module miter (
  input  [  0:0] \__pi_in_data__5 ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [  0:0] \__po_ext__5__gold ,
  output [  0:0] \__po_ext__5__gate
);
  \gold.bm_fsm_ctrl.ext.5 gold (
    .\__pi_in_data__5 (\__pi_in_data__5 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_ext__5 (\__po_ext__5__gold )
  );
  \gate.bm_fsm_ctrl.ext.5 gate (
    .\__pi_in_data__5 (\__pi_in_data__5 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_ext__5 (\__po_ext__5__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(1, "assume") \__pi_in_data__5__assume (\__pi_in_data__5 );
`endif
`ifndef DIRECT_CROSS_POINTS
`endif
`ifdef CHECK_MATCH_POINTS
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(1, "assert") \__po_ext__5__assert (\__po_ext__5__gold , \__po_ext__5__gate );
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
  miter_def_prop #(1, "cover") \__po_ext__5__gold_cover (\__po_ext__5__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(1, "cover") \__po_ext__5__gate_cover (\__po_ext__5__gate );
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
module \gold.bm_fsm_ctrl.ext.5 (
  input  [  0:0] \__pi_in_data__5 ,
  output [  0:0] \__po_ext__5
);
endmodule
module \gate.bm_fsm_ctrl.ext.5 (
  input  [  0:0] \__pi_in_data__5 ,
  output [  0:0] \__po_ext__5
);
endmodule
