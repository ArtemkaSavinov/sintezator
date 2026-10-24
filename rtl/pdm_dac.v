`timescale 1ns / 1ps

// First-order pulse-density modulator. Signed PCM is converted to offset
// binary, then accumulated; the carry bit is the 1-bit DAC stream.
module pdm_dac (
    input  wire               clk,
    input  wire               rst,
    input  wire signed [15:0] sample_in,
    output wire               pdm_out
);
    wire [15:0] offset_sample;
    reg  [16:0] accumulator;

    assign offset_sample = sample_in ^ 16'h8000;
    assign pdm_out = accumulator[16];

    always @(posedge clk) begin
        if (rst)
            accumulator <= 17'd0;
        else
            accumulator <= {1'b0, accumulator[15:0]} +
                           {1'b0, offset_sample};
    end
endmodule
