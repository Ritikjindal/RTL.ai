module miter (
  input  [  7:0] \__pi_a_reg__47_40 ,
  input  [  7:0] \__pi_b_reg__47_40 ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [ 15:0] \__po_m5__gold ,
  output [ 15:0] \__po_m5__gate
);
  \gold.bm_mac8.m5 gold (
    .\__pi_a_reg__47_40 (\__pi_a_reg__47_40 ),
    .\__pi_b_reg__47_40 (\__pi_b_reg__47_40 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_m5 (\__po_m5__gold )
  );
  \gate.bm_mac8.m5 gate (
    .\__pi_a_reg__47_40 (\__pi_a_reg__47_40 ),
    .\__pi_b_reg__47_40 (\__pi_b_reg__47_40 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_m5 (\__po_m5__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(8, "assume") \__pi_a_reg__47_40__assume (\__pi_a_reg__47_40 );
  miter_def_prop #(8, "assume") \__pi_b_reg__47_40__assume (\__pi_b_reg__47_40 );
`endif
`ifndef DIRECT_CROSS_POINTS
`endif
`ifdef CHECK_MATCH_POINTS
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(16, "assert") \__po_m5__assert (\__po_m5__gold , \__po_m5__gate );
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
  miter_def_prop #(16, "cover") \__po_m5__gold_cover (\__po_m5__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(16, "cover") \__po_m5__gate_cover (\__po_m5__gate );
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
module \gold.bm_mac8.m5 (
  input  [  7:0] \__pi_a_reg__47_40 ,
  input  [  7:0] \__pi_b_reg__47_40 ,
  output [ 15:0] \__po_m5
);
endmodule
module \gate.bm_mac8.m5 (
  input  [  7:0] \__pi_a_reg__47_40 ,
  input  [  7:0] \__pi_b_reg__47_40 ,
  output [ 15:0] \__po_m5
);
endmodule
