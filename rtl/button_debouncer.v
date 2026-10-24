`timescale 1ns / 1ps

// Synchronizes an active-high mechanical button, removes contact bounce and
// produces one clock-wide pulse when the debounced button is pressed.
module button_debouncer #(
    parameter integer STABLE_CYCLES = 1_000_000,
    parameter integer COUNTER_WIDTH = 20
) (
    input  wire clk,
    input  wire rst,
    input  wire button_in,
    output reg  pressed_pulse,
    output reg  button_state
);
    reg sync_ff1;
    reg sync_ff2;
    reg [COUNTER_WIDTH-1:0] stable_counter;

    always @(posedge clk) begin
        if (rst) begin
            sync_ff1      <= 1'b0;
            sync_ff2      <= 1'b0;
            stable_counter <= {COUNTER_WIDTH{1'b0}};
            pressed_pulse <= 1'b0;
            button_state  <= 1'b0;
        end else begin
            sync_ff1 <= button_in;
            sync_ff2 <= sync_ff1;
            pressed_pulse <= 1'b0;

            if (sync_ff2 == button_state) begin
                stable_counter <= {COUNTER_WIDTH{1'b0}};
            end else if (stable_counter == STABLE_CYCLES - 1) begin
                stable_counter <= {COUNTER_WIDTH{1'b0}};
                button_state   <= sync_ff2;
                if (sync_ff2)
                    pressed_pulse <= 1'b1;
            end else begin
                stable_counter <= stable_counter + 1'b1;
            end
        end
    end
endmodule
