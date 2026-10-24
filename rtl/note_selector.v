`timescale 1ns / 1ps

// Selects one of the seven natural notes C4..B4 and wraps at both ends.
module note_selector (
    input  wire       clk,
    input  wire       rst,
    input  wire       note_up,
    input  wire       note_down,
    output reg  [2:0] note_index
);
    localparam [2:0] NOTE_C = 3'd0;
    localparam [2:0] NOTE_B = 3'd6;

    always @(posedge clk) begin
        if (rst) begin
            note_index <= NOTE_C;
        end else if (note_up && !note_down) begin
            if (note_index == NOTE_B)
                note_index <= NOTE_C;
            else
                note_index <= note_index + 1'b1;
        end else if (note_down && !note_up) begin
            if (note_index == NOTE_C)
                note_index <= NOTE_B;
            else
                note_index <= note_index - 1'b1;
        end
    end
endmodule
