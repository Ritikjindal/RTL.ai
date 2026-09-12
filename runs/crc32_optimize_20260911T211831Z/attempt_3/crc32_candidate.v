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

   localparam [31:0] POLY = 32'hEDB88320;   // reflect(0x04C11DB7)
   localparam [31:0] INIT = 32'hFFFFFFFF;

   reg [31:0]	     crc;        // running CRC (reflected domain)
   reg               active;     // a frame is in progress

   wire [31:0]	     cur = active ? crc : INIT;   // load INIT at frame start

   // Running CRC tapped at each byte boundary: c_tap[n] = CRC after folding the
   // low n bytes of in_data. These are intermediate nets of one XOR tree.
   reg [31:0]	     c_tap [0:BW];
   reg [31:0]	     cnext;
   integer	     b;

   // Parallel 8-bit CRC update equations (reflected polynomial 0xEDB88320)
   // For each byte position b, compute c_tap[b+1] from c_tap[b] and in_data[b*8+7:b*8]
   // using the closed-form XOR-table equations for reflected CRC-32.
   
   function [31:0] crc_byte_parallel;
      input [31:0] state;
      input [7:0]  byte_in;
      reg [31:0]   result;
      begin
         // Reflected CRC-32 per-byte parallel update:
         // Output bits are XOR of specific input bits determined by the polynomial.
         // These equations are derived from the bit-serial loop unrolled 8 times.
         result[0]  = state[24] ^ state[30] ^ byte_in[0] ^ byte_in[6];
         result[1]  = state[25] ^ state[31] ^ byte_in[1] ^ byte_in[7] ^ state[24] ^ state[30] ^ byte_in[0] ^ byte_in[6];
         result[2]  = state[26] ^ byte_in[2] ^ state[25] ^ state[31] ^ byte_in[1] ^ byte_in[7] ^ state[24] ^ state[30] ^ byte_in[0] ^ byte_in[6];
         result[3]  = state[27] ^ byte_in[3] ^ state[26] ^ byte_in[2] ^ state[25] ^ state[31] ^ byte_in[1] ^ byte_in[7] ^ state[24] ^ state[30] ^ byte_in[0] ^ byte_in[6];
         result[4]  = state[28] ^ byte_in[4] ^ state[27] ^ byte_in[3] ^ state[26] ^ byte_in[2] ^ state[24] ^ state[30] ^ byte_in[0] ^ byte_in[6];
         result[5]  = state[29] ^ byte_in[5] ^ state[28] ^ byte_in[4] ^ state[27] ^ byte_in[3] ^ state[25] ^ state[31] ^ byte_in[1] ^ byte_in[7] ^ state[24] ^ state[30] ^ byte_in[0] ^ byte_in[6];
         result[6]  = state[30] ^ byte_in[6] ^ state[29] ^ byte_in[5] ^ state[28] ^ byte_in[4] ^ state[26] ^ byte_in[2] ^ state[25] ^ state[31] ^ byte_in[1] ^ byte_in[7];
         result[7]  = state[31] ^ byte_in[7] ^ state[29] ^ byte_in[5] ^ state[28] ^ byte_in[4] ^ state[27] ^ byte_in[3] ^ state[26] ^ byte_in[2];
         result[8]  = state[0] ^ state[27] ^ byte_in[3] ^ state[29] ^ byte_in[5] ^ state[28] ^ byte_in[4];
         result[9]  = state[1] ^ state[28] ^ byte_in[4] ^ state[29] ^ byte_in[5] ^ state[30] ^ byte_in[6];
         result[10] = state[2] ^ state[29] ^ byte_in[5] ^ state[30] ^ byte_in[6] ^ state[31] ^ byte_in[7] ^ state[24] ^ state[30] ^ byte_in[0] ^ byte_in[6];
         result[11] = state[3] ^ state[30] ^ byte_in[6] ^ state[31] ^ byte_in[7] ^ state[24] ^ byte_in[0] ^ state[25] ^ byte_in[1] ^ state[24] ^ state[30] ^ byte_in[0] ^ byte_in[6];
         result[12] = state[4] ^ state[31] ^ byte_in[7] ^ state[25] ^ byte_in[1] ^ state[26] ^ byte_in[2] ^ state[24] ^ state[30] ^ byte_in[0] ^ byte_in[6];
         result[13] = state[5] ^ state[26] ^ byte_in[2] ^ state[27] ^ byte_in[3] ^ state[25] ^ state[31] ^ byte_in[1] ^ byte_in[7];
         result[14] = state[6] ^ state[27] ^ byte_in[3] ^ state[28] ^ byte_in[4] ^ state[26] ^ byte_in[2];
         result[15] = state[7] ^ state[28] ^ byte_in[4] ^ state[29] ^ byte_in[5] ^ state[27] ^ byte_in[3];
         result[16] = state[8] ^ state[29] ^ byte_in[5] ^ state[30] ^ byte_in[6] ^ state[24] ^ state[30] ^ byte_in[0] ^ byte_in[6];
         result[17] = state[9] ^ state[30] ^ byte_in[6] ^ state[31] ^ byte_in[7] ^ state[25] ^ state[31] ^ byte_in[1] ^ byte_in[7];
         result[18] = state[10] ^ state[31] ^ byte_in[7] ^ state[26] ^ byte_in[2];
         result[19] = state[11] ^ state[27] ^ byte_in[3];
         result[20] = state[12] ^ state[28] ^ byte_in[4];
         result[21] = state[13] ^ state[29] ^ byte_in[5];
         result[22] = state[14] ^ state[24] ^ byte_in[0] ^ state[30] ^ byte_in[6];
         result[23] = state[15] ^ state[25] ^ byte_in[1] ^ state[31] ^ byte_in[7] ^ state[24] ^ state[30] ^ byte_in[0] ^ byte_in[6];
         result[24] = state[16] ^ state[26] ^ byte_in[2] ^ state[25] ^ state[31] ^ byte_in[1] ^ byte_in[7];
         result[25] = state[17] ^ state[27] ^ byte_in[3] ^ state[26] ^ byte_in[2];
         result[26] = state[18] ^ state[28] ^ byte_in[4] ^ state[27] ^ byte_in[3] ^ state[24] ^ state[30] ^ byte_in[0] ^ byte_in[6];
         result[27] = state[19] ^ state[29] ^ byte_in[5] ^ state[28] ^ byte_in[4] ^ state[25] ^ state[31] ^ byte_in[1] ^ byte_in[7];
         result[28] = state[20] ^ state[29] ^ byte_in[5] ^ state[26] ^ byte_in[2];
         result[29] = state[21] ^ state[30] ^ byte_in[6] ^ state[27] ^ byte_in[3];
         result[30] = state[22] ^ state[31] ^ byte_in[7] ^ state[28] ^ byte_in[4];
         result[31] = state[23] ^ state[29] ^ byte_in[5];
         crc_byte_parallel = result;
      end
   endfunction

   always @* begin
      c_tap[0] = cur;
      for (b = 0; b < BW; b = b + 1) begin
         c_tap[b+1] = crc_byte_parallel(c_tap[b], in_data[b*8 +: 8]);
      end
      // last word folds only its valid bytes; full words fold all BW
      cnext = in_last ? c_tap[in_bytes] : c_tap[BW];
   end

   always @(posedge clk) begin
      if (rst) begin
         crc       <= INIT;
         active    <= 1'b0;
         out_valid <= 1'b0;
         out_crc   <= 32'b0;
      end
      else begin
         out_valid <= 1'b0;
         if (in_valid) begin
            crc    <= cnext;
            active <= ~in_last;          // re-init on the next frame
            if (in_last) begin
               out_valid <= 1'b1;
               out_crc   <= cnext ^ INIT; // final XOR
            end
         end
      end
   end

endmodule