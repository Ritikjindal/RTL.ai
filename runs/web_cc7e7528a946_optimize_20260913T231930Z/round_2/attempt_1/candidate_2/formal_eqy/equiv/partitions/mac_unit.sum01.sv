module miter (
  input  [ 15:0] \__pi_prod0 ,
  input  [ 15:0] \__pi_prod1 ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [ 16:0] \__po_sum01__gold ,
  output [ 16:0] \__po_sum01__gate
);
  \gold.mac_unit.sum01 gold (
    .\__pi_prod0 (\__pi_prod0 ),
    .\__pi_prod1 (\__pi_prod1 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_sum01 (\__po_sum01__gold )
  );
  \gate.mac_unit.sum01 gate (
    .\__pi_prod0 (\__pi_prod0 ),
    .\__pi_prod1 (\__pi_prod1 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_sum01 (\__po_sum01__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(16, "assume") \__pi_prod0__assume (\__pi_prod0 );
  miter_def_prop #(16, "assume") \__pi_prod1__assume (\__pi_prod1 );
`endif
`ifndef DIRECT_CROSS_POINTS
`endif
`ifdef CHECK_MATCH_POINTS
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(17, "assert") \__po_sum01__assert (\__po_sum01__gold , \__po_sum01__gate );
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
  miter_def_prop #(17, "cover") \__po_sum01__gold_cover (\__po_sum01__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(17, "cover") \__po_sum01__gate_cover (\__po_sum01__gate );
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
module \gold.mac_unit.sum01 (
  input  [ 15:0] \__pi_prod0 ,
  input  [ 15:0] \__pi_prod1 ,
  output [ 16:0] \__po_sum01
);
endmodule
module \gate.mac_unit.sum01 (
  input  [ 15:0] \__pi_prod0 ,
  input  [ 15:0] \__pi_prod1 ,
  output [ 16:0] \__po_sum01
);
endmodule
