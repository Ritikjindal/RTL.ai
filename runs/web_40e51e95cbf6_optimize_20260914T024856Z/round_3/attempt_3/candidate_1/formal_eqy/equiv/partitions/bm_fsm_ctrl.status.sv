module miter (
  input  [  0:0] \__pi_clk ,
  input  [  0:0] \__pi_rst ,
  input  [  0:0] \__pi_state__0 ,
  input  [  0:0] \__pi_state__8 ,
  input  [  1:0] \__pi_state__15_14 ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [  3:0] \__po_status__gold ,
  output [  3:0] \__po_status__gate
);
  \gold.bm_fsm_ctrl.status gold (
    .\__pi_clk (\__pi_clk ),
    .\__pi_rst (\__pi_rst ),
    .\__pi_state__0 (\__pi_state__0 ),
    .\__pi_state__8 (\__pi_state__8 ),
    .\__pi_state__15_14 (\__pi_state__15_14 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_status (\__po_status__gold )
  );
  \gate.bm_fsm_ctrl.status gate (
    .\__pi_clk (\__pi_clk ),
    .\__pi_rst (\__pi_rst ),
    .\__pi_state__0 (\__pi_state__0 ),
    .\__pi_state__8 (\__pi_state__8 ),
    .\__pi_state__15_14 (\__pi_state__15_14 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_status (\__po_status__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(1, "assume") \__pi_clk__assume (\__pi_clk );
  miter_def_prop #(1, "assume") \__pi_rst__assume (\__pi_rst );
  miter_def_prop #(1, "assume") \__pi_state__0__assume (\__pi_state__0 );
  miter_def_prop #(1, "assume") \__pi_state__8__assume (\__pi_state__8 );
  miter_def_prop #(2, "assume") \__pi_state__15_14__assume (\__pi_state__15_14 );
`endif
`ifndef DIRECT_CROSS_POINTS
`endif
`ifdef CHECK_MATCH_POINTS
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(4, "assert") \__po_status__assert (\__po_status__gold , \__po_status__gate );
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
  miter_def_prop #(4, "cover") \__po_status__gold_cover (\__po_status__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(4, "cover") \__po_status__gate_cover (\__po_status__gate );
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
module \gold.bm_fsm_ctrl.status (
  input  [  0:0] \__pi_clk ,
  input  [  0:0] \__pi_rst ,
  input  [  0:0] \__pi_state__0 ,
  input  [  0:0] \__pi_state__8 ,
  input  [  1:0] \__pi_state__15_14 ,
  output [  3:0] \__po_status
);
endmodule
module \gate.bm_fsm_ctrl.status (
  input  [  0:0] \__pi_clk ,
  input  [  0:0] \__pi_rst ,
  input  [  0:0] \__pi_state__0 ,
  input  [  0:0] \__pi_state__8 ,
  input  [  1:0] \__pi_state__15_14 ,
  output [  3:0] \__po_status
);
endmodule
