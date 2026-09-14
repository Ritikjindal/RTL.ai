module miter (
  input  [  7:0] \__pi_a_reg__23_16 ,
  input  [  7:0] \__pi_b_reg__23_16 ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [ 15:0] \__po_prod2__gold ,
  output [ 15:0] \__po_prod2__gate
);
  \gold.mac_unit.prod2 gold (
    .\__pi_a_reg__23_16 (\__pi_a_reg__23_16 ),
    .\__pi_b_reg__23_16 (\__pi_b_reg__23_16 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_prod2 (\__po_prod2__gold )
  );
  \gate.mac_unit.prod2 gate (
    .\__pi_a_reg__23_16 (\__pi_a_reg__23_16 ),
    .\__pi_b_reg__23_16 (\__pi_b_reg__23_16 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_prod2 (\__po_prod2__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(8, "assume") \__pi_a_reg__23_16__assume (\__pi_a_reg__23_16 );
  miter_def_prop #(8, "assume") \__pi_b_reg__23_16__assume (\__pi_b_reg__23_16 );
`endif
`ifndef DIRECT_CROSS_POINTS
`endif
`ifdef CHECK_MATCH_POINTS
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(16, "assert") \__po_prod2__assert (\__po_prod2__gold , \__po_prod2__gate );
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
  miter_def_prop #(16, "cover") \__po_prod2__gold_cover (\__po_prod2__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(16, "cover") \__po_prod2__gate_cover (\__po_prod2__gate );
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
module \gold.mac_unit.prod2 (
  input  [  7:0] \__pi_a_reg__23_16 ,
  input  [  7:0] \__pi_b_reg__23_16 ,
  output [ 15:0] \__po_prod2
);
endmodule
module \gate.mac_unit.prod2 (
  input  [  7:0] \__pi_a_reg__23_16 ,
  input  [  7:0] \__pi_b_reg__23_16 ,
  output [ 15:0] \__po_prod2
);
endmodule
