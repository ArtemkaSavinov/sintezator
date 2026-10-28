`timescale 1ns / 1ps

module sintezator_top #(
    parameter integer DEBOUNCE_CYCLES = 1_000_000,
    parameter integer DEBOUNCE_COUNTER_WIDTH = 20,
    parameter integer MIDI_CLKS_PER_BIT = 3200,
    parameter integer MIDI_COUNTER_WIDTH = 12,
    parameter MIDI_INVERT = 1'b0
) (
    input  wire        CLK100MHZ,
    input  wire        CPU_RESETN,
    input  wire        BTNU,
    input  wire        BTND,
    input  wire [1:0]  SW,
    input  wire        MIDI_dat,
    inout  wire        AUD_PWM,
    output wire        AUD_SD,
    output wire [11:0] LED
);
    wire rst;
    wire up_pulse;
    wire down_pulse;
    wire up_state_unused;
    wire down_state_unused;
    wire [2:0] note_index;

    reg [1:0] switch_meta;
    reg [1:0] switch_sync;
    wire chord_mode;
    wire midi_mode;

    wire [31:0] manual_phase_increment_root;
    wire [31:0] manual_phase_increment_third;
    wire [31:0] manual_phase_increment_fifth;

    wire midi_rx_level;
    wire [7:0] midi_byte;
    wire midi_byte_valid;
    wire midi_framing_error_unused;
    wire midi_note_event_valid;
    wire midi_note_event_on;
    wire [6:0] midi_note_number;
    wire [6:0] midi_velocity_unused;
    wire [2:0] midi_voice_active;
    wire [6:0] midi_voice_note_0;
    wire [6:0] midi_voice_note_1;
    wire [6:0] midi_voice_note_2;
    wire [31:0] midi_phase_increment_0;
    wire [31:0] midi_phase_increment_1;
    wire [31:0] midi_phase_increment_2;

    wire [31:0] selected_phase_increment_0;
    wire [31:0] selected_phase_increment_1;
    wire [31:0] selected_phase_increment_2;
    wire [2:0] selected_voice_enable;
    wire [31:0] phase_0;
    wire [31:0] phase_1;
    wire [31:0] phase_2;
    wire signed [15:0] sample_0;
    wire signed [15:0] sample_1;
    wire signed [15:0] sample_2;
    wire signed [15:0] mixed_sample;
    wire pdm_bit;

    assign rst = ~CPU_RESETN;
    assign chord_mode = switch_sync[0];
    assign midi_mode = switch_sync[1];
    assign midi_rx_level = MIDI_INVERT ? ~MIDI_dat : MIDI_dat;

    always @(posedge CLK100MHZ) begin
        if (rst) begin
            switch_meta <= 2'b00;
            switch_sync <= 2'b00;
        end else begin
            switch_meta <= SW;
            switch_sync <= switch_meta;
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

    note_frequency_lut root_frequency (
        .note_index(note_index),
        .phase_increment(manual_phase_increment_root)
    );

    chord_frequency_lut chord_frequencies (
        .note_index(note_index),
        .phase_increment_third(manual_phase_increment_third),
        .phase_increment_fifth(manual_phase_increment_fifth)
    );

    midi_uart_rx #(
        .CLKS_PER_BIT(MIDI_CLKS_PER_BIT),
        .COUNTER_WIDTH(MIDI_COUNTER_WIDTH)
    ) midi_receiver (
        .clk(CLK100MHZ),
        .rst(rst),
        .midi_rx(midi_rx_level),
        .data_byte(midi_byte),
        .data_valid(midi_byte_valid),
        .framing_error(midi_framing_error_unused)
    );

    midi_note_parser midi_parser (
        .clk(CLK100MHZ),
        .rst(rst),
        .data_byte(midi_byte),
        .data_valid(midi_byte_valid),
        .note_event_valid(midi_note_event_valid),
        .note_event_on(midi_note_event_on),
        .note_number(midi_note_number),
        .velocity(midi_velocity_unused)
    );

    midi_voice_allocator midi_voices (
        .clk(CLK100MHZ),
        .rst(rst),
        .note_event_valid(midi_note_event_valid),
        .note_event_on(midi_note_event_on),
        .note_number(midi_note_number),
        .voice_active(midi_voice_active),
        .voice_note_0(midi_voice_note_0),
        .voice_note_1(midi_voice_note_1),
        .voice_note_2(midi_voice_note_2)
    );

    midi_note_to_phase_inc midi_frequency_0 (
        .midi_note(midi_voice_note_0),
        .phase_increment(midi_phase_increment_0)
    );

    midi_note_to_phase_inc midi_frequency_1 (
        .midi_note(midi_voice_note_1),
        .phase_increment(midi_phase_increment_1)
    );

    midi_note_to_phase_inc midi_frequency_2 (
        .midi_note(midi_voice_note_2),
        .phase_increment(midi_phase_increment_2)
    );

    assign selected_phase_increment_0 = midi_mode ? midi_phase_increment_0 :
                                                    manual_phase_increment_root;
    assign selected_phase_increment_1 = midi_mode ? midi_phase_increment_1 :
                                                    manual_phase_increment_third;
    assign selected_phase_increment_2 = midi_mode ? midi_phase_increment_2 :
                                                    manual_phase_increment_fifth;
    assign selected_voice_enable = midi_mode ? midi_voice_active :
                                   (chord_mode ? 3'b111 : 3'b001);

    phase_accumulator nco_0 (
        .clk(CLK100MHZ),
        .rst(rst),
        .phase_increment(selected_phase_increment_0),
        .phase(phase_0)
    );

    phase_accumulator nco_1 (
        .clk(CLK100MHZ),
        .rst(rst),
        .phase_increment(selected_phase_increment_1),
        .phase(phase_1)
    );

    phase_accumulator nco_2 (
        .clk(CLK100MHZ),
        .rst(rst),
        .phase_increment(selected_phase_increment_2),
        .phase(phase_2)
    );

    cordic_sine oscillator_0 (
        .clk(CLK100MHZ),
        .rst(rst),
        .phase_in(phase_0),
        .sine_out(sample_0)
    );

    cordic_sine oscillator_1 (
        .clk(CLK100MHZ),
        .rst(rst),
        .phase_in(phase_1),
        .sine_out(sample_1)
    );

    cordic_sine oscillator_2 (
        .clk(CLK100MHZ),
        .rst(rst),
        .phase_in(phase_2),
        .sine_out(sample_2)
    );

    audio_mixer mixer (
        .voice_enable(selected_voice_enable),
        .root_sample(sample_0),
        .third_sample(sample_1),
        .fifth_sample(sample_2),
        .mixed_sample(mixed_sample)
    );

    pdm_dac audio_dac (
        .clk(CLK100MHZ),
        .rst(rst),
        .sample_in(mixed_sample),
        .pdm_out(pdm_bit)
    );

    assign AUD_PWM = pdm_bit ? 1'bz : 1'b0;
    assign AUD_SD = 1'b1;
    assign LED[6:0] = midi_mode ? 7'b0000000 :
                                    (7'b0000001 << note_index);
    assign LED[7] = chord_mode && !midi_mode;
    assign LED[8] = midi_mode;
    assign LED[11:9] = midi_mode ? midi_voice_active : 3'b000;
endmodule
