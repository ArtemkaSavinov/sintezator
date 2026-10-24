`timescale 1ns / 1ps

module pdm_dac_tb;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg signed [15:0] sample_in = 16'sd0;
    wire pdm_out;
    integer errors = 0;

    always #5 clk = ~clk;

    pdm_dac dut (
        .clk(clk),
        .rst(rst),
        .sample_in(sample_in),
        .pdm_out(pdm_out)
    );

    task check_density;
        input integer sample_value;
        input integer expected_ones;
        integer i;
        integer ones;
        integer difference;
        begin
            rst = 1'b1;
            sample_in = sample_value;
            repeat (2) @(posedge clk);
            rst = 1'b0;
            ones = 0;
            for (i = 0; i < 4096; i = i + 1) begin
                @(posedge clk);
                #1;
                if (pdm_out)
                    ones = ones + 1;
            end
            difference = ones - expected_ones;
            if (difference < 0)
                difference = -difference;
            if (difference > 2) begin
                $display("ERROR sample=%0d ones=%0d expected=%0d", sample_value, ones, expected_ones);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        check_density(0,      2048);
        check_density(16384,  3072);
        check_density(-16384, 1024);

        if (errors == 0)
            $display("PASS: pdm_dac_tb");
        else
            $display("FAIL: pdm_dac_tb errors=%0d", errors);
        $finish;
    end
endmodule
