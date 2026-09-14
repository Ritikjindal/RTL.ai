module miter (
  input  [  0:0] \__pi_clk ,
  input  [ 15:0] \__pi_m0 ,
  input  [ 15:0] \__pi_m1 ,
  input  [ 15:0] \__pi_m2 ,
  input  [ 15:0] \__pi_m3 ,
  input  [ 15:0] \__pi_m4 ,
  input  [ 15:0] \__pi_m5 ,
  input  [ 15:0] \__pi_m6 ,
  input  [ 15:0] \__pi_m7 ,
  input  [  0:0] \__pi_rst ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [ 20:0] \__po_acc__gold ,
  output [ 18:0] \__po_c7__18_0__gold ,
  output [ 20:0] \__po_acc__gate ,
  output [ 18:0] \__po_c7__18_0__gate
);
  \gold.bm_mac8.acc gold (
    .\__pi_clk (\__pi_clk ),
    .\__pi_m0 (\__pi_m0 ),
    .\__pi_m1 (\__pi_m1 ),
    .\__pi_m2 (\__pi_m2 ),
    .\__pi_m3 (\__pi_m3 ),
    .\__pi_m4 (\__pi_m4 ),
    .\__pi_m5 (\__pi_m5 ),
    .\__pi_m6 (\__pi_m6 ),
    .\__pi_m7 (\__pi_m7 ),
    .\__pi_rst (\__pi_rst ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_acc (\__po_acc__gold ),
    .\__po_c7__18_0 (\__po_c7__18_0__gold )
  );
  \gate.bm_mac8.acc gate (
    .\__pi_clk (\__pi_clk ),
    .\__pi_m0 (\__pi_m0 ),
    .\__pi_m1 (\__pi_m1 ),
    .\__pi_m2 (\__pi_m2 ),
    .\__pi_m3 (\__pi_m3 ),
    .\__pi_m4 (\__pi_m4 ),
    .\__pi_m5 (\__pi_m5 ),
    .\__pi_m6 (\__pi_m6 ),
    .\__pi_m7 (\__pi_m7 ),
    .\__pi_rst (\__pi_rst ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_acc (\__po_acc__gate ),
    .\__po_c7__18_0 (\__po_c7__18_0__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(1, "assume") \__pi_clk__assume (\__pi_clk );
  miter_def_prop #(16, "assume") \__pi_m0__assume (\__pi_m0 );
  miter_def_prop #(16, "assume") \__pi_m1__assume (\__pi_m1 );
  miter_def_prop #(16, "assume") \__pi_m2__assume (\__pi_m2 );
  miter_def_prop #(16, "assume") \__pi_m3__assume (\__pi_m3 );
  miter_def_prop #(16, "assume") \__pi_m4__assume (\__pi_m4 );
  miter_def_prop #(16, "assume") \__pi_m5__assume (\__pi_m5 );
  miter_def_prop #(16, "assume") \__pi_m6__assume (\__pi_m6 );
  miter_def_prop #(16, "assume") \__pi_m7__assume (\__pi_m7 );
  miter_def_prop #(1, "assume") \__pi_rst__assume (\__pi_rst );
`endif
`ifndef DIRECT_CROSS_POINTS
`endif
`ifdef CHECK_MATCH_POINTS
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(21, "assert") \__po_acc__assert (\__po_acc__gold , \__po_acc__gate );
  miter_cmp_prop #(19, "assert") \__po_c7__18_0__assert (\__po_c7__18_0__gold , \__po_c7__18_0__gate );
`endif
`ifdef COVER_DEF_CROSS_POINTS
  `ifdef DIRECT_CROSS_POINTS
  `else
  `endif
`endif
`ifdef COVER_DEF_GOLD_MATCH_POINTS
`endif
`ifdef COVER_DEF_GATE_MATCH_POINTS
`endif
`ifdef COVER_DEF_GOLD_OUTPUTS
  miter_def_prop #(21, "cover") \__po_acc__gold_cover (\__po_acc__gold );
  miter_def_prop #(19, "cover") \__po_c7__18_0__gold_cover (\__po_c7__18_0__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(21, "cover") \__po_acc__gate_cover (\__po_acc__gate );
  miter_def_prop #(19, "cover") \__po_c7__18_0__gate_cover (\__po_c7__18_0__gate );
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
module \gold.bm_mac8.acc (
  input  [  0:0] \__pi_clk ,
  input  [ 15:0] \__pi_m0 ,
  input  [ 15:0] \__pi_m1 ,
  input  [ 15:0] \__pi_m2 ,
  input  [ 15:0] \__pi_m3 ,
  input  [ 15:0] \__pi_m4 ,
  input  [ 15:0] \__pi_m5 ,
  input  [ 15:0] \__pi_m6 ,
  input  [ 15:0] \__pi_m7 ,
  input  [  0:0] \__pi_rst ,
  output [ 20:0] \__po_acc ,
  output [ 18:0] \__po_c7__18_0
);
endmodule
module \gate.bm_mac8.acc (
  input  [  0:0] \__pi_clk ,
  input  [ 15:0] \__pi_m0 ,
  input  [ 15:0] \__pi_m1 ,
  input  [ 15:0] \__pi_m2 ,
  input  [ 15:0] \__pi_m3 ,
  input  [ 15:0] \__pi_m4 ,
  input  [ 15:0] \__pi_m5 ,
  input  [ 15:0] \__pi_m6 ,
  input  [ 15:0] \__pi_m7 ,
  input  [  0:0] \__pi_rst ,
  output [ 20:0] \__po_acc ,
  output [ 18:0] \__po_c7__18_0
);
endmodule
