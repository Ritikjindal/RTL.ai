module miter (
  input  [ 23:0] \__pi_acc ,
  input  [ 15:0] \__pi_ext__15_0 ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [ 23:0] \__po_d0__gold ,
  output [ 23:0] \__po_d0__gate
);
  \gold.bm_fsm_ctrl.d0 gold (
    .\__pi_acc (\__pi_acc ),
    .\__pi_ext__15_0 (\__pi_ext__15_0 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_d0 (\__po_d0__gold )
  );
  \gate.bm_fsm_ctrl.d0 gate (
    .\__pi_acc (\__pi_acc ),
    .\__pi_ext__15_0 (\__pi_ext__15_0 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_d0 (\__po_d0__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(24, "assume") \__pi_acc__assume (\__pi_acc );
  miter_def_prop #(16, "assume") \__pi_ext__15_0__assume (\__pi_ext__15_0 );
`endif
`ifndef DIRECT_CROSS_POINTS
`endif
`ifdef CHECK_MATCH_POINTS
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(24, "assert") \__po_d0__assert (\__po_d0__gold , \__po_d0__gate );
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
  miter_def_prop #(24, "cover") \__po_d0__gold_cover (\__po_d0__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(24, "cover") \__po_d0__gate_cover (\__po_d0__gate );
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
module \gold.bm_fsm_ctrl.d0 (
  input  [ 23:0] \__pi_acc ,
  input  [ 15:0] \__pi_ext__15_0 ,
  output [ 23:0] \__po_d0
);
endmodule
module \gate.bm_fsm_ctrl.d0 (
  input  [ 23:0] \__pi_acc ,
  input  [ 15:0] \__pi_ext__15_0 ,
  output [ 23:0] \__po_d0
);
endmodule
