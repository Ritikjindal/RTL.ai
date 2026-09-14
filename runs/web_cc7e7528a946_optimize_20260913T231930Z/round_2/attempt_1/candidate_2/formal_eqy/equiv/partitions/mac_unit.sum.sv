module miter (
  input  [ 16:0] \__pi_sum01 ,
  input  [ 16:0] \__pi_sum23 ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [ 17:0] \__po_sum__gold ,
  output [ 17:0] \__po_sum__gate
);
  \gold.mac_unit.sum gold (
    .\__pi_sum01 (\__pi_sum01 ),
    .\__pi_sum23 (\__pi_sum23 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_sum (\__po_sum__gold )
  );
  \gate.mac_unit.sum gate (
    .\__pi_sum01 (\__pi_sum01 ),
    .\__pi_sum23 (\__pi_sum23 ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_sum (\__po_sum__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(17, "assume") \__pi_sum01__assume (\__pi_sum01 );
  miter_def_prop #(17, "assume") \__pi_sum23__assume (\__pi_sum23 );
`endif
`ifndef DIRECT_CROSS_POINTS
`endif
`ifdef CHECK_MATCH_POINTS
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(18, "assert") \__po_sum__assert (\__po_sum__gold , \__po_sum__gate );
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
  miter_def_prop #(18, "cover") \__po_sum__gold_cover (\__po_sum__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(18, "cover") \__po_sum__gate_cover (\__po_sum__gate );
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
module \gold.mac_unit.sum (
  input  [ 16:0] \__pi_sum01 ,
  input  [ 16:0] \__pi_sum23 ,
  output [ 17:0] \__po_sum
);
endmodule
module \gate.mac_unit.sum (
  input  [ 16:0] \__pi_sum01 ,
  input  [ 16:0] \__pi_sum23 ,
  output [ 17:0] \__po_sum
);
endmodule
