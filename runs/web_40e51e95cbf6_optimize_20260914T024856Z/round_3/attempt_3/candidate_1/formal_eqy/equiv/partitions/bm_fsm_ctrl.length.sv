module miter (
  input  [  0:0] \__pi_clk ,
  input  [ 15:0] \__pi_ext__15_0 ,
  input  [  0:0] \__pi_in_valid ,
  input  [ 15:0] \__pi_lenx__15_0 ,
  input  [  0:0] \__pi_rst ,
  input  [  0:0] \__pi_state__7 ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [ 15:0] \__po_length__gold ,
  output [ 15:0] \__po_length__gate
);
  \gold.bm_fsm_ctrl.length gold (
    .\__pi_clk (\__pi_clk ),
    .\__pi_ext__15_0 (\__pi_ext__15_0 ),
    .\__pi_in_valid (\__pi_in_valid ),
    .\__pi_lenx__15_0 (\__pi_lenx__15_0 ),
    .\__pi_rst (\__pi_rst ),
    .\__pi_state__7 (\__pi_state__7 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_length (\__po_length__gold )
  );
  \gate.bm_fsm_ctrl.length gate (
    .\__pi_clk (\__pi_clk ),
    .\__pi_ext__15_0 (\__pi_ext__15_0 ),
    .\__pi_in_valid (\__pi_in_valid ),
    .\__pi_lenx__15_0 (\__pi_lenx__15_0 ),
    .\__pi_rst (\__pi_rst ),
    .\__pi_state__7 (\__pi_state__7 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_length (\__po_length__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(1, "assume") \__pi_clk__assume (\__pi_clk );
  miter_def_prop #(16, "assume") \__pi_ext__15_0__assume (\__pi_ext__15_0 );
  miter_def_prop #(1, "assume") \__pi_in_valid__assume (\__pi_in_valid );
  miter_def_prop #(16, "assume") \__pi_lenx__15_0__assume (\__pi_lenx__15_0 );
  miter_def_prop #(1, "assume") \__pi_rst__assume (\__pi_rst );
  miter_def_prop #(1, "assume") \__pi_state__7__assume (\__pi_state__7 );
`endif
`ifndef DIRECT_CROSS_POINTS
`endif
`ifdef CHECK_MATCH_POINTS
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(16, "assert") \__po_length__assert (\__po_length__gold , \__po_length__gate );
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
  miter_def_prop #(16, "cover") \__po_length__gold_cover (\__po_length__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(16, "cover") \__po_length__gate_cover (\__po_length__gate );
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
module \gold.bm_fsm_ctrl.length (
  input  [  0:0] \__pi_clk ,
  input  [ 15:0] \__pi_ext__15_0 ,
  input  [  0:0] \__pi_in_valid ,
  input  [ 15:0] \__pi_lenx__15_0 ,
  input  [  0:0] \__pi_rst ,
  input  [  0:0] \__pi_state__7 ,
  output [ 15:0] \__po_length
);
endmodule
module \gate.bm_fsm_ctrl.length (
  input  [  0:0] \__pi_clk ,
  input  [ 15:0] \__pi_ext__15_0 ,
  input  [  0:0] \__pi_in_valid ,
  input  [ 15:0] \__pi_lenx__15_0 ,
  input  [  0:0] \__pi_rst ,
  input  [  0:0] \__pi_state__7 ,
  output [ 15:0] \__po_length
);
endmodule
