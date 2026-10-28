`timescale 1ns / 1ps

// Parses MIDI channel messages and emits normalized note events. All MIDI
// channels are accepted. Running status is supported and real-time messages
// (clock, active sensing, etc.) do not disturb the current message.
module midi_note_parser (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] data_byte,
    input  wire       data_valid,
    output reg        note_event_valid,
    output reg        note_event_on,
    output reg  [6:0] note_number,
    output reg  [6:0] velocity
);
    reg [7:0] running_status;
    reg       waiting_for_second_data;
    reg [6:0] first_data_byte;

    always @(posedge clk) begin
        if (rst) begin
            running_status         <= 8'd0;
            waiting_for_second_data <= 1'b0;
            first_data_byte        <= 7'd0;
            note_event_valid       <= 1'b0;
            note_event_on          <= 1'b0;
            note_number            <= 7'd0;
            velocity               <= 7'd0;
        end else begin
            note_event_valid <= 1'b0;

            if (data_valid) begin
                // MIDI real-time bytes may occur between any two bytes and do
                // not cancel running status.
                if (data_byte >= 8'hF8) begin
                    waiting_for_second_data <= waiting_for_second_data;
                end else if (data_byte[7]) begin
                    waiting_for_second_data <= 1'b0;
                    if ((data_byte[7:4] >= 4'h8) &&
                        (data_byte[7:4] <= 4'hE))
                        running_status <= data_byte;
                    else
                        running_status <= 8'd0;
                end else if (running_status != 0) begin
                    // Program Change and Channel Pressure contain only one
                    // data byte. They are ignored but parsed correctly.
                    if ((running_status[7:4] == 4'hC) ||
                        (running_status[7:4] == 4'hD)) begin
                        waiting_for_second_data <= 1'b0;
                    end else if (!waiting_for_second_data) begin
                        first_data_byte <= data_byte[6:0];
                        waiting_for_second_data <= 1'b1;
                    end else begin
                        waiting_for_second_data <= 1'b0;
                        if ((running_status[7:4] == 4'h8) ||
                            (running_status[7:4] == 4'h9)) begin
                            note_number      <= first_data_byte;
                            velocity         <= data_byte[6:0];
                            note_event_on    <= (running_status[7:4] == 4'h9) &&
                                                (data_byte[6:0] != 0);
                            note_event_valid <= 1'b1;
                        end
                    end
                end
            end
        end
    end
endmodule
