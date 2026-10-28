`timescale 1ns / 1ps

// MIDI physical-layer receiver: 31250 baud, 8 data bits, no parity, one stop
// bit. At 100 MHz the nominal bit period is exactly 3200 clock cycles.
module midi_uart_rx #(
    parameter integer CLKS_PER_BIT = 3200,
    parameter integer COUNTER_WIDTH = 12
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       midi_rx,
    output reg  [7:0] data_byte,
    output reg        data_valid,
    output reg        framing_error
);
    localparam [1:0] STATE_IDLE  = 2'd0;
    localparam [1:0] STATE_START = 2'd1;
    localparam [1:0] STATE_DATA  = 2'd2;
    localparam [1:0] STATE_STOP  = 2'd3;

    reg rx_meta;
    reg rx_sync;
    reg [1:0] state;
    reg [COUNTER_WIDTH-1:0] clock_counter;
    reg [2:0] bit_index;
    reg [7:0] shift_register;

    always @(posedge clk) begin
        if (rst) begin
            rx_meta        <= 1'b1;
            rx_sync        <= 1'b1;
            state          <= STATE_IDLE;
            clock_counter  <= {COUNTER_WIDTH{1'b0}};
            bit_index      <= 3'd0;
            shift_register <= 8'd0;
            data_byte      <= 8'd0;
            data_valid     <= 1'b0;
            framing_error  <= 1'b0;
        end else begin
            rx_meta <= midi_rx;
            rx_sync <= rx_meta;
            data_valid <= 1'b0;
            framing_error <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    clock_counter <= {COUNTER_WIDTH{1'b0}};
                    bit_index <= 3'd0;
                    if (!rx_sync) begin
                        clock_counter <= (CLKS_PER_BIT / 2) - 1;
                        state <= STATE_START;
                    end
                end

                STATE_START: begin
                    if (clock_counter == 0) begin
                        if (!rx_sync) begin
                            clock_counter <= CLKS_PER_BIT - 1;
                            bit_index <= 3'd0;
                            state <= STATE_DATA;
                        end else begin
                            state <= STATE_IDLE;
                        end
                    end else begin
                        clock_counter <= clock_counter - 1'b1;
                    end
                end

                STATE_DATA: begin
                    if (clock_counter == 0) begin
                        shift_register[bit_index] <= rx_sync;
                        clock_counter <= CLKS_PER_BIT - 1;
                        if (bit_index == 3'd7) begin
                            state <= STATE_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clock_counter <= clock_counter - 1'b1;
                    end
                end

                STATE_STOP: begin
                    if (clock_counter == 0) begin
                        if (rx_sync) begin
                            data_byte  <= shift_register;
                            data_valid <= 1'b1;
                        end else begin
                            framing_error <= 1'b1;
                        end
                        state <= STATE_IDLE;
                    end else begin
                        clock_counter <= clock_counter - 1'b1;
                    end
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end
endmodule
