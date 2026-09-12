//#############################################################################
// Copyright: Zero ASIC. All rights Reserved.
// Author: Andreas Olofsson
// License:  MIT (see LICENSE file in LogikBench repository)
//#############################################################################
//
// Parallel CRC-32 (IEEE 802.3 / 10GbE frame check sequence).
//
// Polynomial 0x04C11DB7, reflected input/output, init 0xFFFFFFFF, final XOR
// 0xFFFFFFFF (the standard Ethernet FCS / CRC-32, check value 0xCBF43926 for
// ASCII "123456789").
//
// Processes W bits per clock (default 64, the 10GbE XGMII datapath). The
// per-bit reflected update is written as a combinational loop that synthesis
// unrolls into the parallel CRC XOR tree; the running CRC is tapped at every
// byte boundary (c_tap[]) so the final, possibly partial, word can fold in
// only its valid bytes.
//
// Streaming interface: assert in_valid with W bits of data. On the LAST word
// of a frame assert in_last and set in_bytes to the number of valid bytes in
// that word (1..W/8); the valid bytes are the low byte lanes (in_data[7:0] is
// byte 0). On non-last words all W/8 bytes are consumed and in_bytes is
// ignored. This supports arbitrary frame byte-lengths (partial final beat).
// out_crc / out_valid present the frame FCS one cycle after the last word.
//
//#############################################################################

module crc32
  #(parameter DW = 64)                  // datapath bits/clock (mult of 8)
   (
    input                  clk,
    input                  rst,      // synchronous, active high
    input                  in_valid,
    input [DW-1:0]         in_data,
    input                  in_last,  // last word of the frame
    input [$clog2(DW/8):0] in_bytes, // valid bytes in last word (1..DW/8)
    output reg             out_valid,
    output reg [31:0]      out_crc   // frame FCS (valid when out_valid)
    );

   localparam BW = DW/8;                // byte lanes
   localparam HBW = BW/2;               // half byte lanes

   localparam [31:0] POLY = 32'hEDB88320;   // reflect(0x04C11DB7)
   localparam [31:0] INIT = 32'hFFFFFFFF;

   reg [31:0]	     crc;        // running CRC (reflected domain)
   reg               active;     // a frame is in progress

   wire [31:0]	     cur = active ? crc : INIT;   // load INIT at frame start

   // Pipeline stage 1: fold low half of in_data
   reg [31:0]	     crc_half;
   reg [DW-1:HBW*8] in_data_hi_r;
   reg              in_valid_r;
   reg              in_last_r;
   reg [$clog2(DW/8):0] in_bytes_r;
   reg              active_r;

   // Combinational folding for stage 1 (low half)
   wire [31:0]      c_tap_stage1 [0:HBW];
   wire [31:0]      cnext_stage1;
   integer          b, i;

   always @* begin
      c_tap_stage1[0] = cur;
      for (b = 0; b < HBW; b = b + 1) begin
         c_tap_stage1[b+1] = c_tap_stage1[b];
         for (i = 0; i < 8; i = i + 1)
           c_tap_stage1[b+1] = (c_tap_stage1[b+1] >> 1) ^
                  (POLY & {32{c_tap_stage1[b+1][0] ^ in_data[b*8 + i]}});
      end
      cnext_stage1 = c_tap_stage1[HBW];
   end

   // Combinational folding for stage 2 (high half)
   wire [31:0]      c_tap_stage2 [0:HBW];
   wire [31:0]      cnext_stage2;

   always @* begin
      c_tap_stage2[0] = crc_half;
      for (b = 0; b < HBW; b = b + 1) begin
         c_tap_stage2[b+1] = c_tap_stage2[b];
         for (i = 0; i < 8; i = i + 1)
           c_tap_stage2[b+1] = (c_tap_stage2[b+1] >> 1) ^
                  (POLY & {32{c_tap_stage2[b+1][0] ^ in_data_hi_r[b*8 + i]}});
      end
      // last word folds only its valid bytes (in_bytes_r indicates how many from high half)
      cnext_stage2 = in_last_r ? c_tap_stage2[in_bytes_r - HBW] : c_tap_stage2[HBW];
   end

   always @(posedge clk) begin
      if (rst) begin
         crc       <= INIT;
         active    <= 1'b0;
         out_valid <= 1'b0;
         out_crc   <= 32'b0;
         crc_half  <= 32'b0;
         in_valid_r <= 1'b0;
         in_last_r <= 1'b0;
         in_bytes_r <= 'd0;
         active_r <= 1'b0;
         in_data_hi_r <= 'd0;
      end
      else begin
         out_valid <= 1'b0;
         
         // Stage 1: process low half on in_valid
         if (in_valid) begin
            crc_half <= cnext_stage1;
            in_data_hi_r <= in_data[DW-1:HBW*8];
            in_valid_r <= 1'b1;
            in_last_r <= in_last;
            in_bytes_r <= in_bytes;
            active_r <= active;
         end
         else begin
            in_valid_r <= 1'b0;
         end
         
         // Stage 2: process high half on in_valid_r
         if (in_valid_r) begin
            crc <= cnext_stage2;
            active <= ~in_last_r;          // re-init on the next frame
            if (in_last_r) begin
               out_valid <= 1'b1;
               out_crc <= cnext_stage2 ^ INIT; // final XOR
            end
         end
      end
   end

endmodule