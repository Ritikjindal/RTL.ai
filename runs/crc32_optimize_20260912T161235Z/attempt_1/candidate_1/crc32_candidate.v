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
   localparam HBW = BW/2;               // half-width in bytes

   localparam [31:0] POLY = 32'hEDB88320;   // reflect(0x04C11DB7)
   localparam [31:0] INIT = 32'hFFFFFFFF;

   reg [31:0]	     crc;        // running CRC (reflected domain)
   reg               active;     // a frame is in progress

   wire [31:0]	     cur = active ? crc : INIT;   // load INIT at frame start

   // First stage: compute c_tap[0..HBW] (fold bytes 0 to HBW-1)
   reg [31:0]	     c_tap [0:HBW];
   integer	     b, i;

   always @* begin
      c_tap[0] = cur;
      for (b = 0; b < HBW; b = b + 1) begin
         c_tap[b+1] = c_tap[b];
         for (i = 0; i < 8; i = i + 1)
           c_tap[b+1] = (c_tap[b+1] >> 1) ^
                  (POLY & {32{c_tap[b+1][0] ^ in_data[b*8 + i]}});
      end
   end

   // Pipeline registers for the second stage
   reg [31:0]	     crc_half;
   reg [DW-1:HBW*8]  in_data_r;
   reg               in_last_r;
   reg [$clog2(DW/8):0] in_bytes_r;
   reg               in_valid_r;
   reg               active_r;

   // Second stage: compute c_tap_2[0..HBW] (fold bytes HBW to BW-1)
   reg [31:0]	     c_tap_2 [0:HBW];
   reg [31:0]	     cnext;

   wire [31:0]	     cur_2 = active_r ? crc_half : INIT;

   always @* begin
      c_tap_2[0] = cur_2;
      for (b = 0; b < HBW; b = b + 1) begin
         c_tap_2[b+1] = c_tap_2[b];
         for (i = 0; i < 8; i = i + 1)
           c_tap_2[b+1] = (c_tap_2[b+1] >> 1) ^
                  (POLY & {32{c_tap_2[b+1][0] ^ in_data_r[b*8 + i]}});
      end
      // last word folds only its valid bytes; full words fold all HBW
      cnext = in_last_r ? c_tap_2[in_bytes_r - HBW] : c_tap_2[HBW];
   end

   always @(posedge clk) begin
      if (rst) begin
         crc       <= INIT;
         active    <= 1'b0;
         crc_half  <= 32'b0;
         in_data_r <= {DW-HBW*8{1'b0}};
         in_last_r <= 1'b0;
         in_bytes_r <= {($clog2(DW/8)+1){1'b0}};
         in_valid_r <= 1'b0;
         active_r  <= 1'b0;
         out_valid <= 1'b0;
         out_crc   <= 32'b0;
      end
      else begin
         // First stage: update pipeline registers
         if (in_valid) begin
            crc_half  <= c_tap[HBW];
            in_data_r <= in_data[DW-1:HBW*8];
            in_last_r <= in_last;
            in_bytes_r <= in_bytes;
            in_valid_r <= 1'b1;
            active_r  <= active;
         end else begin
            in_valid_r <= 1'b0;
         end

         // Second stage: update output
         out_valid <= 1'b0;
         if (in_valid_r) begin
            crc    <= cnext;
            active <= ~in_last_r;
            if (in_last_r) begin
               out_valid <= 1'b1;
               out_crc   <= cnext ^ INIT; // final XOR
            end
         end
      end
   end

endmodule