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

   // Stage 1: compute first half of fold
   wire [31:0]	     cur = active ? crc : INIT;   // load INIT at frame start

   reg [31:0]	     c_tap_s1 [0:HBW];
   reg [31:0]	     c_tap_s1_out;
   integer	     b, i;

   always @* begin
      c_tap_s1[0] = cur;
      for (b = 0; b < HBW; b = b + 1) begin
         c_tap_s1[b+1] = c_tap_s1[b];
         for (i = 0; i < 8; i = i + 1)
           c_tap_s1[b+1] = (c_tap_s1[b+1] >> 1) ^
                  (POLY & {32{c_tap_s1[b+1][0] ^ in_data[b*8 + i]}});
      end
      c_tap_s1_out = c_tap_s1[HBW];
   end

   // Pipeline registers
   reg [31:0]	     crc_mid;
   reg [DW/2-1:0]   data_hi_reg;
   reg               last_reg;
   reg [$clog2(DW/8):0] bytes_reg;
   reg               valid_reg;

   // Stage 2: compute second half of fold
   reg [31:0]	     cur_s2;
   reg [31:0]	     c_tap_s2 [0:HBW];
   reg [31:0]	     cnext;
   reg [$clog2(DW/8):0] bytes_s2_adjusted;

   always @* begin
      cur_s2 = crc_mid;
      
      // Adjust bytes for stage 2: if we had N bytes to fold and N > HBW,
      // then in stage 2 we need to fold (N - HBW) bytes
      if (last_reg && bytes_reg > HBW) begin
         bytes_s2_adjusted = bytes_reg - HBW;
      end else if (last_reg && bytes_reg <= HBW) begin
         // All bytes were processed in stage 1
         bytes_s2_adjusted = 0;
      end else begin
         // Not the last word, fold all remaining bytes
         bytes_s2_adjusted = HBW;
      end
      
      c_tap_s2[0] = cur_s2;
      for (b = 0; b < HBW; b = b + 1) begin
         c_tap_s2[b+1] = c_tap_s2[b];
         for (i = 0; i < 8; i = i + 1)
           c_tap_s2[b+1] = (c_tap_s2[b+1] >> 1) ^
                  (POLY & {32{c_tap_s2[b+1][0] ^ data_hi_reg[b*8 + i]}});
      end
      
      // Select output: if last and bytes was > HBW, use adjusted; 
      // if last and bytes <= HBW, use c_tap_s2[0] (no fold);
      // if not last, use c_tap_s2[HBW]
      if (last_reg) begin
         if (bytes_reg <= HBW) begin
            cnext = c_tap_s2[0];
         end else begin
            cnext = c_tap_s2[bytes_s2_adjusted];
         end
      end else begin
         cnext = c_tap_s2[HBW];
      end
   end

   always @(posedge clk) begin
      if (rst) begin
         crc       <= INIT;
         active    <= 1'b0;
         out_valid <= 1'b0;
         out_crc   <= 32'b0;
         crc_mid   <= 32'b0;
         data_hi_reg <= {(DW/2){1'b0}};
         last_reg  <= 1'b0;
         bytes_reg <= {($clog2(DW/8)+1){1'b0}};
         valid_reg <= 1'b0;
      end
      else begin
         out_valid <= 1'b0;
         
         // Stage 2: produce final output
         if (valid_reg) begin
            crc    <= cnext;
            active <= ~last_reg;
            if (last_reg) begin
               out_valid <= 1'b1;
               out_crc   <= cnext ^ INIT;
            end
         end
         
         // Stage 1: latch for stage 2
         if (in_valid) begin
            crc_mid    <= c_tap_s1_out;
            data_hi_reg <= in_data[DW-1:DW/2];
            last_reg   <= in_last;
            bytes_reg  <= in_bytes;
            valid_reg  <= 1'b1;
         end else begin
            valid_reg  <= 1'b0;
         end
      end
   end

endmodule