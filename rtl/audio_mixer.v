`timescale 1ns / 1ps

// In single-note mode only the root voice is passed through. In chord mode
// three half-scale CORDIC outputs are summed at 18-bit precision and divided
// by two. The worst-case result is +/-24576, safely inside signed 16-bit range.
module audio_mixer (
    input  wire               chord_mode,
    input  wire signed [15:0] root_sample,
    input  wire signed [15:0] third_sample,
    input  wire signed [15:0] fifth_sample,
    output reg  signed [15:0] mixed_sample
);
    wire signed [17:0] root_extended;
    wire signed [17:0] third_extended;
    wire signed [17:0] fifth_extended;
    wire signed [17:0] voice_sum;
    wire signed [17:0] scaled_sum;

    assign root_extended  = {{2{root_sample[15]}}, root_sample};
    assign third_extended = {{2{third_sample[15]}}, third_sample};
    assign fifth_extended = {{2{fifth_sample[15]}}, fifth_sample};
    assign voice_sum = root_extended + third_extended + fifth_extended;
    assign scaled_sum = voice_sum >>> 1;

    always @* begin
        if (chord_mode)
            mixed_sample = scaled_sum[15:0];
        else
            mixed_sample = root_sample;
    end
endmodule
