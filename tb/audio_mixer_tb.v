`timescale 1ns / 1ps

module audio_mixer_tb;
    reg chord_mode;
    reg signed [15:0] root_sample;
    reg signed [15:0] third_sample;
    reg signed [15:0] fifth_sample;
    wire signed [15:0] mixed_sample;
    integer errors = 0;

    audio_mixer dut (
        .chord_mode(chord_mode),
        .root_sample(root_sample),
        .third_sample(third_sample),
        .fifth_sample(fifth_sample),
        .mixed_sample(mixed_sample)
    );

    task check_mix;
        input mode;
        input integer root_value;
        input integer third_value;
        input integer fifth_value;
        input integer expected;
        begin
            chord_mode = mode;
            root_sample = root_value;
            third_sample = third_value;
            fifth_sample = fifth_value;
            #1;
            if ($signed(mixed_sample) !== expected) begin
                $display("ERROR mode=%0d samples=%0d,%0d,%0d mixed=%0d expected=%0d",
                         mode, root_value, third_value, fifth_value,
                         $signed(mixed_sample), expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        check_mix(1'b0,   1000,  2000,  3000,   1000);
        check_mix(1'b1,   1000,  2000,  3000,   3000);
        check_mix(1'b1,  -1000, -2000, -3000,  -3000);
        check_mix(1'b1,  16384, 16384, 16384,  24576);
        check_mix(1'b1, -16384,-16384,-16384, -24576);
        check_mix(1'b1,  12000, -4000,  2000,   5000);

        if (errors == 0)
            $display("PASS: audio_mixer_tb");
        else
            $display("FAIL: audio_mixer_tb errors=%0d", errors);
        $finish;
    end
endmodule
