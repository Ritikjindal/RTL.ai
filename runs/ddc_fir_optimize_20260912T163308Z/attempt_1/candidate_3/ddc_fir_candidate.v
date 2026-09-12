//#############################################################################
// Copyright: Zero ASIC. All rights Reserved.
// Author: Andreas Olofsson
// License:  MIT (see LICENSE file in LogikBench repository)
//#############################################################################
//
// Compensation / low-pass FIR filter (direct form), one lane.
//
// Runs at the decimated (CIC output) rate. Its purpose is to flatten the CIC
// passband droop (the sin(x)/x shape) and provide final low-pass shaping.
//
// Structure (per CLAUDE.md: replicated hardware via generate, NOT a procedural
// MAC loop):
//   - a tapped delay line of NTAP samples,
//   - a genvar generate loop instantiating ONE signed multiplier per tap into
//     a "products" array,
//   - an explicit running-sum reduction of the products array.
//
// Coefficients are packed LSB-first into a single [NTAP*CW-1:0] parameter H;
// tap i occupies bits [i*CW +: CW] and is Q1.15. The default H is a unit
// impulse at the center tap (a pure delay), which is overridden at integration
// with real compensation coefficients.
//
// Output: the products are Q2.30; the accumulator is sized for NTAP additions,
// then rounded (round-half-up) and symmetrically saturated to OUTW bits.
//
//#############################################################################

module ddc_fir
  #(parameter		    IQW = 16,  // input sample width (Q1.15)
    parameter		    OUTW = 16, // output sample width (Q1.15)
    parameter		    CW = 16,   // coefficient width (Q1.15)
    parameter		    NTAP = 15, // number of taps
    parameter [NTAP*CW-1:0] H = {{(NTAP/2){{CW{1'b0}}}},
				 {1'b0, {(CW-1){1'b1}}},
				 {(NTAP/2){{CW{1'b0}}}}}
    )
   (
    input			 clk,
    input			 rst, // synchronous, active high
    input			 in_valid,
    input signed [IQW-1:0]	 in_data,
    output reg			 out_valid,
    output reg signed [OUTW-1:0] out_data
    );

   // Per-tap product width and accumulator headroom for NTAP additions.
   localparam PW   = IQW + CW;            // single product width (Q2.30)
   localparam GROW = $clog2(NTAP);        // extra bits for the sum
   localparam ACCW = PW + GROW;           // accumulator width
   localparam SH   = CW - 1;             // fractional bits to drop (15)

   // Tapped delay line: shift[0] = newest sample.
   reg signed [IQW-1:0]	shift [0:NTAP-1];
   integer		j;

   // One product per tap (generated hardware, not a procedural MAC loop).
   wire signed [PW-1:0]	prod [0:NTAP-1];
   genvar		gt;
   generate
      for (gt = 0; gt < NTAP; gt = gt + 1) begin : g_tap
         wire signed [CW-1:0] coeff = H[gt*CW +: CW];
         assign prod[gt] = shift[gt] * coeff;
      end
   endgenerate

   // Two-stage pipelined reduction:
   // Stage 1: Parallel partial-sum trees for lower and upper halves
   
   // Lower half: sum of prod[0..7] (8 taps)
   wire signed [ACCW-1:0] psumA [0:8];
   assign psumA[0] = {ACCW{1'b0}};
   genvar gsA;
   generate
      for (gsA = 0; gsA < 8; gsA = gsA + 1) begin : g_sum_a
         assign psumA[gsA+1] = psumA[gsA] +
                               {{(ACCW-PW){prod[gsA][PW-1]}}, prod[gsA]};
      end
   endgenerate
   wire signed [ACCW-1:0] accA = psumA[8];

   // Upper half: sum of prod[8..14] (7 taps)
   wire signed [ACCW-1:0] psumB [0:7];
   assign psumB[0] = {ACCW{1'b0}};
   genvar gsB;
   generate
      for (gsB = 0; gsB < 7; gsB = gsB + 1) begin : g_sum_b
         assign psumB[gsB+1] = psumB[gsB] +
                               {{(ACCW-PW){prod[gsB+8][PW-1]}}, prod[gsB+8]};
      end
   endgenerate
   wire signed [ACCW-1:0] accB = psumB[7];

   // Pipeline register to capture partial sums from stage 1
   reg signed [ACCW-1:0] partial_sum_reg_A;
   reg signed [ACCW-1:0] partial_sum_reg_B;
   reg valid_pipe1;

   // Stage 2 (combinational): combine the registered partial sums
   wire signed [ACCW-1:0] acc = partial_sum_reg_A + partial_sum_reg_B;

   // round-half-up then drop SH fractional bits
   wire signed [ACCW-1:0] racc = acc + (1 <<< (SH-1));
   wire signed [ACCW-1:0] sacc = racc >>> SH;

   // symmetric saturation to OUTW bits
   localparam signed [ACCW-1:0]	MAXA =  (1 <<< (OUTW-1)) - 1;
   localparam signed [ACCW-1:0]	MINA = -(1 <<< (OUTW-1));
   wire signed [OUTW-1:0]	sat = (sacc > MAXA) ? MAXA[OUTW-1:0] :
                                (sacc < MINA) ? MINA[OUTW-1:0] : sacc[OUTW-1:0];

   always @(posedge clk) begin
      if (rst) begin
         for (j = 0; j < NTAP; j = j + 1)
           shift[j] <= {IQW{1'b0}};
         partial_sum_reg_A <= {ACCW{1'b0}};
         partial_sum_reg_B <= {ACCW{1'b0}};
         valid_pipe1 <= 1'b0;
         out_valid <= 1'b0;
         out_data  <= {OUTW{1'b0}};
      end
      else begin
         // Pipeline stage 1: update shift register and capture partial sums
         if (in_valid) begin
            for (j = NTAP-1; j > 0; j = j - 1)
              shift[j] <= shift[j-1];
            shift[0] <= in_data;
         end
         partial_sum_reg_A <= accA;
         partial_sum_reg_B <= accB;
         valid_pipe1 <= in_valid;

         // Pipeline stage 2: combine partial sums and produce output
         out_valid <= valid_pipe1;
         out_data <= sat;
      end
   end

endmodule