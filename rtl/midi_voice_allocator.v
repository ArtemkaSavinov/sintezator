`timescale 1ns / 1ps

// Allocates incoming MIDI notes to three monophonic oscillator slots. A free
// slot is preferred; when all slots are busy, voices are stolen round-robin.
module midi_voice_allocator (
    input  wire       clk,
    input  wire       rst,
    input  wire       note_event_valid,
    input  wire       note_event_on,
    input  wire [6:0] note_number,
    output reg  [2:0] voice_active,
    output reg  [6:0] voice_note_0,
    output reg  [6:0] voice_note_1,
    output reg  [6:0] voice_note_2
);
    reg [1:0] steal_pointer;

    always @(posedge clk) begin
        if (rst) begin
            voice_active <= 3'b000;
            voice_note_0 <= 7'd60;
            voice_note_1 <= 7'd64;
            voice_note_2 <= 7'd67;
            steal_pointer <= 2'd0;
        end else if (note_event_valid) begin
            if (note_event_on) begin
                // Repeated Note On for an already active pitch does not
                // consume another voice.
                if ((voice_active[0] && (voice_note_0 == note_number)) ||
                    (voice_active[1] && (voice_note_1 == note_number)) ||
                    (voice_active[2] && (voice_note_2 == note_number))) begin
                    voice_active <= voice_active;
                end else if (!voice_active[0]) begin
                    voice_note_0 <= note_number;
                    voice_active[0] <= 1'b1;
                    steal_pointer <= 2'd1;
                end else if (!voice_active[1]) begin
                    voice_note_1 <= note_number;
                    voice_active[1] <= 1'b1;
                    steal_pointer <= 2'd2;
                end else if (!voice_active[2]) begin
                    voice_note_2 <= note_number;
                    voice_active[2] <= 1'b1;
                    steal_pointer <= 2'd0;
                end else begin
                    case (steal_pointer)
                        2'd0: begin
                            voice_note_0 <= note_number;
                            steal_pointer <= 2'd1;
                        end
                        2'd1: begin
                            voice_note_1 <= note_number;
                            steal_pointer <= 2'd2;
                        end
                        default: begin
                            voice_note_2 <= note_number;
                            steal_pointer <= 2'd0;
                        end
                    endcase
                end
            end else begin
                if (voice_active[0] && (voice_note_0 == note_number))
                    voice_active[0] <= 1'b0;
                if (voice_active[1] && (voice_note_1 == note_number))
                    voice_active[1] <= 1'b0;
                if (voice_active[2] && (voice_note_2 == note_number))
                    voice_active[2] <= 1'b0;
            end
        end
    end
endmodule
