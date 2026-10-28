`timescale 1ns / 1ps

module sintezator_top_tb;
    localparam integer MIDI_CLKS_PER_BIT = 8;
    reg CLK100MHZ = 1'b0;
    reg CPU_RESETN = 1'b0;
    reg BTNU = 1'b0;
    reg BTND = 1'b0;
    reg [1:0] SW = 2'b00;
    reg MIDI_dat = 1'b1;
    wire AUD_PWM;
    wire AUD_SD;
    wire [11:0] LED;
    integer errors = 0;
    integer zero_count;
    integer high_z_count;
    integer i;

    always #5 CLK100MHZ = ~CLK100MHZ;

    sintezator_top #(
        .DEBOUNCE_CYCLES(4),
        .DEBOUNCE_COUNTER_WIDTH(3),
        .MIDI_CLKS_PER_BIT(MIDI_CLKS_PER_BIT),
        .MIDI_COUNTER_WIDTH(4)
    ) dut (
        .CLK100MHZ(CLK100MHZ),
        .CPU_RESETN(CPU_RESETN),
        .BTNU(BTNU),
        .BTND(BTND),
        .SW(SW),
        .MIDI_dat(MIDI_dat),
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
        input [11:0] expected;
        begin
            #1;
            if (LED !== expected) begin
                $display("ERROR LED=%b expected=%b", LED, expected);
                errors = errors + 1;
            end
        end
    endtask

    task send_midi_byte;
        input [7:0] value;
        integer bit_number;
        begin
            MIDI_dat = 1'b0;
            repeat (MIDI_CLKS_PER_BIT) @(posedge CLK100MHZ);
            for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
                MIDI_dat = value[bit_number];
                repeat (MIDI_CLKS_PER_BIT) @(posedge CLK100MHZ);
            end
            MIDI_dat = 1'b1;
            repeat (MIDI_CLKS_PER_BIT) @(posedge CLK100MHZ);
            repeat (3) @(posedge CLK100MHZ);
        end
    endtask

    initial begin
        repeat (4) @(posedge CLK100MHZ);
        CPU_RESETN = 1'b1;
        repeat (2) @(posedge CLK100MHZ);
        check_led(12'b0000_0000_0001); // C, single-note mode

        press_up;
        check_led(12'b0000_0000_0010); // D
        press_up;
        check_led(12'b0000_0000_0100); // E
        press_down;
        check_led(12'b0000_0000_0010); // D

        // Reset to C, then verify downward wrap C -> B.
        CPU_RESETN = 1'b0;
        repeat (2) @(posedge CLK100MHZ);
        CPU_RESETN = 1'b1;
        repeat (2) @(posedge CLK100MHZ);
        press_down;
        check_led(12'b0000_0100_0000); // B

        // SW0 enables all three voices; LED7 indicates chord mode.
        SW[0] = 1'b1;
        repeat (3) @(posedge CLK100MHZ);
        check_led(12'b0000_1100_0000); // B diminished chord

        SW[0] = 1'b0;
        repeat (3) @(posedge CLK100MHZ);
        check_led(12'b0000_0100_0000); // Back to single B

        // SW1 enables MIDI mode. LED8 marks the mode and LED9..11 show
        // allocated voices.
        SW[1] = 1'b1;
        repeat (3) @(posedge CLK100MHZ);
        check_led(12'b0001_0000_0000);

        // Note On C3, velocity 92 (the message shown by the keyboard monitor).
        send_midi_byte(8'h90);
        send_midi_byte(8'h30);
        send_midi_byte(8'h5C);
        check_led(12'b0011_0000_0000);

        // Running status Note On C5, velocity 79.
        send_midi_byte(8'h48);
        send_midi_byte(8'h4F);
        check_led(12'b0111_0000_0000);

        // Note On with velocity zero is Note Off.
        send_midi_byte(8'h30);
        send_midi_byte(8'h00);
        check_led(12'b0101_0000_0000);
        send_midi_byte(8'h48);
        send_midi_byte(8'h00);
        check_led(12'b0001_0000_0000);

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
