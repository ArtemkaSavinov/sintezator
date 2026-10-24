`timescale 1ns / 1ps

module note_frequency_lut_tb;
    reg [2:0] note_index;
    wire [31:0] phase_increment;
    integer errors = 0;

    note_frequency_lut dut (
        .note_index(note_index),
        .phase_increment(phase_increment)
    );

    task check_increment;
        input [2:0] index;
        input [31:0] expected;
        begin
            note_index = index;
            #1;
            if (phase_increment !== expected) begin
                $display("ERROR index=%0d increment=%h expected=%h", index, phase_increment, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        check_increment(3'd0, 32'h0000_2BE5);
        check_increment(3'd1, 32'h0000_3145);
        check_increment(3'd2, 32'h0000_374D);
        check_increment(3'd3, 32'h0000_3A97);
        check_increment(3'd4, 32'h0000_41C4);
        check_increment(3'd5, 32'h0000_49D2);
        check_increment(3'd6, 32'h0000_52DC);

        if (errors == 0)
            $display("PASS: note_frequency_lut_tb");
        else
            $display("FAIL: note_frequency_lut_tb errors=%0d", errors);
        $finish;
    end
endmodule
