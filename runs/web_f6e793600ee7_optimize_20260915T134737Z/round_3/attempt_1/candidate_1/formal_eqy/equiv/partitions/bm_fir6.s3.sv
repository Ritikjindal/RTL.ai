module miter (
  input  [ 14:0] \__pi_p3__14_0 ,
  input  [  0:0] \__pi_p3__18 ,
  input  [ 13:0] \__pi_p4__13_0 ,
  input  [  0:0] \__pi_p4__18 ,
  input  [ 12:0] \__pi_p5__12_0 ,
  input  [  0:0] \__pi_p5__18 ,
  input  [ 15:0] \__pi_s2__15_0 ,
  input  [  0:0] \__pi_s2__18 ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [ 17:0] \__po_s3__17_0__gold ,
  output [ 17:0] \__po_s3__17_0__gate
);
  \gold.bm_fir6.s3 gold (
    .\__pi_p3__14_0 (\__pi_p3__14_0 ),
    .\__pi_p3__18 (\__pi_p3__18 ),
    .\__pi_p4__13_0 (\__pi_p4__13_0 ),
    .\__pi_p4__18 (\__pi_p4__18 ),
    .\__pi_p5__12_0 (\__pi_p5__12_0 ),
    .\__pi_p5__18 (\__pi_p5__18 ),
    .\__pi_s2__15_0 (\__pi_s2__15_0 ),
    .\__pi_s2__18 (\__pi_s2__18 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_s3__17_0 (\__po_s3__17_0__gold )
  );
  \gate.bm_fir6.s3 gate (
    .\__pi_p3__14_0 (\__pi_p3__14_0 ),
    .\__pi_p3__18 (\__pi_p3__18 ),
    .\__pi_p4__13_0 (\__pi_p4__13_0 ),
    .\__pi_p4__18 (\__pi_p4__18 ),
    .\__pi_p5__12_0 (\__pi_p5__12_0 ),
    .\__pi_p5__18 (\__pi_p5__18 ),
    .\__pi_s2__15_0 (\__pi_s2__15_0 ),
    .\__pi_s2__18 (\__pi_s2__18 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_s3__17_0 (\__po_s3__17_0__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(15, "assume") \__pi_p3__14_0__assume (\__pi_p3__14_0 );
  miter_def_prop #(1, "assume") \__pi_p3__18__assume (\__pi_p3__18 );
  miter_def_prop #(14, "assume") \__pi_p4__13_0__assume (\__pi_p4__13_0 );
  miter_def_prop #(1, "assume") \__pi_p4__18__assume (\__pi_p4__18 );
  miter_def_prop #(13, "assume") \__pi_p5__12_0__assume (\__pi_p5__12_0 );
  miter_def_prop #(1, "assume") \__pi_p5__18__assume (\__pi_p5__18 );
  miter_def_prop #(16, "assume") \__pi_s2__15_0__assume (\__pi_s2__15_0 );
  miter_def_prop #(1, "assume") \__pi_s2__18__assume (\__pi_s2__18 );
`endif
`ifndef DIRECT_CROSS_POINTS
`endif
`ifdef CHECK_MATCH_POINTS
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(18, "assert") \__po_s3__17_0__assert (\__po_s3__17_0__gold , \__po_s3__17_0__gate );
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
  miter_def_prop #(18, "cover") \__po_s3__17_0__gold_cover (\__po_s3__17_0__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(18, "cover") \__po_s3__17_0__gate_cover (\__po_s3__17_0__gate );
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
module \gold.bm_fir6.s3 (
  input  [ 14:0] \__pi_p3__14_0 ,
  input  [  0:0] \__pi_p3__18 ,
  input  [ 13:0] \__pi_p4__13_0 ,
  input  [  0:0] \__pi_p4__18 ,
  input  [ 12:0] \__pi_p5__12_0 ,
  input  [  0:0] \__pi_p5__18 ,
  input  [ 15:0] \__pi_s2__15_0 ,
  input  [  0:0] \__pi_s2__18 ,
  output [ 17:0] \__po_s3__17_0
);
endmodule
module \gate.bm_fir6.s3 (
  input  [ 14:0] \__pi_p3__14_0 ,
  input  [  0:0] \__pi_p3__18 ,
  input  [ 13:0] \__pi_p4__13_0 ,
  input  [  0:0] \__pi_p4__18 ,
  input  [ 12:0] \__pi_p5__12_0 ,
  input  [  0:0] \__pi_p5__18 ,
  input  [ 15:0] \__pi_s2__15_0 ,
  input  [  0:0] \__pi_s2__18 ,
  output [ 17:0] \__po_s3__17_0
);
endmodule
