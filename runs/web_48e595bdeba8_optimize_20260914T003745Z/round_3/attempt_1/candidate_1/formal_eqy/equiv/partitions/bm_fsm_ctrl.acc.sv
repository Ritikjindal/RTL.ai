module miter (
  input  [  0:0] \__pi_clk ,
  input  [ 23:0] \__pi_d9 ,
  input  [  0:0] \__pi_in_valid ,
  input  [  0:0] \__pi_rst ,
  input  [  0:0] \__pi_state__12 ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [ 23:0] \__po_acc__gold ,
  output [ 23:0] \__po_acc__gate
);
  \gold.bm_fsm_ctrl.acc gold (
    .\__pi_clk (\__pi_clk ),
    .\__pi_d9 (\__pi_d9 ),
    .\__pi_in_valid (\__pi_in_valid ),
    .\__pi_rst (\__pi_rst ),
    .\__pi_state__12 (\__pi_state__12 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_acc (\__po_acc__gold )
  );
  \gate.bm_fsm_ctrl.acc gate (
    .\__pi_clk (\__pi_clk ),
    .\__pi_d9 (\__pi_d9 ),
    .\__pi_in_valid (\__pi_in_valid ),
    .\__pi_rst (\__pi_rst ),
    .\__pi_state__12 (\__pi_state__12 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_acc (\__po_acc__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(1, "assume") \__pi_clk__assume (\__pi_clk );
  miter_def_prop #(24, "assume") \__pi_d9__assume (\__pi_d9 );
  miter_def_prop #(1, "assume") \__pi_in_valid__assume (\__pi_in_valid );
  miter_def_prop #(1, "assume") \__pi_rst__assume (\__pi_rst );
  miter_def_prop #(1, "assume") \__pi_state__12__assume (\__pi_state__12 );
`endif
`ifndef DIRECT_CROSS_POINTS
`endif
`ifdef CHECK_MATCH_POINTS
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(24, "assert") \__po_acc__assert (\__po_acc__gold , \__po_acc__gate );
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
  miter_def_prop #(24, "cover") \__po_acc__gold_cover (\__po_acc__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(24, "cover") \__po_acc__gate_cover (\__po_acc__gate );
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
module \gold.bm_fsm_ctrl.acc (
  input  [  0:0] \__pi_clk ,
  input  [ 23:0] \__pi_d9 ,
  input  [  0:0] \__pi_in_valid ,
  input  [  0:0] \__pi_rst ,
  input  [  0:0] \__pi_state__12 ,
  output [ 23:0] \__po_acc
);
endmodule
module \gate.bm_fsm_ctrl.acc (
  input  [  0:0] \__pi_clk ,
  input  [ 23:0] \__pi_d9 ,
  input  [  0:0] \__pi_in_valid ,
  input  [  0:0] \__pi_rst ,
  input  [  0:0] \__pi_state__12 ,
  output [ 23:0] \__po_acc
);
endmodule
