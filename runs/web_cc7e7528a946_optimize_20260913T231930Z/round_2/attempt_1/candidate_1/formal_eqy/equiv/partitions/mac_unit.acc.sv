module miter (
  input  [  0:0] \__pi_clk ,
  input  [  0:0] \__pi_rst ,
  input  [ 17:0] \__pi_sum_reg ,
  input  [  0:0] \__pi_valid_reg2 ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [ 23:0] \__po_acc__gold ,
  output [ 23:0] \__po_acc__gate
);
  \gold.mac_unit.acc gold (
    .\__pi_clk (\__pi_clk ),
    .\__pi_rst (\__pi_rst ),
    .\__pi_sum_reg (\__pi_sum_reg ),
    .\__pi_valid_reg2 (\__pi_valid_reg2 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_acc (\__po_acc__gold )
  );
  \gate.mac_unit.acc gate (
    .\__pi_clk (\__pi_clk ),
    .\__pi_rst (\__pi_rst ),
    .\__pi_sum_reg (\__pi_sum_reg ),
    .\__pi_valid_reg2 (\__pi_valid_reg2 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_acc (\__po_acc__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(1, "assume") \__pi_clk__assume (\__pi_clk );
  miter_def_prop #(1, "assume") \__pi_rst__assume (\__pi_rst );
  miter_def_prop #(18, "assume") \__pi_sum_reg__assume (\__pi_sum_reg );
  miter_def_prop #(1, "assume") \__pi_valid_reg2__assume (\__pi_valid_reg2 );
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
module \gold.mac_unit.acc (
  input  [  0:0] \__pi_clk ,
  input  [  0:0] \__pi_rst ,
  input  [ 17:0] \__pi_sum_reg ,
  input  [  0:0] \__pi_valid_reg2 ,
  output [ 23:0] \__po_acc
);
endmodule
module \gate.mac_unit.acc (
  input  [  0:0] \__pi_clk ,
  input  [  0:0] \__pi_rst ,
  input  [ 17:0] \__pi_sum_reg ,
  input  [  0:0] \__pi_valid_reg2 ,
  output [ 23:0] \__po_acc
);
endmodule
