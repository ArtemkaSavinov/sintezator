`timescale 1ns / 1ps

module audio_mixer_tb;
    reg [2:0] voice_enable;
    reg signed [15:0] root_sample;
    reg signed [15:0] third_sample;
    reg signed [15:0] fifth_sample;
    wire signed [15:0] mixed_sample;
    integer errors = 0;

    audio_mixer dut (
        .voice_enable(voice_enable),
        .root_sample(root_sample),
        .third_sample(third_sample),
        .fifth_sample(fifth_sample),
        .mixed_sample(mixed_sample)
    );

    task check_mix;
        input [2:0] enable;
        input integer root_value;
        input integer third_value;
        input integer fifth_value;
        input integer expected;
        begin
            voice_enable = enable;
            root_sample = root_value;
            third_sample = third_value;
            fifth_sample = fifth_value;
            #1;
            if ($signed(mixed_sample) !== expected) begin
                $display("ERROR enable=%b samples=%0d,%0d,%0d mixed=%0d expected=%0d",
                         enable, root_value, third_value, fifth_value,
                         $signed(mixed_sample), expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        check_mix(3'b000,  1000,  2000,  3000,      0);
        check_mix(3'b001,  1000,  2000,  3000,   1000);
        check_mix(3'b010,  1000,  2000,  3000,   2000);
        check_mix(3'b111,  1000,  2000,  3000,   3000);
        check_mix(3'b111, -1000, -2000, -3000,  -3000);
        check_mix(3'b111, 16384, 16384, 16384,  24576);
        check_mix(3'b111,-16384,-16384,-16384, -24576);
        check_mix(3'b101, 12000, -4000,  2000,   7000);

        if (errors == 0)
            $display("PASS: audio_mixer_tb");
        else
            $display("FAIL: audio_mixer_tb errors=%0d", errors);
        $finish;
    end
endmodule
