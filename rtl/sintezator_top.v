`timescale 1ns / 1ps

module sintezator_top #(
    parameter integer DEBOUNCE_CYCLES = 1_000_000,
    parameter integer DEBOUNCE_COUNTER_WIDTH = 20
) (
    input  wire       CLK100MHZ,
    input  wire       CPU_RESETN,
    input  wire       BTNU,
    input  wire       BTND,
    input  wire [0:0] SW,
    inout  wire       AUD_PWM,
    output wire       AUD_SD,
    output wire [7:0] LED
);
    wire rst;
    wire up_pulse;
    wire down_pulse;
    wire up_state_unused;
    wire down_state_unused;
    wire [2:0] note_index;
    wire [31:0] phase_increment_root;
    wire [31:0] phase_increment_third;
    wire [31:0] phase_increment_fifth;
    wire [31:0] phase_root;
    wire [31:0] phase_third;
    wire [31:0] phase_fifth;
    wire signed [15:0] root_sample;
    wire signed [15:0] third_sample;
    wire signed [15:0] fifth_sample;
    wire signed [15:0] mixed_sample;
    wire pdm_bit;
    reg chord_mode_meta;
    reg chord_mode;

    assign rst = ~CPU_RESETN;

    // Synchronize the asynchronous slide switch into the audio clock domain.
    always @(posedge CLK100MHZ) begin
        if (rst) begin
            chord_mode_meta <= 1'b0;
            chord_mode      <= 1'b0;
        end else begin
            chord_mode_meta <= SW[0];
            chord_mode      <= chord_mode_meta;
        end
    end

    button_debouncer #(
        .STABLE_CYCLES(DEBOUNCE_CYCLES),
        .COUNTER_WIDTH(DEBOUNCE_COUNTER_WIDTH)
    ) debounce_up (
        .clk(CLK100MHZ),
        .rst(rst),
        .button_in(BTNU),
        .pressed_pulse(up_pulse),
        .button_state(up_state_unused)
    );

    button_debouncer #(
        .STABLE_CYCLES(DEBOUNCE_CYCLES),
        .COUNTER_WIDTH(DEBOUNCE_COUNTER_WIDTH)
    ) debounce_down (
        .clk(CLK100MHZ),
        .rst(rst),
        .button_in(BTND),
        .pressed_pulse(down_pulse),
        .button_state(down_state_unused)
    );

    note_selector selector (
        .clk(CLK100MHZ),
        .rst(rst),
        .note_up(up_pulse),
        .note_down(down_pulse),
        .note_index(note_index)
    );

    chord_frequency_lut frequencies (
        .note_index(note_index),
        .phase_increment_root(phase_increment_root),
        .phase_increment_third(phase_increment_third),
        .phase_increment_fifth(phase_increment_fifth)
    );

    phase_accumulator nco_root (
        .clk(CLK100MHZ),
        .rst(rst),
        .phase_increment(phase_increment_root),
        .phase(phase_root)
    );

    phase_accumulator nco_third (
        .clk(CLK100MHZ),
        .rst(rst),
        .phase_increment(phase_increment_third),
        .phase(phase_third)
    );

    phase_accumulator nco_fifth (
        .clk(CLK100MHZ),
        .rst(rst),
        .phase_increment(phase_increment_fifth),
        .phase(phase_fifth)
    );

    cordic_sine oscillator_root (
        .clk(CLK100MHZ),
        .rst(rst),
        .phase_in(phase_root),
        .sine_out(root_sample)
    );

    cordic_sine oscillator_third (
        .clk(CLK100MHZ),
        .rst(rst),
        .phase_in(phase_third),
        .sine_out(third_sample)
    );

    cordic_sine oscillator_fifth (
        .clk(CLK100MHZ),
        .rst(rst),
        .phase_in(phase_fifth),
        .sine_out(fifth_sample)
    );

    audio_mixer mixer (
        .chord_mode(chord_mode),
        .root_sample(root_sample),
        .third_sample(third_sample),
        .fifth_sample(fifth_sample),
        .mixed_sample(mixed_sample)
    );

    pdm_dac audio_dac (
        .clk(CLK100MHZ),
        .rst(rst),
        .sample_in(mixed_sample),
        .pdm_out(pdm_bit)
    );

    // Nexys A7 AUD_PWM must be open-drain: drive zero, release for one.
    assign AUD_PWM = pdm_bit ? 1'bz : 1'b0;
    assign AUD_SD  = 1'b1;
    assign LED[6:0] = 7'b0000001 << note_index;
    assign LED[7]   = chord_mode;
endmodule
