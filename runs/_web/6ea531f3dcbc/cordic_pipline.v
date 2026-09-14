`timescale 1ns/1ps
//------------------------------------------------------------------------------
// cordic_pipeline.v
//
// 16-stage pipelined CORDIC cosine generator.
//
// Input:
//      phase       : 32-bit phase from phase accumulator
//      phase_valid : Valid input pulse
//
// Output:
//      cos_out     : 14-bit cosine sample
//      cos_valid   : Valid output pulse
//
//------------------------------------------------------------------------------

module cordic_pipeline
(
    input  wire               clk,
    input  wire               rst,

    input  wire signed [31:0] phase,
    input  wire               phase_valid,

    output wire signed [13:0] cos_out,
    output wire               cos_valid
);

    //--------------------------------------------------
    // Initial CORDIC vector
    //
    // K ≈ 0.607252
    // 0.607252 × 2^17 ≈ 79598
    //--------------------------------------------------

    localparam signed [17:0] X0 = 18'sd79598;
    localparam signed [17:0] Y0 = 18'sd0;

    //--------------------------------------------------
    // Stage Interconnect Signals
    //--------------------------------------------------

    wire signed [17:0] x [0:16];
    wire signed [17:0] y [0:16];
    wire signed [31:0] z [0:16];

    wire valid [0:16];

    //--------------------------------------------------
    // Stage 0 Inputs
    //--------------------------------------------------

    assign x[0] = X0;
    assign y[0] = Y0;
    assign z[0] = phase;

    assign valid[0] = phase_valid;

    //--------------------------------------------------
    // 16 CORDIC Stages
    //--------------------------------------------------

    cordic_stage #(.SHIFT(4'd0)) stage0 (
        .clk(clk), .rst(rst),
        .x_in(x[0]), .y_in(y[0]), .z_in(z[0]),
        .in_valid(valid[0]),
        .x_out(x[1]), .y_out(y[1]), .z_out(z[1]),
        .out_valid(valid[1])
    );

    cordic_stage #(.SHIFT(4'd1)) stage1 (
        .clk(clk), .rst(rst),
        .x_in(x[1]), .y_in(y[1]), .z_in(z[1]),
        .in_valid(valid[1]),
        .x_out(x[2]), .y_out(y[2]), .z_out(z[2]),
        .out_valid(valid[2])
    );

    cordic_stage #(.SHIFT(4'd2)) stage2 (
        .clk(clk), .rst(rst),
        .x_in(x[2]), .y_in(y[2]), .z_in(z[2]),
        .in_valid(valid[2]),
        .x_out(x[3]), .y_out(y[3]), .z_out(z[3]),
        .out_valid(valid[3])
    );

    cordic_stage #(.SHIFT(4'd3)) stage3 (
        .clk(clk), .rst(rst),
        .x_in(x[3]), .y_in(y[3]), .z_in(z[3]),
        .in_valid(valid[3]),
        .x_out(x[4]), .y_out(y[4]), .z_out(z[4]),
        .out_valid(valid[4])
    );

    cordic_stage #(.SHIFT(4'd4)) stage4 (
        .clk(clk), .rst(rst),
        .x_in(x[4]), .y_in(y[4]), .z_in(z[4]),
        .in_valid(valid[4]),
        .x_out(x[5]), .y_out(y[5]), .z_out(z[5]),
        .out_valid(valid[5])
    );

    cordic_stage #(.SHIFT(4'd5)) stage5 (
        .clk(clk), .rst(rst),
        .x_in(x[5]), .y_in(y[5]), .z_in(z[5]),
        .in_valid(valid[5]),
        .x_out(x[6]), .y_out(y[6]), .z_out(z[6]),
        .out_valid(valid[6])
    );

    cordic_stage #(.SHIFT(4'd6)) stage6 (
        .clk(clk), .rst(rst),
        .x_in(x[6]), .y_in(y[6]), .z_in(z[6]),
        .in_valid(valid[6]),
        .x_out(x[7]), .y_out(y[7]), .z_out(z[7]),
        .out_valid(valid[7])
    );

    cordic_stage #(.SHIFT(4'd7)) stage7 (
        .clk(clk), .rst(rst),
        .x_in(x[7]), .y_in(y[7]), .z_in(z[7]),
        .in_valid(valid[7]),
        .x_out(x[8]), .y_out(y[8]), .z_out(z[8]),
        .out_valid(valid[8])
    );

    cordic_stage #(.SHIFT(4'd8)) stage8 (
        .clk(clk), .rst(rst),
        .x_in(x[8]), .y_in(y[8]), .z_in(z[8]),
        .in_valid(valid[8]),
        .x_out(x[9]), .y_out(y[9]), .z_out(z[9]),
        .out_valid(valid[9])
    );

    cordic_stage #(.SHIFT(4'd9)) stage9 (
        .clk(clk), .rst(rst),
        .x_in(x[9]), .y_in(y[9]), .z_in(z[9]),
        .in_valid(valid[9]),
        .x_out(x[10]), .y_out(y[10]), .z_out(z[10]),
        .out_valid(valid[10])
    );

    cordic_stage #(.SHIFT(4'd10)) stage10 (
        .clk(clk), .rst(rst),
        .x_in(x[10]), .y_in(y[10]), .z_in(z[10]),
        .in_valid(valid[10]),
        .x_out(x[11]), .y_out(y[11]), .z_out(z[11]),
        .out_valid(valid[11])
    );

    cordic_stage #(.SHIFT(4'd11)) stage11 (
        .clk(clk), .rst(rst),
        .x_in(x[11]), .y_in(y[11]), .z_in(z[11]),
        .in_valid(valid[11]),
        .x_out(x[12]), .y_out(y[12]), .z_out(z[12]),
        .out_valid(valid[12])
    );

    cordic_stage #(.SHIFT(4'd12)) stage12 (
        .clk(clk), .rst(rst),
        .x_in(x[12]), .y_in(y[12]), .z_in(z[12]),
        .in_valid(valid[12]),
        .x_out(x[13]), .y_out(y[13]), .z_out(z[13]),
        .out_valid(valid[13])
    );

    cordic_stage #(.SHIFT(4'd13)) stage13 (
        .clk(clk), .rst(rst),
        .x_in(x[13]), .y_in(y[13]), .z_in(z[13]),
        .in_valid(valid[13]),
        .x_out(x[14]), .y_out(y[14]), .z_out(z[14]),
        .out_valid(valid[14])
    );

    cordic_stage #(.SHIFT(4'd14)) stage14 (
        .clk(clk), .rst(rst),
        .x_in(x[14]), .y_in(y[14]), .z_in(z[14]),
        .in_valid(valid[14]),
        .x_out(x[15]), .y_out(y[15]), .z_out(z[15]),
        .out_valid(valid[15])
    );

    cordic_stage #(.SHIFT(4'd15)) stage15 (
        .clk(clk), .rst(rst),
        .x_in(x[15]), .y_in(y[15]), .z_in(z[15]),
        .in_valid(valid[15]),
        .x_out(x[16]), .y_out(y[16]), .z_out(z[16]),
        .out_valid(valid[16])
    );

    //--------------------------------------------------
    // Output
    //--------------------------------------------------

    assign cos_out   = x[16][17:4];
    assign cos_valid = valid[16];

endmodule