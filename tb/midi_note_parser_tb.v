`timescale 1ns / 1ps

module midi_note_parser_tb;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg [7:0] data_byte = 8'd0;
    reg data_valid = 1'b0;
    wire note_event_valid;
    wire note_event_on;
    wire [6:0] note_number;
    wire [6:0] velocity;
    integer errors = 0;

    always #5 clk = ~clk;

    midi_note_parser dut (
        .clk(clk),
        .rst(rst),
        .data_byte(data_byte),
        .data_valid(data_valid),
        .note_event_valid(note_event_valid),
        .note_event_on(note_event_on),
        .note_number(note_number),
        .velocity(velocity)
    );

    task send_byte;
        input [7:0] value;
        begin
            @(negedge clk);
            data_byte = value;
            data_valid = 1'b1;
            @(negedge clk);
            data_valid = 1'b0;
        end
    endtask

    task expect_event;
        input expected_on;
        input [6:0] expected_note;
        input [6:0] expected_velocity;
        begin
            if (!note_event_valid ||
                (note_event_on !== expected_on) ||
                (note_number !== expected_note) ||
                (velocity !== expected_velocity)) begin
                $display("ERROR event valid=%b on=%b note=%0d velocity=%0d",
                         note_event_valid, note_event_on, note_number, velocity);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        repeat (3) @(posedge clk);
        rst = 1'b0;

        send_byte(8'h90);
        send_byte(8'h30);
        send_byte(8'h5C);
        expect_event(1'b1, 7'd48, 7'd92);

        // Running status: a second Note On without another status byte.
        send_byte(8'h48);
        send_byte(8'h4F);
        expect_event(1'b1, 7'd72, 7'd79);

        // Real-time clock must not disturb running status.
        send_byte(8'hF8);
        send_byte(8'h48);
        send_byte(8'h00);
        expect_event(1'b0, 7'd72, 7'd0);

        send_byte(8'h80);
        send_byte(8'h30);
        send_byte(8'h40);
        expect_event(1'b0, 7'd48, 7'd64);

        if (errors == 0)
            $display("PASS: midi_note_parser_tb");
        else
            $display("FAIL: midi_note_parser_tb errors=%0d", errors);
        $finish;
    end
endmodule
