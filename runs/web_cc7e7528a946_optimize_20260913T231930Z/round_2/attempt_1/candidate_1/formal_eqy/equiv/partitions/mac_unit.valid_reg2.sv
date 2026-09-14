module miter (
  input  [  0:0] \__pi_clk ,
  input  [  0:0] \__pi_rst ,
  input  [  0:0] \__pi_valid_reg ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [  0:0] \__po_valid_reg2__gold ,
  output [  0:0] \__po_valid_reg2__gate
);
  \gold.mac_unit.valid_reg2 gold (
    .\__pi_clk (\__pi_clk ),
    .\__pi_rst (\__pi_rst ),
    .\__pi_valid_reg (\__pi_valid_reg ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_valid_reg2 (\__po_valid_reg2__gold )
  );
  \gate.mac_unit.valid_reg2 gate (
    .\__pi_clk (\__pi_clk ),
    .\__pi_rst (\__pi_rst ),
    .\__pi_valid_reg (\__pi_valid_reg ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_valid_reg2 (\__po_valid_reg2__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(1, "assume") \__pi_clk__assume (\__pi_clk );
  miter_def_prop #(1, "assume") \__pi_rst__assume (\__pi_rst );
  miter_def_prop #(1, "assume") \__pi_valid_reg__assume (\__pi_valid_reg );
`endif
`ifndef DIRECT_CROSS_POINTS
`endif
`ifdef CHECK_MATCH_POINTS
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(1, "assert") \__po_valid_reg2__assert (\__po_valid_reg2__gold , \__po_valid_reg2__gate );
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
  miter_def_prop #(1, "cover") \__po_valid_reg2__gold_cover (\__po_valid_reg2__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(1, "cover") \__po_valid_reg2__gate_cover (\__po_valid_reg2__gate );
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
module \gold.mac_unit.valid_reg2 (
  input  [  0:0] \__pi_clk ,
  input  [  0:0] \__pi_rst ,
  input  [  0:0] \__pi_valid_reg ,
  output [  0:0] \__po_valid_reg2
);
endmodule
module \gate.mac_unit.valid_reg2 (
  input  [  0:0] \__pi_clk ,
  input  [  0:0] \__pi_rst ,
  input  [  0:0] \__pi_valid_reg ,
  output [  0:0] \__po_valid_reg2
);
endmodule
