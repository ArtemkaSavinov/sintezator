`timescale 1ns / 1ps

module midi_voice_allocator_tb;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg note_event_valid = 1'b0;
    reg note_event_on = 1'b0;
    reg [6:0] note_number = 7'd0;
    wire [2:0] voice_active;
    wire [6:0] voice_note_0;
    wire [6:0] voice_note_1;
    wire [6:0] voice_note_2;
    integer errors = 0;

    always #5 clk = ~clk;

    midi_voice_allocator dut (
        .clk(clk),
        .rst(rst),
        .note_event_valid(note_event_valid),
        .note_event_on(note_event_on),
        .note_number(note_number),
        .voice_active(voice_active),
        .voice_note_0(voice_note_0),
        .voice_note_1(voice_note_1),
        .voice_note_2(voice_note_2)
    );

    task send_event;
        input event_on;
        input [6:0] event_note;
        begin
            @(negedge clk);
            note_event_on = event_on;
            note_number = event_note;
            note_event_valid = 1'b1;
            @(negedge clk);
            note_event_valid = 1'b0;
            #1;
        end
    endtask

    initial begin
        repeat (3) @(posedge clk);
        rst = 1'b0;

        send_event(1'b1, 7'd48);
        send_event(1'b1, 7'd52);
        send_event(1'b1, 7'd55);
        if ((voice_active !== 3'b111) ||
            (voice_note_0 !== 7'd48) ||
            (voice_note_1 !== 7'd52) ||
            (voice_note_2 !== 7'd55)) begin
            $display("ERROR three-note allocation");
            errors = errors + 1;
        end

        send_event(1'b0, 7'd52);
        if (voice_active !== 3'b101) begin
            $display("ERROR Note Off active=%b expected=101", voice_active);
            errors = errors + 1;
        end

        send_event(1'b1, 7'd60);
        if ((voice_active !== 3'b111) || (voice_note_1 !== 7'd60)) begin
            $display("ERROR free-slot reuse");
            errors = errors + 1;
        end

        // All slots are busy; the next note steals one slot round-robin.
        send_event(1'b1, 7'd64);
        if ((voice_active !== 3'b111) || (voice_note_2 !== 7'd64)) begin
            $display("ERROR round-robin voice stealing");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("PASS: midi_voice_allocator_tb");
        else
            $display("FAIL: midi_voice_allocator_tb errors=%0d", errors);
        $finish;
    end
endmodule
