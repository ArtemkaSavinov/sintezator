`timescale 1ns / 1ps

module midi_uart_rx_tb;
    localparam integer CLKS_PER_BIT = 8;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg midi_rx = 1'b1;
    wire [7:0] data_byte;
    wire data_valid;
    wire framing_error;
    integer errors = 0;
    integer received_count = 0;
    reg [7:0] expected_byte;

    always #5 clk = ~clk;

    midi_uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT),
        .COUNTER_WIDTH(4)
    ) dut (
        .clk(clk),
        .rst(rst),
        .midi_rx(midi_rx),
        .data_byte(data_byte),
        .data_valid(data_valid),
        .framing_error(framing_error)
    );

    always @(negedge clk) begin
        if (data_valid) begin
            received_count = received_count + 1;
            if (data_byte !== expected_byte) begin
                $display("ERROR received=%h expected=%h", data_byte, expected_byte);
                errors = errors + 1;
            end
        end
        if (framing_error) begin
            $display("ERROR unexpected framing error");
            errors = errors + 1;
        end
    end

    task send_uart_byte;
        input [7:0] value;
        integer bit_number;
        begin
            expected_byte = value;
            midi_rx = 1'b0;
            repeat (CLKS_PER_BIT) @(posedge clk);
            for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
                midi_rx = value[bit_number];
                repeat (CLKS_PER_BIT) @(posedge clk);
            end
            midi_rx = 1'b1;
            repeat (CLKS_PER_BIT) @(posedge clk);
            repeat (3) @(posedge clk);
        end
    endtask

    initial begin
        repeat (3) @(posedge clk);
        rst = 1'b0;
        repeat (3) @(posedge clk);

        send_uart_byte(8'h90);
        send_uart_byte(8'h30);
        send_uart_byte(8'h5C);

        if (received_count != 3) begin
            $display("ERROR received_count=%0d expected=3", received_count);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("PASS: midi_uart_rx_tb");
        else
            $display("FAIL: midi_uart_rx_tb errors=%0d", errors);
        $finish;
    end
endmodule
