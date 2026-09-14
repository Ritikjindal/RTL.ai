module miter (
  input  [  0:0] \__pi_clk ,
  input  [  0:0] \__pi_rst ,
  input  [ 17:0] \__pi_sum ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [ 17:0] \__po_sum_reg__gold ,
  output [ 17:0] \__po_sum_reg__gate
);
  \gold.mac_unit.sum_reg gold (
    .\__pi_clk (\__pi_clk ),
    .\__pi_rst (\__pi_rst ),
    .\__pi_sum (\__pi_sum ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_sum_reg (\__po_sum_reg__gold )
  );
  \gate.mac_unit.sum_reg gate (
    .\__pi_clk (\__pi_clk ),
    .\__pi_rst (\__pi_rst ),
    .\__pi_sum (\__pi_sum ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_sum_reg (\__po_sum_reg__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(1, "assume") \__pi_clk__assume (\__pi_clk );
  miter_def_prop #(1, "assume") \__pi_rst__assume (\__pi_rst );
  miter_def_prop #(18, "assume") \__pi_sum__assume (\__pi_sum );
`endif
`ifndef DIRECT_CROSS_POINTS
`endif
`ifdef CHECK_MATCH_POINTS
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(18, "assert") \__po_sum_reg__assert (\__po_sum_reg__gold , \__po_sum_reg__gate );
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
  miter_def_prop #(18, "cover") \__po_sum_reg__gold_cover (\__po_sum_reg__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(18, "cover") \__po_sum_reg__gate_cover (\__po_sum_reg__gate );
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
module \gold.mac_unit.sum_reg (
  input  [  0:0] \__pi_clk ,
  input  [  0:0] \__pi_rst ,
  input  [ 17:0] \__pi_sum ,
  output [ 17:0] \__po_sum_reg
);
endmodule
module \gate.mac_unit.sum_reg (
  input  [  0:0] \__pi_clk ,
  input  [  0:0] \__pi_rst ,
  input  [ 17:0] \__pi_sum ,
  output [ 17:0] \__po_sum_reg
);
endmodule
