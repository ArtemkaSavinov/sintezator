`timescale 1ns / 1ps

module phase_accumulator (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] phase_increment,
    output reg  [31:0] phase
);
    always @(posedge clk) begin
        if (rst)
            phase <= 32'd0;
        else
            phase <= phase + phase_increment;
    end
endmodule
