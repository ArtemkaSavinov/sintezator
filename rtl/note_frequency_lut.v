`timescale 1ns / 1ps

// Phase increments for a 32-bit accumulator clocked at 100 MHz.
// f_out = phase_increment * 100_000_000 / 2^32.
module note_frequency_lut (
    input  wire [2:0]  note_index,
    output reg  [31:0] phase_increment
);
    always @* begin
        case (note_index)
            3'd0: phase_increment = 32'h0000_2BE5; // C4  261.632 Hz
            3'd1: phase_increment = 32'h0000_3145; // D4  293.669 Hz
            3'd2: phase_increment = 32'h0000_374D; // E4  329.618 Hz
            3'd3: phase_increment = 32'h0000_3A97; // F4  349.223 Hz
            3'd4: phase_increment = 32'h0000_41C4; // G4  391.994 Hz
            3'd5: phase_increment = 32'h0000_49D2; // A4  440.003 Hz
            3'd6: phase_increment = 32'h0000_52DC; // B4  493.880 Hz
            default: phase_increment = 32'h0000_2BE5;
        endcase
    end
endmodule
