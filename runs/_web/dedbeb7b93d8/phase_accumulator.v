`timescale 1ns/1ps

// PHASE_ACCUMULATOR / NCO block.
// fout = fclk * tuning_word / 2^32.
module phase_accumulator (
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,
    input  wire [31:0] tuning_word,
    output reg  [31:0] phase,
    output reg         phase_valid
);
    always @(posedge clk) begin
        if (rst) begin
            phase       <= 32'd0;
            phase_valid <= 1'b0;
        end else if (enable) begin
            phase       <= phase + tuning_word;
            phase_valid <= 1'b1;
        end else begin
            phase_valid <= 1'b0;
        end
    end
endmodule
