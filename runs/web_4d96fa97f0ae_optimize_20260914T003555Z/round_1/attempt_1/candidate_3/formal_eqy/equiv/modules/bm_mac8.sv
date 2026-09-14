module miter (
  input  [ 63:0] \__pi_a_vec ,
  input  [ 63:0] \__pi_b_vec ,
  input  [  0:0] \__pi_clk ,
  input  [  0:0] \__pi_in_valid ,
  input  [  0:0] \__pi_rst ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [ 63:0] \__mp_a_reg__gold ,
  output [ 63:0] \__mp_b_reg__gold ,
  output [ 18:0] \__mp_c7__18_0__gold ,
  output [ 15:0] \__mp_m0__gold ,
  output [ 15:0] \__mp_m1__gold ,
  output [ 15:0] \__mp_m2__gold ,
  output [ 15:0] \__mp_m3__gold ,
  output [ 15:0] \__mp_m4__gold ,
  output [ 15:0] \__mp_m5__gold ,
  output [ 15:0] \__mp_m6__gold ,
  output [ 15:0] \__mp_m7__gold ,
  output [  0:0] \__mp_vld__gold ,
  output [ 63:0] \__mp_a_reg__gate ,
  output [ 63:0] \__mp_b_reg__gate ,
  output [ 18:0] \__mp_c7__18_0__gate ,
  output [ 15:0] \__mp_m0__gate ,
  output [ 15:0] \__mp_m1__gate ,
  output [ 15:0] \__mp_m2__gate ,
  output [ 15:0] \__mp_m3__gate ,
  output [ 15:0] \__mp_m4__gate ,
  output [ 15:0] \__mp_m5__gate ,
  output [ 15:0] \__mp_m6__gate ,
  output [ 15:0] \__mp_m7__gate ,
  output [  0:0] \__mp_vld__gate ,
  output [ 20:0] \__po_acc__gold ,
  output [  0:0] \__po_out_valid__gold ,
  output [ 20:0] \__po_acc__gate ,
  output [  0:0] \__po_out_valid__gate
);
  \gold.bm_mac8 gold (
    .\__pi_a_vec (\__pi_a_vec ),
    .\__pi_b_vec (\__pi_b_vec ),
    .\__pi_clk (\__pi_clk ),
    .\__pi_in_valid (\__pi_in_valid ),
    .\__pi_rst (\__pi_rst ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__mp_a_reg (\__mp_a_reg__gold ),
    .\__mp_b_reg (\__mp_b_reg__gold ),
    .\__mp_c7__18_0 (\__mp_c7__18_0__gold ),
    .\__mp_m0 (\__mp_m0__gold ),
    .\__mp_m1 (\__mp_m1__gold ),
    .\__mp_m2 (\__mp_m2__gold ),
    .\__mp_m3 (\__mp_m3__gold ),
    .\__mp_m4 (\__mp_m4__gold ),
    .\__mp_m5 (\__mp_m5__gold ),
    .\__mp_m6 (\__mp_m6__gold ),
    .\__mp_m7 (\__mp_m7__gold ),
    .\__mp_vld (\__mp_vld__gold ),
    .\__po_acc (\__po_acc__gold ),
    .\__po_out_valid (\__po_out_valid__gold )
  );
  \gate.bm_mac8 gate (
    .\__pi_a_vec (\__pi_a_vec ),
    .\__pi_b_vec (\__pi_b_vec ),
    .\__pi_clk (\__pi_clk ),
    .\__pi_in_valid (\__pi_in_valid ),
    .\__pi_rst (\__pi_rst ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__mp_a_reg (\__mp_a_reg__gate ),
    .\__mp_b_reg (\__mp_b_reg__gate ),
    .\__mp_c7__18_0 (\__mp_c7__18_0__gate ),
    .\__mp_m0 (\__mp_m0__gate ),
    .\__mp_m1 (\__mp_m1__gate ),
    .\__mp_m2 (\__mp_m2__gate ),
    .\__mp_m3 (\__mp_m3__gate ),
    .\__mp_m4 (\__mp_m4__gate ),
    .\__mp_m5 (\__mp_m5__gate ),
    .\__mp_m6 (\__mp_m6__gate ),
    .\__mp_m7 (\__mp_m7__gate ),
    .\__mp_vld (\__mp_vld__gate ),
    .\__po_acc (\__po_acc__gate ),
    .\__po_out_valid (\__po_out_valid__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(64, "assume") \__pi_a_vec__assume (\__pi_a_vec );
  miter_def_prop #(64, "assume") \__pi_b_vec__assume (\__pi_b_vec );
  miter_def_prop #(1, "assume") \__pi_clk__assume (\__pi_clk );
  miter_def_prop #(1, "assume") \__pi_in_valid__assume (\__pi_in_valid );
  miter_def_prop #(1, "assume") \__pi_rst__assume (\__pi_rst );
`endif
`ifndef DIRECT_CROSS_POINTS
`endif
`ifdef CHECK_MATCH_POINTS
  miter_cmp_prop #(64, "assert") \__mp_a_reg__assert (\__mp_a_reg__gold , \__mp_a_reg__gate );
  miter_cmp_prop #(64, "assert") \__mp_b_reg__assert (\__mp_b_reg__gold , \__mp_b_reg__gate );
  miter_cmp_prop #(19, "assert") \__mp_c7__18_0__assert (\__mp_c7__18_0__gold , \__mp_c7__18_0__gate );
  miter_cmp_prop #(16, "assert") \__mp_m0__assert (\__mp_m0__gold , \__mp_m0__gate );
  miter_cmp_prop #(16, "assert") \__mp_m1__assert (\__mp_m1__gold , \__mp_m1__gate );
  miter_cmp_prop #(16, "assert") \__mp_m2__assert (\__mp_m2__gold , \__mp_m2__gate );
  miter_cmp_prop #(16, "assert") \__mp_m3__assert (\__mp_m3__gold , \__mp_m3__gate );
  miter_cmp_prop #(16, "assert") \__mp_m4__assert (\__mp_m4__gold , \__mp_m4__gate );
  miter_cmp_prop #(16, "assert") \__mp_m5__assert (\__mp_m5__gold , \__mp_m5__gate );
  miter_cmp_prop #(16, "assert") \__mp_m6__assert (\__mp_m6__gold , \__mp_m6__gate );
  miter_cmp_prop #(16, "assert") \__mp_m7__assert (\__mp_m7__gold , \__mp_m7__gate );
  miter_cmp_prop #(1, "assert") \__mp_vld__assert (\__mp_vld__gold , \__mp_vld__gate );
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(21, "assert") \__po_acc__assert (\__po_acc__gold , \__po_acc__gate );
  miter_cmp_prop #(1, "assert") \__po_out_valid__assert (\__po_out_valid__gold , \__po_out_valid__gate );
`endif
`ifdef COVER_DEF_CROSS_POINTS
  `ifdef DIRECT_CROSS_POINTS
  `else
  `endif
`endif
`ifdef COVER_DEF_GOLD_MATCH_POINTS
  miter_def_prop #(64, "cover") \__mp_a_reg__gold_cover (\__mp_a_reg__gold );
  miter_def_prop #(64, "cover") \__mp_b_reg__gold_cover (\__mp_b_reg__gold );
  miter_def_prop #(19, "cover") \__mp_c7__18_0__gold_cover (\__mp_c7__18_0__gold );
  miter_def_prop #(16, "cover") \__mp_m0__gold_cover (\__mp_m0__gold );
  miter_def_prop #(16, "cover") \__mp_m1__gold_cover (\__mp_m1__gold );
  miter_def_prop #(16, "cover") \__mp_m2__gold_cover (\__mp_m2__gold );
  miter_def_prop #(16, "cover") \__mp_m3__gold_cover (\__mp_m3__gold );
  miter_def_prop #(16, "cover") \__mp_m4__gold_cover (\__mp_m4__gold );
  miter_def_prop #(16, "cover") \__mp_m5__gold_cover (\__mp_m5__gold );
  miter_def_prop #(16, "cover") \__mp_m6__gold_cover (\__mp_m6__gold );
  miter_def_prop #(16, "cover") \__mp_m7__gold_cover (\__mp_m7__gold );
  miter_def_prop #(1, "cover") \__mp_vld__gold_cover (\__mp_vld__gold );
`endif
`ifdef COVER_DEF_GATE_MATCH_POINTS
  miter_def_prop #(64, "cover") \__mp_a_reg__gate_cover (\__mp_a_reg__gate );
  miter_def_prop #(64, "cover") \__mp_b_reg__gate_cover (\__mp_b_reg__gate );
  miter_def_prop #(19, "cover") \__mp_c7__18_0__gate_cover (\__mp_c7__18_0__gate );
  miter_def_prop #(16, "cover") \__mp_m0__gate_cover (\__mp_m0__gate );
  miter_def_prop #(16, "cover") \__mp_m1__gate_cover (\__mp_m1__gate );
  miter_def_prop #(16, "cover") \__mp_m2__gate_cover (\__mp_m2__gate );
  miter_def_prop #(16, "cover") \__mp_m3__gate_cover (\__mp_m3__gate );
  miter_def_prop #(16, "cover") \__mp_m4__gate_cover (\__mp_m4__gate );
  miter_def_prop #(16, "cover") \__mp_m5__gate_cover (\__mp_m5__gate );
  miter_def_prop #(16, "cover") \__mp_m6__gate_cover (\__mp_m6__gate );
  miter_def_prop #(16, "cover") \__mp_m7__gate_cover (\__mp_m7__gate );
  miter_def_prop #(1, "cover") \__mp_vld__gate_cover (\__mp_vld__gate );
`endif
`ifdef COVER_DEF_GOLD_OUTPUTS
  miter_def_prop #(21, "cover") \__po_acc__gold_cover (\__po_acc__gold );
  miter_def_prop #(1, "cover") \__po_out_valid__gold_cover (\__po_out_valid__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(21, "cover") \__po_acc__gate_cover (\__po_acc__gate );
  miter_def_prop #(1, "cover") \__po_out_valid__gate_cover (\__po_out_valid__gate );
`endif
endmodule
module miter_cmp_prop #(parameter WIDTH=1, parameter TYPE="assert") (input [WIDTH-1:0] in_gold, in_gate);
  reg okay;
  integer i;
  always @* begin
    okay = 1;
    for (i = 0; i < WIDTH; i = i+1)
      okay = okay && (in_gold[i] === 1'bx || in_gold[i] === in_gate[i]);
  end
  generate
    if (TYPE == "assert") always @* assert(okay);
    if (TYPE == "assume") always @* assume(okay);
    if (TYPE == "cover")  always @* cover(okay);
  endgenerate
endmodule
module miter_def_prop #(parameter WIDTH=1, parameter TYPE="assert") (input [WIDTH-1:0] in);
  wire okay = ^in !== 1'bx;
  generate
    if (TYPE == "assert") always @* assert(okay);
    if (TYPE == "assume") always @* assume(okay);
    if (TYPE == "cover")  always @* cover(okay);
  endgenerate
endmodule
module \gold.bm_mac8 (
  input  [ 63:0] \__pi_a_vec ,
  input  [ 63:0] \__pi_b_vec ,
  input  [  0:0] \__pi_clk ,
  input  [  0:0] \__pi_in_valid ,
  input  [  0:0] \__pi_rst ,
  output [ 63:0] \__mp_a_reg ,
  output [ 63:0] \__mp_b_reg ,
  output [ 18:0] \__mp_c7__18_0 ,
  output [ 15:0] \__mp_m0 ,
  output [ 15:0] \__mp_m1 ,
  output [ 15:0] \__mp_m2 ,
  output [ 15:0] \__mp_m3 ,
  output [ 15:0] \__mp_m4 ,
  output [ 15:0] \__mp_m5 ,
  output [ 15:0] \__mp_m6 ,
  output [ 15:0] \__mp_m7 ,
  output [  0:0] \__mp_vld ,
  output [ 20:0] \__po_acc ,
  output [  0:0] \__po_out_valid
);
endmodule
module \gate.bm_mac8 (
  input  [ 63:0] \__pi_a_vec ,
  input  [ 63:0] \__pi_b_vec ,
  input  [  0:0] \__pi_clk ,
  input  [  0:0] \__pi_in_valid ,
  input  [  0:0] \__pi_rst ,
  output [ 63:0] \__mp_a_reg ,
  output [ 63:0] \__mp_b_reg ,
  output [ 18:0] \__mp_c7__18_0 ,
  output [ 15:0] \__mp_m0 ,
  output [ 15:0] \__mp_m1 ,
  output [ 15:0] \__mp_m2 ,
  output [ 15:0] \__mp_m3 ,
  output [ 15:0] \__mp_m4 ,
  output [ 15:0] \__mp_m5 ,
  output [ 15:0] \__mp_m6 ,
  output [ 15:0] \__mp_m7 ,
  output [  0:0] \__mp_vld ,
  output [ 20:0] \__po_acc ,
  output [  0:0] \__po_out_valid
);
endmodule
