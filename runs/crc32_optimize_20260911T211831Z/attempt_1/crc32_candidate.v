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

   // Precomputed byte-at-a-time CRC-32 lookahead matrix for reflected Poly 0xEDB88320
   // Each output bit is a fixed XOR of specific input and prior-CRC bits
   localparam [31:0] MATRIX [0:31][0:7] = '{
     '{32'h00000001, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000},
     '{32'h00000000, 32'h00000001, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000},
     '{32'h00000000, 32'h00000000, 32'h00000001, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000},
     '{32'h00000000, 32'h00000000, 32'h00000000, 32'h00000001, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000},
     '{32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000001, 32'h00000000, 32'h00000000, 32'h00000000},
     '{32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000001, 32'h00000000, 32'h00000000},
     '{32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000001, 32'h00000000},
     '{32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000001},
     '{32'h00000000, 32'h00000001, 32'h00000001, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000},
     '{32'h00000000, 32'h00000000, 32'h00000001, 32'h00000001, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000},
     '{32'h00000000, 32'h00000000, 32'h00000000, 32'h00000001, 32'h00000001, 32'h00000000, 32'h00000000, 32'h00000000},
     '{32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000001, 32'h00000001, 32'h00000000, 32'h00000000},
     '{32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000001, 32'h00000001, 32'h00000000},
     '{32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000001, 32'h00000001},
     '{32'hEDB88320, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000001},
     '{32'h7E8E78B0, 32'hEDB88320, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000},
     '{32'hBF3CBCD8, 32'h7E8E78B0, 32'hEDB88320, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000},
     '{32'h5F9E0E6C, 32'hBF3CBCD8, 32'h7E8E78B0, 32'hEDB88320, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000},
     '{32'hAFCF8736, 32'h5F9E0E6C, 32'hBF3CBCD8, 32'h7E8E78B0, 32'hEDB88320, 32'h00000000, 32'h00000000, 32'h00000000},
     '{32'h579E0E6B, 32'hAFCF8736, 32'h5F9E0E6C, 32'hBF3CBCD8, 32'h7E8E78B0, 32'hEDB88320, 32'h00000000, 32'h00000000},
     '{32'hABCF8765, 32'h579E0E6B, 32'hAFCF8736, 32'h5F9E0E6C, 32'hBF3CBCD8, 32'h7E8E78B0, 32'hEDB88320, 32'h00000000},
     '{32'h579E0E6B, 32'hABCF8765, 32'h579E0E6B, 32'hAFCF8736, 32'h5F9E0E6C, 32'hBF3CBCD8, 32'h7E8E78B0, 32'hEDB88320},
     '{32'hAFCF8736, 32'h579E0E6B, 32'hABCF8765, 32'h579E0E6B, 32'hAFCF8736, 32'h5F9E0E6C, 32'hBF3CBCD8, 32'h7E8E78B0},
     '{32'h5F9E0E6C, 32'hAFCF8736, 32'h579E0E6B, 32'hABCF8765, 32'h579E0E6B, 32'hAFCF8736, 32'h5F9E0E6C, 32'hBF3CBCD8},
     '{32'hBF3CBCD8, 32'h5F9E0E6C, 32'hAFCF8736, 32'h579E0E6B, 32'hABCF8765, 32'h579E0E6B, 32'hAFCF8736, 32'h5F9E0E6C},
     '{32'h7E8E78B0, 32'hBF3CBCD8, 32'h5F9E0E6C, 32'hAFCF8736, 32'h579E0E6B, 32'hABCF8765, 32'h579E0E6B, 32'hAFCF8736},
     '{32'hEDB88320, 32'h7E8E78B0, 32'hBF3CBCD8, 32'h5F9E0E6C, 32'hAFCF8736, 32'h579E0E6B, 32'hABCF8765, 32'h579E0E6B},
     '{32'h00000001, 32'hEDB88320, 32'h7E8E78B0, 32'hBF3CBCD8, 32'h5F9E0E6C, 32'hAFCF8736, 32'h579E0E6B, 32'hABCF8765},
     '{32'h00000000, 32'h00000001, 32'hEDB88320, 32'h7E8E78B0, 32'hBF3CBCD8, 32'h5F9E0E6C, 32'hAFCF8736, 32'h579E0E6B},
     '{32'h00000000, 32'h00000000, 32'h00000001, 32'hEDB88320, 32'h7E8E78B0, 32'hBF3CBCD8, 32'h5F9E0E6C, 32'hAFCF8736},
     '{32'h00000000, 32'h00000000, 32'h00000000, 32'h00000001, 32'hEDB88320, 32'h7E8E78B0, 32'hBF3CBCD8, 32'h5F9E0E6C},
     '{32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000001, 32'hEDB88320, 32'h7E8E78B0, 32'hBF3CBCD8}
   };

   // Running CRC tapped at each byte boundary: c_tap[n] = CRC after folding the
   // low n bytes of in_data. These are intermediate nets of one XOR tree.
   reg [31:0]	     c_tap [0:BW];
   reg [31:0]	     cnext;

   // Helper function: compute one output bit of byte-wide CRC using the lookahead matrix
   function [0:0] byte_crc_bit;
      input [31:0] crc_in;
      input [7:0]  data_byte;
      input [4:0]  bit_idx;
      integer      b, i;
      reg          result;
   begin
      result = 1'b0;
      for (b = 0; b < 8; b = b + 1) begin
         if (MATRIX[bit_idx][b][b]) result = result ^ data_byte[b];
      end
      for (i = 0; i < 32; i = i + 1) begin
         if (MATRIX[bit_idx][8 + i][i]) result = result ^ crc_in[i];
      end
      byte_crc_bit = result;
   end
   endfunction

   // Compute all 32 output bits for a byte-wide CRC fold
   function [31:0] byte_crc_fold;
      input [31:0] crc_in;
      input [7:0]  data_byte;
      reg [31:0]   result;
      integer      bit_idx;
   begin
      for (bit_idx = 0; bit_idx < 32; bit_idx = bit_idx + 1) begin
         result[bit_idx] = byte_crc_bit(crc_in, data_byte, bit_idx);
      end
      byte_crc_fold = result;
   end
   endfunction

   always @* begin
      c_tap[0] = cur;
      // Use byte-parallel lookahead for each byte
      for (integer b = 0; b < BW; b = b + 1) begin
         c_tap[b+1] = byte_crc_fold(c_tap[b], in_data[b*8 +: 8]);
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