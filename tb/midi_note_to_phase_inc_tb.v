`timescale 1ns / 1ps

module midi_note_to_phase_inc_tb;
    reg [6:0] midi_note;
    wire [31:0] phase_increment;
    integer errors = 0;

    midi_note_to_phase_inc dut (
        .midi_note(midi_note),
        .phase_increment(phase_increment)
    );

    task check_note;
        input [6:0] note;
        input [31:0] expected;
        begin
            midi_note = note;
            #1;
            if (phase_increment !== expected) begin
                $display("ERROR note=%0d increment=%h expected=%h",
                         note, phase_increment, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        check_note(7'd48, 32'h0000_15F2); // C3
        check_note(7'd60, 32'h0000_2BE5); // C4
        check_note(7'd69, 32'h0000_49D2); // A4
        check_note(7'd72, 32'h0000_57CA); // C5
        check_note(7'd127, 32'h0008_3880); // G9

        if (errors == 0)
            $display("PASS: midi_note_to_phase_inc_tb");
        else
            $display("FAIL: midi_note_to_phase_inc_tb errors=%0d", errors);
        $finish;
    end
endmodule
