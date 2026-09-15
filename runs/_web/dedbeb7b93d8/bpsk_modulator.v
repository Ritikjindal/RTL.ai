`timescale 1ns/1ps
//------------------------------------------------------------------------------
// bpsk_modulator.v
//
// GPS L1 BPSK Modulator
//
// Maps:
//      gps_chip = 0  --> +carrier
//      gps_chip = 1  --> -carrier
//
// Inputs:
//      carrier   : 14-bit cosine sample from CORDIC
//      gps_chip  : Spread GPS chip
//
// Output:
//      mod_sample : BPSK-modulated carrier
//------------------------------------------------------------------------------

module bpsk_modulator
(
    input  wire               clk,
    input  wire               rst,

    input  wire               enable,
    input  wire               in_valid,

    input  wire               gps_chip,
    input  wire signed [13:0] carrier,

    output reg  signed [13:0] mod_sample,
    output reg                out_valid
);

    always @(posedge clk)
    begin
        if (rst)
        begin
            mod_sample <= 14'sd0;
            out_valid  <= 1'b0;
        end
        else
        begin
            out_valid <= enable && in_valid;

            if (enable && in_valid)
            begin
                if (gps_chip)
                    mod_sample <= -carrier;
                else
                    mod_sample <= carrier;
            end
            else
            begin
                mod_sample <= 14'sd0;
            end
        end
    end

endmodule