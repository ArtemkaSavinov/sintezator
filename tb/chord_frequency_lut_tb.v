`timescale 1ns / 1ps

module chord_frequency_lut_tb;
    reg [2:0] note_index;
    wire [31:0] phase_increment_third;
    wire [31:0] phase_increment_fifth;
    integer errors = 0;

    chord_frequency_lut dut (
        .note_index(note_index),
        .phase_increment_third(phase_increment_third),
        .phase_increment_fifth(phase_increment_fifth)
    );

    task check_chord;
        input [2:0] index;
        input [31:0] expected_third;
        input [31:0] expected_fifth;
        begin
            note_index = index;
            #1;
            if ((phase_increment_third !== expected_third) ||
                (phase_increment_fifth !== expected_fifth)) begin
                $display("ERROR chord=%0d got=%h,%h expected=%h,%h",
                         index,
                         phase_increment_third,
                         phase_increment_fifth,
                         expected_third,
                         expected_fifth);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        check_chord(3'd0, 32'h0000_374D, 32'h0000_41C4);
        check_chord(3'd1, 32'h0000_3A97, 32'h0000_49D2);
        check_chord(3'd2, 32'h0000_41C4, 32'h0000_52DC);
        check_chord(3'd3, 32'h0000_49D2, 32'h0000_57C9);
        check_chord(3'd4, 32'h0000_52DC, 32'h0000_628A);
        check_chord(3'd5, 32'h0000_57C9, 32'h0000_6E9B);
        check_chord(3'd6, 32'h0000_628A, 32'h0000_752E);

        if (errors == 0)
            $display("PASS: chord_frequency_lut_tb");
        else
            $display("FAIL: chord_frequency_lut_tb errors=%0d", errors);
        $finish;
    end
endmodule
