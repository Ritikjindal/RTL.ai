module miter (
  input  [  0:0] \__pi_clk ,
  input  [  7:0] \__pi_in_data ,
  input  [  0:0] \__pi_in_valid ,
  input  [  0:0] \__pi_rst ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [ 18:0] \__mp_p0__gold ,
  output [ 18:0] \__mp_p1__gold ,
  output [ 18:0] \__mp_p2__gold ,
  output [ 18:0] \__mp_p3__gold ,
  output [ 18:0] \__mp_p4__gold ,
  output [ 18:0] \__mp_p5__gold ,
  output [ 18:0] \__mp_s1__gold ,
  output [ 18:0] \__mp_s2__gold ,
  output [ 18:0] \__mp_s3__gold ,
  output [ 18:0] \__mp_s4__gold ,
  output [ 18:0] \__mp_s5__gold ,
  output [  7:0] \__mp_t0__gold ,
  output [  7:0] \__mp_t1__gold ,
  output [  7:0] \__mp_t2__gold ,
  output [  7:0] \__mp_t3__gold ,
  output [  7:0] \__mp_t4__gold ,
  output [  7:0] \__mp_t5__gold ,
  output [  0:0] \__mp_vld__gold ,
  output [ 18:0] \__mp_p0__gate ,
  output [ 18:0] \__mp_p1__gate ,
  output [ 18:0] \__mp_p2__gate ,
  output [ 18:0] \__mp_p3__gate ,
  output [ 18:0] \__mp_p4__gate ,
  output [ 18:0] \__mp_p5__gate ,
  output [ 18:0] \__mp_s1__gate ,
  output [ 18:0] \__mp_s2__gate ,
  output [ 18:0] \__mp_s3__gate ,
  output [ 18:0] \__mp_s4__gate ,
  output [ 18:0] \__mp_s5__gate ,
  output [  7:0] \__mp_t0__gate ,
  output [  7:0] \__mp_t1__gate ,
  output [  7:0] \__mp_t2__gate ,
  output [  7:0] \__mp_t3__gate ,
  output [  7:0] \__mp_t4__gate ,
  output [  7:0] \__mp_t5__gate ,
  output [  0:0] \__mp_vld__gate ,
  output [ 18:0] \__po_out_data__gold ,
  output [  0:0] \__po_out_valid__gold ,
  output [ 18:0] \__po_out_data__gate ,
  output [  0:0] \__po_out_valid__gate
);
  \gold.bm_fir6 gold (
    .\__pi_clk (\__pi_clk ),
    .\__pi_in_data (\__pi_in_data ),
    .\__pi_in_valid (\__pi_in_valid ),
    .\__pi_rst (\__pi_rst ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__mp_p0 (\__mp_p0__gold ),
    .\__mp_p1 (\__mp_p1__gold ),
    .\__mp_p2 (\__mp_p2__gold ),
    .\__mp_p3 (\__mp_p3__gold ),
    .\__mp_p4 (\__mp_p4__gold ),
    .\__mp_p5 (\__mp_p5__gold ),
    .\__mp_s1 (\__mp_s1__gold ),
    .\__mp_s2 (\__mp_s2__gold ),
    .\__mp_s3 (\__mp_s3__gold ),
    .\__mp_s4 (\__mp_s4__gold ),
    .\__mp_s5 (\__mp_s5__gold ),
    .\__mp_t0 (\__mp_t0__gold ),
    .\__mp_t1 (\__mp_t1__gold ),
    .\__mp_t2 (\__mp_t2__gold ),
    .\__mp_t3 (\__mp_t3__gold ),
    .\__mp_t4 (\__mp_t4__gold ),
    .\__mp_t5 (\__mp_t5__gold ),
    .\__mp_vld (\__mp_vld__gold ),
    .\__po_out_data (\__po_out_data__gold ),
    .\__po_out_valid (\__po_out_valid__gold )
  );
  \gate.bm_fir6 gate (
    .\__pi_clk (\__pi_clk ),
    .\__pi_in_data (\__pi_in_data ),
    .\__pi_in_valid (\__pi_in_valid ),
    .\__pi_rst (\__pi_rst ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__mp_p0 (\__mp_p0__gate ),
    .\__mp_p1 (\__mp_p1__gate ),
    .\__mp_p2 (\__mp_p2__gate ),
    .\__mp_p3 (\__mp_p3__gate ),
    .\__mp_p4 (\__mp_p4__gate ),
    .\__mp_p5 (\__mp_p5__gate ),
    .\__mp_s1 (\__mp_s1__gate ),
    .\__mp_s2 (\__mp_s2__gate ),
    .\__mp_s3 (\__mp_s3__gate ),
    .\__mp_s4 (\__mp_s4__gate ),
    .\__mp_s5 (\__mp_s5__gate ),
    .\__mp_t0 (\__mp_t0__gate ),
    .\__mp_t1 (\__mp_t1__gate ),
    .\__mp_t2 (\__mp_t2__gate ),
    .\__mp_t3 (\__mp_t3__gate ),
    .\__mp_t4 (\__mp_t4__gate ),
    .\__mp_t5 (\__mp_t5__gate ),
    .\__mp_vld (\__mp_vld__gate ),
    .\__po_out_data (\__po_out_data__gate ),
    .\__po_out_valid (\__po_out_valid__gate )
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
  miter_cmp_prop #(19, "assert") \__mp_p0__assert (\__mp_p0__gold , \__mp_p0__gate );
  miter_cmp_prop #(19, "assert") \__mp_p1__assert (\__mp_p1__gold , \__mp_p1__gate );
  miter_cmp_prop #(19, "assert") \__mp_p2__assert (\__mp_p2__gold , \__mp_p2__gate );
  miter_cmp_prop #(19, "assert") \__mp_p3__assert (\__mp_p3__gold , \__mp_p3__gate );
  miter_cmp_prop #(19, "assert") \__mp_p4__assert (\__mp_p4__gold , \__mp_p4__gate );
  miter_cmp_prop #(19, "assert") \__mp_p5__assert (\__mp_p5__gold , \__mp_p5__gate );
  miter_cmp_prop #(19, "assert") \__mp_s1__assert (\__mp_s1__gold , \__mp_s1__gate );
  miter_cmp_prop #(19, "assert") \__mp_s2__assert (\__mp_s2__gold , \__mp_s2__gate );
  miter_cmp_prop #(19, "assert") \__mp_s3__assert (\__mp_s3__gold , \__mp_s3__gate );
  miter_cmp_prop #(19, "assert") \__mp_s4__assert (\__mp_s4__gold , \__mp_s4__gate );
  miter_cmp_prop #(19, "assert") \__mp_s5__assert (\__mp_s5__gold , \__mp_s5__gate );
  miter_cmp_prop #(8, "assert") \__mp_t0__assert (\__mp_t0__gold , \__mp_t0__gate );
  miter_cmp_prop #(8, "assert") \__mp_t1__assert (\__mp_t1__gold , \__mp_t1__gate );
  miter_cmp_prop #(8, "assert") \__mp_t2__assert (\__mp_t2__gold , \__mp_t2__gate );
  miter_cmp_prop #(8, "assert") \__mp_t3__assert (\__mp_t3__gold , \__mp_t3__gate );
  miter_cmp_prop #(8, "assert") \__mp_t4__assert (\__mp_t4__gold , \__mp_t4__gate );
  miter_cmp_prop #(8, "assert") \__mp_t5__assert (\__mp_t5__gold , \__mp_t5__gate );
  miter_cmp_prop #(1, "assert") \__mp_vld__assert (\__mp_vld__gold , \__mp_vld__gate );
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(19, "assert") \__po_out_data__assert (\__po_out_data__gold , \__po_out_data__gate );
  miter_cmp_prop #(1, "assert") \__po_out_valid__assert (\__po_out_valid__gold , \__po_out_valid__gate );
`endif
`ifdef COVER_DEF_CROSS_POINTS
  `ifdef DIRECT_CROSS_POINTS
  `else
  `endif
`endif
`ifdef COVER_DEF_GOLD_MATCH_POINTS
  miter_def_prop #(19, "cover") \__mp_p0__gold_cover (\__mp_p0__gold );
  miter_def_prop #(19, "cover") \__mp_p1__gold_cover (\__mp_p1__gold );
  miter_def_prop #(19, "cover") \__mp_p2__gold_cover (\__mp_p2__gold );
  miter_def_prop #(19, "cover") \__mp_p3__gold_cover (\__mp_p3__gold );
  miter_def_prop #(19, "cover") \__mp_p4__gold_cover (\__mp_p4__gold );
  miter_def_prop #(19, "cover") \__mp_p5__gold_cover (\__mp_p5__gold );
  miter_def_prop #(19, "cover") \__mp_s1__gold_cover (\__mp_s1__gold );
  miter_def_prop #(19, "cover") \__mp_s2__gold_cover (\__mp_s2__gold );
  miter_def_prop #(19, "cover") \__mp_s3__gold_cover (\__mp_s3__gold );
  miter_def_prop #(19, "cover") \__mp_s4__gold_cover (\__mp_s4__gold );
  miter_def_prop #(19, "cover") \__mp_s5__gold_cover (\__mp_s5__gold );
  miter_def_prop #(8, "cover") \__mp_t0__gold_cover (\__mp_t0__gold );
  miter_def_prop #(8, "cover") \__mp_t1__gold_cover (\__mp_t1__gold );
  miter_def_prop #(8, "cover") \__mp_t2__gold_cover (\__mp_t2__gold );
  miter_def_prop #(8, "cover") \__mp_t3__gold_cover (\__mp_t3__gold );
  miter_def_prop #(8, "cover") \__mp_t4__gold_cover (\__mp_t4__gold );
  miter_def_prop #(8, "cover") \__mp_t5__gold_cover (\__mp_t5__gold );
  miter_def_prop #(1, "cover") \__mp_vld__gold_cover (\__mp_vld__gold );
`endif
`ifdef COVER_DEF_GATE_MATCH_POINTS
  miter_def_prop #(19, "cover") \__mp_p0__gate_cover (\__mp_p0__gate );
  miter_def_prop #(19, "cover") \__mp_p1__gate_cover (\__mp_p1__gate );
  miter_def_prop #(19, "cover") \__mp_p2__gate_cover (\__mp_p2__gate );
  miter_def_prop #(19, "cover") \__mp_p3__gate_cover (\__mp_p3__gate );
  miter_def_prop #(19, "cover") \__mp_p4__gate_cover (\__mp_p4__gate );
  miter_def_prop #(19, "cover") \__mp_p5__gate_cover (\__mp_p5__gate );
  miter_def_prop #(19, "cover") \__mp_s1__gate_cover (\__mp_s1__gate );
  miter_def_prop #(19, "cover") \__mp_s2__gate_cover (\__mp_s2__gate );
  miter_def_prop #(19, "cover") \__mp_s3__gate_cover (\__mp_s3__gate );
  miter_def_prop #(19, "cover") \__mp_s4__gate_cover (\__mp_s4__gate );
  miter_def_prop #(19, "cover") \__mp_s5__gate_cover (\__mp_s5__gate );
  miter_def_prop #(8, "cover") \__mp_t0__gate_cover (\__mp_t0__gate );
  miter_def_prop #(8, "cover") \__mp_t1__gate_cover (\__mp_t1__gate );
  miter_def_prop #(8, "cover") \__mp_t2__gate_cover (\__mp_t2__gate );
  miter_def_prop #(8, "cover") \__mp_t3__gate_cover (\__mp_t3__gate );
  miter_def_prop #(8, "cover") \__mp_t4__gate_cover (\__mp_t4__gate );
  miter_def_prop #(8, "cover") \__mp_t5__gate_cover (\__mp_t5__gate );
  miter_def_prop #(1, "cover") \__mp_vld__gate_cover (\__mp_vld__gate );
`endif
`ifdef COVER_DEF_GOLD_OUTPUTS
  miter_def_prop #(19, "cover") \__po_out_data__gold_cover (\__po_out_data__gold );
  miter_def_prop #(1, "cover") \__po_out_valid__gold_cover (\__po_out_valid__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(19, "cover") \__po_out_data__gate_cover (\__po_out_data__gate );
  miter_def_prop #(1, "cover") \__po_out_valid__gate_cover (\__po_out_valid__gate );
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
module \gold.bm_fir6 (
  input  [  0:0] \__pi_clk ,
  input  [  7:0] \__pi_in_data ,
  input  [  0:0] \__pi_in_valid ,
  input  [  0:0] \__pi_rst ,
  output [ 18:0] \__mp_p0 ,
  output [ 18:0] \__mp_p1 ,
  output [ 18:0] \__mp_p2 ,
  output [ 18:0] \__mp_p3 ,
  output [ 18:0] \__mp_p4 ,
  output [ 18:0] \__mp_p5 ,
  output [ 18:0] \__mp_s1 ,
  output [ 18:0] \__mp_s2 ,
  output [ 18:0] \__mp_s3 ,
  output [ 18:0] \__mp_s4 ,
  output [ 18:0] \__mp_s5 ,
  output [  7:0] \__mp_t0 ,
  output [  7:0] \__mp_t1 ,
  output [  7:0] \__mp_t2 ,
  output [  7:0] \__mp_t3 ,
  output [  7:0] \__mp_t4 ,
  output [  7:0] \__mp_t5 ,
  output [  0:0] \__mp_vld ,
  output [ 18:0] \__po_out_data ,
  output [  0:0] \__po_out_valid
);
endmodule
module \gate.bm_fir6 (
  input  [  0:0] \__pi_clk ,
  input  [  7:0] \__pi_in_data ,
  input  [  0:0] \__pi_in_valid ,
  input  [  0:0] \__pi_rst ,
  output [ 18:0] \__mp_p0 ,
  output [ 18:0] \__mp_p1 ,
  output [ 18:0] \__mp_p2 ,
  output [ 18:0] \__mp_p3 ,
  output [ 18:0] \__mp_p4 ,
  output [ 18:0] \__mp_p5 ,
  output [ 18:0] \__mp_s1 ,
  output [ 18:0] \__mp_s2 ,
  output [ 18:0] \__mp_s3 ,
  output [ 18:0] \__mp_s4 ,
  output [ 18:0] \__mp_s5 ,
  output [  7:0] \__mp_t0 ,
  output [  7:0] \__mp_t1 ,
  output [  7:0] \__mp_t2 ,
  output [  7:0] \__mp_t3 ,
  output [  7:0] \__mp_t4 ,
  output [  7:0] \__mp_t5 ,
  output [  0:0] \__mp_vld ,
  output [ 18:0] \__po_out_data ,
  output [  0:0] \__po_out_valid
);
endmodule
