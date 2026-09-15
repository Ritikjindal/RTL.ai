module miter (
  input  [  0:0] \__pi_clk ,
  input  [  7:0] \__pi_in_data ,
  input  [  0:0] \__pi_in_valid ,
  input  [  0:0] \__pi_rst ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [  7:0] \__po_t0__gold ,
  output [  7:0] \__po_t0__gate
);
  \gold.bm_fir6.t0 gold (
    .\__pi_clk (\__pi_clk ),
    .\__pi_in_data (\__pi_in_data ),
    .\__pi_in_valid (\__pi_in_valid ),
    .\__pi_rst (\__pi_rst ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_t0 (\__po_t0__gold )
  );
  \gate.bm_fir6.t0 gate (
    .\__pi_clk (\__pi_clk ),
    .\__pi_in_data (\__pi_in_data ),
    .\__pi_in_valid (\__pi_in_valid ),
    .\__pi_rst (\__pi_rst ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_t0 (\__po_t0__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(1, "assume") \__pi_clk__assume (\__pi_clk );
  miter_def_prop #(8, "assume") \__pi_in_data__assume (\__pi_in_data );
  miter_def_prop #(1, "assume") \__pi_in_valid__assume (\__pi_in_valid );
  miter_def_prop #(1, "assume") \__pi_rst__assume (\__pi_rst );
`endif
`ifndef DIRECT_CROSS_POINTS
`endif
`ifdef CHECK_MATCH_POINTS
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(8, "assert") \__po_t0__assert (\__po_t0__gold , \__po_t0__gate );
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
  miter_def_prop #(8, "cover") \__po_t0__gold_cover (\__po_t0__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(8, "cover") \__po_t0__gate_cover (\__po_t0__gate );
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
module \gold.bm_fir6.t0 (
  input  [  0:0] \__pi_clk ,
  input  [  7:0] \__pi_in_data ,
  input  [  0:0] \__pi_in_valid ,
  input  [  0:0] \__pi_rst ,
  output [  7:0] \__po_t0
);
endmodule
module \gate.bm_fir6.t0 (
  input  [  0:0] \__pi_clk ,
  input  [  7:0] \__pi_in_data ,
  input  [  0:0] \__pi_in_valid ,
  input  [  0:0] \__pi_rst ,
  output [  7:0] \__po_t0
);
endmodule
