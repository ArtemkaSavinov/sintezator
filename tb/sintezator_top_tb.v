`timescale 1ns / 1ps

module sintezator_top_tb;
    reg CLK100MHZ = 1'b0;
    reg CPU_RESETN = 1'b0;
    reg BTNU = 1'b0;
    reg BTND = 1'b0;
    reg [0:0] SW = 1'b0;
    wire AUD_PWM;
    wire AUD_SD;
    wire [7:0] LED;
    integer errors = 0;
    integer zero_count;
    integer high_z_count;
    integer i;

    always #5 CLK100MHZ = ~CLK100MHZ;

    sintezator_top #(
        .DEBOUNCE_CYCLES(4),
        .DEBOUNCE_COUNTER_WIDTH(3)
    ) dut (
        .CLK100MHZ(CLK100MHZ),
        .CPU_RESETN(CPU_RESETN),
        .BTNU(BTNU),
        .BTND(BTND),
        .SW(SW),
        .AUD_PWM(AUD_PWM),
        .AUD_SD(AUD_SD),
        .LED(LED)
    );

    task press_up;
        begin
            BTNU = 1'b1;
            repeat (9) @(posedge CLK100MHZ);
            BTNU = 1'b0;
            repeat (9) @(posedge CLK100MHZ);
        end
    endtask

    task press_down;
        begin
            BTND = 1'b1;
            repeat (9) @(posedge CLK100MHZ);
            BTND = 1'b0;
            repeat (9) @(posedge CLK100MHZ);
        end
    endtask

    task check_led;
        input [7:0] expected;
        begin
            #1;
            if (LED !== expected) begin
                $display("ERROR LED=%b expected=%b", LED, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        repeat (4) @(posedge CLK100MHZ);
        CPU_RESETN = 1'b1;
        repeat (2) @(posedge CLK100MHZ);
        check_led(8'b00000001); // C, single-note mode

        press_up;
        check_led(8'b00000010); // D
        press_up;
        check_led(8'b00000100); // E
        press_down;
        check_led(8'b00000010); // D

        // Reset to C, then verify downward wrap C -> B.
        CPU_RESETN = 1'b0;
        repeat (2) @(posedge CLK100MHZ);
        CPU_RESETN = 1'b1;
        repeat (2) @(posedge CLK100MHZ);
        press_down;
        check_led(8'b01000000); // B

        // SW0 enables all three voices; LED7 indicates chord mode.
        SW[0] = 1'b1;
        repeat (3) @(posedge CLK100MHZ);
        check_led(8'b11000000); // B diminished chord

        SW[0] = 1'b0;
        repeat (3) @(posedge CLK100MHZ);
        check_led(8'b01000000); // Back to single B

        if (AUD_SD !== 1'b1) begin
            $display("ERROR AUD_SD is not enabled");
            errors = errors + 1;
        end

        zero_count = 0;
        high_z_count = 0;
        for (i = 0; i < 200; i = i + 1) begin
            @(posedge CLK100MHZ);
            #1;
            if (AUD_PWM === 1'b0)
                zero_count = zero_count + 1;
            if (AUD_PWM === 1'bz)
                high_z_count = high_z_count + 1;
        end
        if ((zero_count == 0) || (high_z_count == 0)) begin
            $display("ERROR open-drain PDM did not produce both 0 and Z");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("PASS: sintezator_top_tb");
        else
            $display("FAIL: sintezator_top_tb errors=%0d", errors);
        $finish;
    end
endmodule
