`timescale 1ns/1ps

//------------------------------------------------------------------------------
// atan_lut.v
//
// Lookup table for CORDIC rotation angles.
//
// Input:
//      index = iteration number (0 to 15)
//
// Output:
//      angle = atan(2^-index)
//              represented in 32-bit phase format
//
// Used by:
//      cordic_stage.v
//------------------------------------------------------------------------------

module atan_lut
(
    input  wire [3:0]  index,
    output reg  [31:0] angle
);

always @(*)
begin

    case(index)

        4'd0  : angle = 32'h20000000;   // atan(1)
        4'd1  : angle = 32'h12E4051E;   // atan(1/2)
        4'd2  : angle = 32'h09FB385B;   // atan(1/4)
        4'd3  : angle = 32'h051111D4;   // atan(1/8)

        4'd4  : angle = 32'h028B0D43;
        4'd5  : angle = 32'h0145D7E1;
        4'd6  : angle = 32'h00A2F61E;
        4'd7  : angle = 32'h00517C55;

        4'd8  : angle = 32'h0028BE53;
        4'd9  : angle = 32'h00145F2F;
        4'd10 : angle = 32'h000A2F98;
        4'd11 : angle = 32'h000517CC;

        4'd12 : angle = 32'h00028BE6;
        4'd13 : angle = 32'h000145F3;
        4'd14 : angle = 32'h0000A2FA;
        4'd15 : angle = 32'h0000517D;

        default : angle = 32'd0;

    endcase

end

endmodule