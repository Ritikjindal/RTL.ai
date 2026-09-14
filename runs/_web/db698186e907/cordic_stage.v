`timescale 1ns/1ps
//------------------------------------------------------------------------------
// cordic_stage.v
//
// One pipelined CORDIC rotation stage.
//
// Inputs:
//      x_in, y_in : Current vector
//      z_in       : Remaining angle
//
// Outputs:
//      x_out, y_out : Rotated vector
//      z_out        : Updated remaining angle
//
// SHIFT specifies the iteration number (0-15).
// The corresponding atan angle is obtained from atan_lut.
//
//------------------------------------------------------------------------------

module cordic_stage
#(
    parameter [3:0] SHIFT = 4'd0
)
(
    input  wire               clk,
    input  wire               rst,

    input  wire signed [17:0] x_in,
    input  wire signed [17:0] y_in,
    input  wire signed [31:0] z_in,

    input  wire               in_valid,

    output reg signed [17:0]  x_out,
    output reg signed [17:0]  y_out,
    output reg signed [31:0]  z_out,

    output reg                out_valid
);

    //--------------------------------------------------
    // Lookup angle for this stage
    //--------------------------------------------------

    wire [31:0] atan_angle;

    atan_lut LUT
    (
        .index(SHIFT),
        .angle(atan_angle)
    );

    //--------------------------------------------------
    // One CORDIC iteration
    //--------------------------------------------------

    always @(posedge clk)
    begin
        if (rst)
        begin
            x_out     <= 18'sd0;
            y_out     <= 18'sd0;
            z_out     <= 32'sd0;
            out_valid <= 1'b0;
        end
        else
        begin
            out_valid <= in_valid;

            if (z_in >= 0)
            begin
                // Rotate clockwise
                x_out <= x_in - (y_in >>> SHIFT);
                y_out <= y_in + (x_in >>> SHIFT);
                z_out <= z_in - $signed(atan_angle);
            end
            else
            begin
                // Rotate counter-clockwise
                x_out <= x_in + (y_in >>> SHIFT);
                y_out <= y_in - (x_in >>> SHIFT);
                z_out <= z_in + $signed(atan_angle);
            end
        end
    end

endmodule