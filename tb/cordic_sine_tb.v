`timescale 1ns / 1ps

module cordic_sine_tb;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg [31:0] phase_in = 32'd0;
    wire signed [15:0] sine_out;
    integer errors = 0;

    always #5 clk = ~clk;

    cordic_sine dut (
        .clk(clk),
        .rst(rst),
        .phase_in(phase_in),
        .sine_out(sine_out)
    );

    task check_sample;
        input [31:0] test_phase;
        input integer expected;
        input integer tolerance;
        integer measured;
        integer difference;
        begin
            phase_in = test_phase;
            repeat (22) @(posedge clk);
            #1;
            measured = $signed(sine_out);
            difference = measured - expected;
            if (difference < 0)
                difference = -difference;
            if (difference > tolerance) begin
                $display("ERROR phase=%h measured=%0d expected=%0d", test_phase, measured, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        repeat (3) @(posedge clk);
        rst = 1'b0;

        check_sample(32'h0000_0000,      0, 20);
        check_sample(32'h2000_0000,  11585, 20);
        check_sample(32'h4000_0000,  16384, 20);
        check_sample(32'h8000_0000,      0, 20);
        check_sample(32'hA000_0000, -11585, 20);
        check_sample(32'hC000_0000, -16384, 20);

        if (errors == 0)
            $display("PASS: cordic_sine_tb");
        else
            $display("FAIL: cordic_sine_tb errors=%0d", errors);
        $finish;
    end
endmodule
