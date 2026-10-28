`timescale 1ns / 1ps

// Converts a MIDI note number (0..127) to the phase increment of a 32-bit DDS
// clocked at 100 MHz. The 12-entry table stores octave 4 (MIDI 60..71); other
// octaves are obtained by exact powers-of-two shifts.
module midi_note_to_phase_inc (
    input  wire [6:0]  midi_note,
    output reg  [31:0] phase_increment
);
    reg [3:0] octave_number;
    reg [3:0] pitch_class;
    reg [31:0] base_increment;

    always @* begin
        octave_number = midi_note / 12;
        pitch_class   = midi_note % 12;

        case (pitch_class)
            4'd0:  base_increment = 32'h0000_2BE5; // C4
            4'd1:  base_increment = 32'h0000_2E81; // C#4
            4'd2:  base_increment = 32'h0000_3145; // D4
            4'd3:  base_increment = 32'h0000_3433; // D#4
            4'd4:  base_increment = 32'h0000_374D; // E4
            4'd5:  base_increment = 32'h0000_3A97; // F4
            4'd6:  base_increment = 32'h0000_3E13; // F#4
            4'd7:  base_increment = 32'h0000_41C4; // G4
            4'd8:  base_increment = 32'h0000_45AD; // G#4
            4'd9:  base_increment = 32'h0000_49D2; // A4
            4'd10: base_increment = 32'h0000_4E36; // A#4
            default: base_increment = 32'h0000_52DC; // B4
        endcase

        if (octave_number < 5)
            phase_increment = base_increment >> (5 - octave_number);
        else
            phase_increment = base_increment << (octave_number - 5);
    end
endmodule
