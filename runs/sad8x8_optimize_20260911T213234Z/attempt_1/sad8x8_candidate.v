//#############################################################################
// Copyright: Zero ASIC. All rights Reserved.
// Author: Andreas Olofsson
// License:  MIT (see LICENSE file in LogikBench repository)
//#############################################################################
//
// 8x8 Sum-of-Absolute-Differences (SAD) block matcher (motion estimation).
//
// Two NxN pixel blocks are presented in parallel as packed buses (pixel k at
// bits [k*PW +: PW], raster order). All N*N absolute differences |a-b| are
// computed in parallel (one subtract/compare/select each, generated) and summed
// in an adder-tree reduction to the SAD. Registered I/O (valid_in -> valid_out,
// 1-cycle latency). No multiply (0 DSP), no memory (0 BRAM).
//
// Same clk/rst/valid/pixel-width conventions as the streaming 3x3 filters so it
// drops in at the tail of an image-processing pipeline as a measurement block
// (it is a reduction, not a same-size stream filter).
//
//#############################################################################

module sad8x8
  #(parameter N = 8,
    parameter PW = 8,
    parameter NP = N*N,
    parameter SADW = 14) // clog2(N*N*(2^PW-1)+1): 64*255=16320 -> 14
   (
    input		  clk,
    input		  rst,
    input		  valid_in,
    input [NP*PW-1:0]	  curblk, // current block, pixel k at [k*PW +: PW]
    input [NP*PW-1:0]	  refblk, // reference block, same packing
    output reg		  valid_out,
    output reg [SADW-1:0] sad
    );

   // per-pixel absolute differences (generated, one per pixel pair)
   wire [PW-1:0] ad [0:NP-1];
   genvar	 i;
   generate
      for (i = 0; i < NP; i = i + 1) begin : g_ad
         wire [PW-1:0] a = curblk[i*PW +: PW];
         wire [PW-1:0] b = refblk[i*PW +: PW];
         assign ad[i] = (a >= b) ? (a - b) : (b - a);
      end
   endgenerate

   // Binary adder tree reduction
   // Stage 0: 64 -> 32 (width PW+1 = 9)
   wire [PW:0] s0 [0:31];
   generate
      for (i = 0; i < 32; i = i + 1) begin : g_s0
         assign s0[i] = {1'b0, ad[2*i]} + {1'b0, ad[2*i+1]};
      end
   endgenerate

   // Stage 1: 32 -> 16 (width PW+2 = 10)
   wire [PW+1:0] s1 [0:15];
   generate
      for (i = 0; i < 16; i = i + 1) begin : g_s1
         assign s1[i] = {{1'b0}, s0[2*i]} + {{1'b0}, s0[2*i+1]};
      end
   endgenerate

   // Stage 2: 16 -> 8 (width PW+3 = 11)
   wire [PW+2:0] s2 [0:7];
   generate
      for (i = 0; i < 8; i = i + 1) begin : g_s2
         assign s2[i] = {{1'b0}, s1[2*i]} + {{1'b0}, s1[2*i+1]};
      end
   endgenerate

   // Stage 3: 8 -> 4 (width PW+4 = 12)
   wire [PW+3:0] s3 [0:3];
   generate
      for (i = 0; i < 4; i = i + 1) begin : g_s3
         assign s3[i] = {{1'b0}, s2[2*i]} + {{1'b0}, s2[2*i+1]};
      end
   endgenerate

   // Stage 4: 4 -> 2 (width PW+5 = 13)
   wire [PW+4:0] s4 [0:1];
   generate
      for (i = 0; i < 2; i = i + 1) begin : g_s4
         assign s4[i] = {{1'b0}, s3[2*i]} + {{1'b0}, s3[2*i+1]};
      end
   endgenerate

   // Stage 5: 2 -> 1 (width PW+6 = 14 = SADW)
   wire [SADW-1:0] acc;
   assign acc = {{1'b0}, s4[0]} + {{1'b0}, s4[1]};

   always @(posedge clk) begin
      if (rst) begin
         valid_out <= 1'b0; sad <= {SADW{1'b0}};
      end else begin
         valid_out <= valid_in;
         sad       <= acc;
      end
   end

endmodule