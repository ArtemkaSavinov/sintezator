`timescale 1ns / 1ps

// Three-note diatonic triads in C major. Each output is a phase increment for
// a 32-bit accumulator clocked at 100 MHz.
module chord_frequency_lut (
    input  wire [2:0]  note_index,
    output reg  [31:0] phase_increment_root,
    output reg  [31:0] phase_increment_third,
    output reg  [31:0] phase_increment_fifth
);
    always @* begin
        case (note_index)
            3'd0: begin // C major: C4 E4 G4
                phase_increment_root  = 32'h0000_2BE5;
                phase_increment_third = 32'h0000_374D;
                phase_increment_fifth = 32'h0000_41C4;
            end
            3'd1: begin // D minor: D4 F4 A4
                phase_increment_root  = 32'h0000_3145;
                phase_increment_third = 32'h0000_3A97;
                phase_increment_fifth = 32'h0000_49D2;
            end
            3'd2: begin // E minor: E4 G4 B4
                phase_increment_root  = 32'h0000_374D;
                phase_increment_third = 32'h0000_41C4;
                phase_increment_fifth = 32'h0000_52DC;
            end
            3'd3: begin // F major: F4 A4 C5
                phase_increment_root  = 32'h0000_3A97;
                phase_increment_third = 32'h0000_49D2;
                phase_increment_fifth = 32'h0000_57C9;
            end
            3'd4: begin // G major: G4 B4 D5
                phase_increment_root  = 32'h0000_41C4;
                phase_increment_third = 32'h0000_52DC;
                phase_increment_fifth = 32'h0000_628A;
            end
            3'd5: begin // A minor: A4 C5 E5
                phase_increment_root  = 32'h0000_49D2;
                phase_increment_third = 32'h0000_57C9;
                phase_increment_fifth = 32'h0000_6E9B;
            end
            3'd6: begin // B diminished: B4 D5 F5
                phase_increment_root  = 32'h0000_52DC;
                phase_increment_third = 32'h0000_628A;
                phase_increment_fifth = 32'h0000_752E;
            end
            default: begin
                phase_increment_root  = 32'h0000_2BE5;
                phase_increment_third = 32'h0000_374D;
                phase_increment_fifth = 32'h0000_41C4;
            end
        endcase
    end
endmodule
