`timescale 1ns / 1ps

// Mixes any enabled subset of three CORDIC voices. A single voice keeps its
// original level; two or three voices are divided by two after an 18-bit sum.
// The worst-case result is +/-24576, safely inside signed 16-bit range.
module audio_mixer (
    input  wire        [2:0]  voice_enable,
    input  wire signed [15:0] root_sample,
    input  wire signed [15:0] third_sample,
    input  wire signed [15:0] fifth_sample,
    output reg  signed [15:0] mixed_sample
);
    wire signed [17:0] root_extended;
    wire signed [17:0] third_extended;
    wire signed [17:0] fifth_extended;
    wire signed [17:0] enabled_root;
    wire signed [17:0] enabled_third;
    wire signed [17:0] enabled_fifth;
    wire signed [17:0] voice_sum;
    wire signed [17:0] scaled_sum;
    reg [1:0] active_count;

    assign root_extended  = {{2{root_sample[15]}}, root_sample};
    assign third_extended = {{2{third_sample[15]}}, third_sample};
    assign fifth_extended = {{2{fifth_sample[15]}}, fifth_sample};
    assign enabled_root  = voice_enable[0] ? root_extended  : 18'sd0;
    assign enabled_third = voice_enable[1] ? third_extended : 18'sd0;
    assign enabled_fifth = voice_enable[2] ? fifth_extended : 18'sd0;
    assign voice_sum = enabled_root + enabled_third + enabled_fifth;
    assign scaled_sum = voice_sum >>> 1;

    always @* begin
        active_count = voice_enable[0] + voice_enable[1] + voice_enable[2];
        case (active_count)
            2'd0: mixed_sample = 16'sd0;
            2'd1: mixed_sample = voice_sum[15:0];
            default: mixed_sample = scaled_sum[15:0];
        endcase
    end
endmodule
