`timescale 1ns / 1ps

// Fully pipelined rotation-mode CORDIC.
// phase_in represents one complete turn: 0x00000000 = 0 degrees,
// 0x40000000 = 90 degrees, etc. The output peak is approximately 16384.
module cordic_sine (
    input  wire               clk,
    input  wire               rst,
    input  wire        [31:0] phase_in,
    output reg signed [15:0]  sine_out
);
    localparam integer ITERATIONS = 16;
    localparam integer XY_WIDTH   = 18;
    // 16384 * inverse CORDIC gain (0.607252935).
    localparam signed [XY_WIDTH-1:0] CORDIC_X0 = 18'sd9949;

    reg signed [XY_WIDTH-1:0] x_pipe [0:ITERATIONS];
    reg signed [XY_WIDTH-1:0] y_pipe [0:ITERATIONS];
    reg signed [31:0]         z_pipe [0:ITERATIONS];
    reg                       negate_pipe [0:ITERATIONS];
    integer i;

    function signed [31:0] atan_turns;
        input integer index;
        begin
            case (index)
                0:  atan_turns = 32'sh2000_0000;
                1:  atan_turns = 32'sh12E4_051E;
                2:  atan_turns = 32'sh09FB_385B;
                3:  atan_turns = 32'sh0511_11D4;
                4:  atan_turns = 32'sh028B_0D43;
                5:  atan_turns = 32'sh0145_D7E1;
                6:  atan_turns = 32'sh00A2_F61E;
                7:  atan_turns = 32'sh0051_7C55;
                8:  atan_turns = 32'sh0028_BE53;
                9:  atan_turns = 32'sh0014_5F2F;
                10: atan_turns = 32'sh000A_2F98;
                11: atan_turns = 32'sh0005_17CC;
                12: atan_turns = 32'sh0002_8BE6;
                13: atan_turns = 32'sh0001_45F3;
                14: atan_turns = 32'sh0000_A2FA;
                15: atan_turns = 32'sh0000_517D;
                default: atan_turns = 32'sd0;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            sine_out <= 16'sd0;
            for (i = 0; i <= ITERATIONS; i = i + 1) begin
                x_pipe[i]      <= {XY_WIDTH{1'b0}};
                y_pipe[i]      <= {XY_WIDTH{1'b0}};
                z_pipe[i]      <= 32'sd0;
                negate_pipe[i] <= 1'b0;
            end
        end else begin
            x_pipe[0] <= CORDIC_X0;
            y_pipe[0] <= {XY_WIDTH{1'b0}};

            // Fold the full circle into 0..90 degrees. Sine is negative in
            // quadrants III and IV.
            case (phase_in[31:30])
                2'b00: begin
                    z_pipe[0]      <= $signed(phase_in);
                    negate_pipe[0] <= 1'b0;
                end
                2'b01: begin
                    z_pipe[0]      <= $signed(32'h8000_0000 - phase_in);
                    negate_pipe[0] <= 1'b0;
                end
                2'b10: begin
                    z_pipe[0]      <= $signed(phase_in - 32'h8000_0000);
                    negate_pipe[0] <= 1'b1;
                end
                default: begin
                    z_pipe[0]      <= $signed(32'h0000_0000 - phase_in);
                    negate_pipe[0] <= 1'b1;
                end
            endcase

            for (i = 0; i < ITERATIONS; i = i + 1) begin
                negate_pipe[i+1] <= negate_pipe[i];
                if (z_pipe[i] >= 0) begin
                    x_pipe[i+1] <= x_pipe[i] - (y_pipe[i] >>> i);
                    y_pipe[i+1] <= y_pipe[i] + (x_pipe[i] >>> i);
                    z_pipe[i+1] <= z_pipe[i] - atan_turns(i);
                end else begin
                    x_pipe[i+1] <= x_pipe[i] + (y_pipe[i] >>> i);
                    y_pipe[i+1] <= y_pipe[i] - (x_pipe[i] >>> i);
                    z_pipe[i+1] <= z_pipe[i] + atan_turns(i);
                end
            end

            if (negate_pipe[ITERATIONS])
                sine_out <= -$signed(y_pipe[ITERATIONS]);
            else
                sine_out <= $signed(y_pipe[ITERATIONS]);
        end
    end
endmodule
