module miter (
  input  [  0:0] \__pi_clk ,
  input  [  3:0] \__pi_cmd ,
  input  [ 15:0] \__pi_in_data ,
  input  [  0:0] \__pi_in_valid ,
  input  [  0:0] \__pi_rst ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [ 23:0] \__mp_acc__gold ,
  output [ 23:0] \__mp_cntx__gold ,
  output [  7:0] \__mp_count__gold ,
  output [ 23:0] \__mp_d0__gold ,
  output [ 23:0] \__mp_d9__gold ,
  output [ 23:0] \__mp_ext__gold ,
  output [ 23:0] \__mp_held__gold ,
  output [ 15:0] \__mp_hold__gold ,
  output [ 15:0] \__mp_length__gold ,
  output [ 23:0] \__mp_lenx__gold ,
  output [ 15:0] \__mp_next__gold ,
  output [ 15:0] \__mp_state__gold ,
  output [ 23:0] \__mp_acc__gate ,
  output [ 23:0] \__mp_cntx__gate ,
  output [  7:0] \__mp_count__gate ,
  output [ 23:0] \__mp_d0__gate ,
  output [ 23:0] \__mp_d9__gate ,
  output [ 23:0] \__mp_ext__gate ,
  output [ 23:0] \__mp_held__gate ,
  output [ 15:0] \__mp_hold__gate ,
  output [ 15:0] \__mp_length__gate ,
  output [ 23:0] \__mp_lenx__gate ,
  output [ 15:0] \__mp_next__gate ,
  output [ 15:0] \__mp_state__gate ,
  output [ 23:0] \__po_out_data__gold ,
  output [  0:0] \__po_out_valid__gold ,
  output [  3:0] \__po_status__gold ,
  output [ 23:0] \__po_out_data__gate ,
  output [  0:0] \__po_out_valid__gate ,
  output [  3:0] \__po_status__gate
);
  \gold.bm_fsm_ctrl gold (
    .\__pi_clk (\__pi_clk ),
    .\__pi_cmd (\__pi_cmd ),
    .\__pi_in_data (\__pi_in_data ),
    .\__pi_in_valid (\__pi_in_valid ),
    .\__pi_rst (\__pi_rst ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__mp_acc (\__mp_acc__gold ),
    .\__mp_cntx (\__mp_cntx__gold ),
    .\__mp_count (\__mp_count__gold ),
    .\__mp_d0 (\__mp_d0__gold ),
    .\__mp_d9 (\__mp_d9__gold ),
    .\__mp_ext (\__mp_ext__gold ),
    .\__mp_held (\__mp_held__gold ),
    .\__mp_hold (\__mp_hold__gold ),
    .\__mp_length (\__mp_length__gold ),
    .\__mp_lenx (\__mp_lenx__gold ),
    .\__mp_next (\__mp_next__gold ),
    .\__mp_state (\__mp_state__gold ),
    .\__po_out_data (\__po_out_data__gold ),
    .\__po_out_valid (\__po_out_valid__gold ),
    .\__po_status (\__po_status__gold )
  );
  \gate.bm_fsm_ctrl gate (
    .\__pi_clk (\__pi_clk ),
    .\__pi_cmd (\__pi_cmd ),
    .\__pi_in_data (\__pi_in_data ),
    .\__pi_in_valid (\__pi_in_valid ),
    .\__pi_rst (\__pi_rst ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__mp_acc (\__mp_acc__gate ),
    .\__mp_cntx (\__mp_cntx__gate ),
    .\__mp_count (\__mp_count__gate ),
    .\__mp_d0 (\__mp_d0__gate ),
    .\__mp_d9 (\__mp_d9__gate ),
    .\__mp_ext (\__mp_ext__gate ),
    .\__mp_held (\__mp_held__gate ),
    .\__mp_hold (\__mp_hold__gate ),
    .\__mp_length (\__mp_length__gate ),
    .\__mp_lenx (\__mp_lenx__gate ),
    .\__mp_next (\__mp_next__gate ),
    .\__mp_state (\__mp_state__gate ),
    .\__po_out_data (\__po_out_data__gate ),
    .\__po_out_valid (\__po_out_valid__gate ),
    .\__po_status (\__po_status__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(1, "assume") \__pi_clk__assume (\__pi_clk );
  miter_def_prop #(4, "assume") \__pi_cmd__assume (\__pi_cmd );
  miter_def_prop #(16, "assume") \__pi_in_data__assume (\__pi_in_data );
  miter_def_prop #(1, "assume") \__pi_in_valid__assume (\__pi_in_valid );
  miter_def_prop #(1, "assume") \__pi_rst__assume (\__pi_rst );
`endif
`ifndef DIRECT_CROSS_POINTS
`endif
`ifdef CHECK_MATCH_POINTS
  miter_cmp_prop #(24, "assert") \__mp_acc__assert (\__mp_acc__gold , \__mp_acc__gate );
  miter_cmp_prop #(24, "assert") \__mp_cntx__assert (\__mp_cntx__gold , \__mp_cntx__gate );
  miter_cmp_prop #(8, "assert") \__mp_count__assert (\__mp_count__gold , \__mp_count__gate );
  miter_cmp_prop #(24, "assert") \__mp_d0__assert (\__mp_d0__gold , \__mp_d0__gate );
  miter_cmp_prop #(24, "assert") \__mp_d9__assert (\__mp_d9__gold , \__mp_d9__gate );
  miter_cmp_prop #(24, "assert") \__mp_ext__assert (\__mp_ext__gold , \__mp_ext__gate );
  miter_cmp_prop #(24, "assert") \__mp_held__assert (\__mp_held__gold , \__mp_held__gate );
  miter_cmp_prop #(16, "assert") \__mp_hold__assert (\__mp_hold__gold , \__mp_hold__gate );
  miter_cmp_prop #(16, "assert") \__mp_length__assert (\__mp_length__gold , \__mp_length__gate );
  miter_cmp_prop #(24, "assert") \__mp_lenx__assert (\__mp_lenx__gold , \__mp_lenx__gate );
  miter_cmp_prop #(16, "assert") \__mp_next__assert (\__mp_next__gold , \__mp_next__gate );
  miter_cmp_prop #(16, "assert") \__mp_state__assert (\__mp_state__gold , \__mp_state__gate );
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(24, "assert") \__po_out_data__assert (\__po_out_data__gold , \__po_out_data__gate );
  miter_cmp_prop #(1, "assert") \__po_out_valid__assert (\__po_out_valid__gold , \__po_out_valid__gate );
  miter_cmp_prop #(4, "assert") \__po_status__assert (\__po_status__gold , \__po_status__gate );
`endif
`ifdef COVER_DEF_CROSS_POINTS
  `ifdef DIRECT_CROSS_POINTS
  `else
  `endif
`endif
`ifdef COVER_DEF_GOLD_MATCH_POINTS
  miter_def_prop #(24, "cover") \__mp_acc__gold_cover (\__mp_acc__gold );
  miter_def_prop #(24, "cover") \__mp_cntx__gold_cover (\__mp_cntx__gold );
  miter_def_prop #(8, "cover") \__mp_count__gold_cover (\__mp_count__gold );
  miter_def_prop #(24, "cover") \__mp_d0__gold_cover (\__mp_d0__gold );
  miter_def_prop #(24, "cover") \__mp_d9__gold_cover (\__mp_d9__gold );
  miter_def_prop #(24, "cover") \__mp_ext__gold_cover (\__mp_ext__gold );
  miter_def_prop #(24, "cover") \__mp_held__gold_cover (\__mp_held__gold );
  miter_def_prop #(16, "cover") \__mp_hold__gold_cover (\__mp_hold__gold );
  miter_def_prop #(16, "cover") \__mp_length__gold_cover (\__mp_length__gold );
  miter_def_prop #(24, "cover") \__mp_lenx__gold_cover (\__mp_lenx__gold );
  miter_def_prop #(16, "cover") \__mp_next__gold_cover (\__mp_next__gold );
  miter_def_prop #(16, "cover") \__mp_state__gold_cover (\__mp_state__gold );
`endif
`ifdef COVER_DEF_GATE_MATCH_POINTS
  miter_def_prop #(24, "cover") \__mp_acc__gate_cover (\__mp_acc__gate );
  miter_def_prop #(24, "cover") \__mp_cntx__gate_cover (\__mp_cntx__gate );
  miter_def_prop #(8, "cover") \__mp_count__gate_cover (\__mp_count__gate );
  miter_def_prop #(24, "cover") \__mp_d0__gate_cover (\__mp_d0__gate );
  miter_def_prop #(24, "cover") \__mp_d9__gate_cover (\__mp_d9__gate );
  miter_def_prop #(24, "cover") \__mp_ext__gate_cover (\__mp_ext__gate );
  miter_def_prop #(24, "cover") \__mp_held__gate_cover (\__mp_held__gate );
  miter_def_prop #(16, "cover") \__mp_hold__gate_cover (\__mp_hold__gate );
  miter_def_prop #(16, "cover") \__mp_length__gate_cover (\__mp_length__gate );
  miter_def_prop #(24, "cover") \__mp_lenx__gate_cover (\__mp_lenx__gate );
  miter_def_prop #(16, "cover") \__mp_next__gate_cover (\__mp_next__gate );
  miter_def_prop #(16, "cover") \__mp_state__gate_cover (\__mp_state__gate );
`endif
`ifdef COVER_DEF_GOLD_OUTPUTS
  miter_def_prop #(24, "cover") \__po_out_data__gold_cover (\__po_out_data__gold );
  miter_def_prop #(1, "cover") \__po_out_valid__gold_cover (\__po_out_valid__gold );
  miter_def_prop #(4, "cover") \__po_status__gold_cover (\__po_status__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(24, "cover") \__po_out_data__gate_cover (\__po_out_data__gate );
  miter_def_prop #(1, "cover") \__po_out_valid__gate_cover (\__po_out_valid__gate );
  miter_def_prop #(4, "cover") \__po_status__gate_cover (\__po_status__gate );
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
module \gold.bm_fsm_ctrl (
  input  [  0:0] \__pi_clk ,
  input  [  3:0] \__pi_cmd ,
  input  [ 15:0] \__pi_in_data ,
  input  [  0:0] \__pi_in_valid ,
  input  [  0:0] \__pi_rst ,
  output [ 23:0] \__mp_acc ,
  output [ 23:0] \__mp_cntx ,
  output [  7:0] \__mp_count ,
  output [ 23:0] \__mp_d0 ,
  output [ 23:0] \__mp_d9 ,
  output [ 23:0] \__mp_ext ,
  output [ 23:0] \__mp_held ,
  output [ 15:0] \__mp_hold ,
  output [ 15:0] \__mp_length ,
  output [ 23:0] \__mp_lenx ,
  output [ 15:0] \__mp_next ,
  output [ 15:0] \__mp_state ,
  output [ 23:0] \__po_out_data ,
  output [  0:0] \__po_out_valid ,
  output [  3:0] \__po_status
);
endmodule
module \gate.bm_fsm_ctrl (
  input  [  0:0] \__pi_clk ,
  input  [  3:0] \__pi_cmd ,
  input  [ 15:0] \__pi_in_data ,
  input  [  0:0] \__pi_in_valid ,
  input  [  0:0] \__pi_rst ,
  output [ 23:0] \__mp_acc ,
  output [ 23:0] \__mp_cntx ,
  output [  7:0] \__mp_count ,
  output [ 23:0] \__mp_d0 ,
  output [ 23:0] \__mp_d9 ,
  output [ 23:0] \__mp_ext ,
  output [ 23:0] \__mp_held ,
  output [ 15:0] \__mp_hold ,
  output [ 15:0] \__mp_length ,
  output [ 23:0] \__mp_lenx ,
  output [ 15:0] \__mp_next ,
  output [ 15:0] \__mp_state ,
  output [ 23:0] \__po_out_data ,
  output [  0:0] \__po_out_valid ,
  output [  3:0] \__po_status
);
endmodule
