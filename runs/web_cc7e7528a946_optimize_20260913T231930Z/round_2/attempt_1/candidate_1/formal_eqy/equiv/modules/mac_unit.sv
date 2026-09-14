module miter (
  input  [ 31:0] \__pi_a_vec ,
  input  [ 31:0] \__pi_b_vec ,
  input  [  0:0] \__pi_clk ,
  input  [  0:0] \__pi_rst ,
  input  [  0:0] \__pi_valid ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [ 31:0] \__mp_a_reg__gold ,
  output [ 31:0] \__mp_b_reg__gold ,
  output [ 15:0] \__mp_prod0__gold ,
  output [ 15:0] \__mp_prod1__gold ,
  output [ 15:0] \__mp_prod2__gold ,
  output [ 15:0] \__mp_prod3__gold ,
  output [ 17:0] \__mp_sum__gold ,
  output [ 16:0] \__mp_sum01__gold ,
  output [ 16:0] \__mp_sum23__gold ,
  output [ 17:0] \__mp_sum_reg__gold ,
  output [  0:0] \__mp_valid_reg__gold ,
  output [  0:0] \__mp_valid_reg2__gold ,
  output [ 31:0] \__mp_a_reg__gate ,
  output [ 31:0] \__mp_b_reg__gate ,
  output [ 15:0] \__mp_prod0__gate ,
  output [ 15:0] \__mp_prod1__gate ,
  output [ 15:0] \__mp_prod2__gate ,
  output [ 15:0] \__mp_prod3__gate ,
  output [ 17:0] \__mp_sum__gate ,
  output [ 16:0] \__mp_sum01__gate ,
  output [ 16:0] \__mp_sum23__gate ,
  output [ 17:0] \__mp_sum_reg__gate ,
  output [  0:0] \__mp_valid_reg__gate ,
  output [  0:0] \__mp_valid_reg2__gate ,
  output [ 23:0] \__po_acc__gold ,
  output [  0:0] \__po_acc_valid__gold ,
  output [ 23:0] \__po_acc__gate ,
  output [  0:0] \__po_acc_valid__gate
);
  \gold.mac_unit gold (
    .\__pi_a_vec (\__pi_a_vec ),
    .\__pi_b_vec (\__pi_b_vec ),
    .\__pi_clk (\__pi_clk ),
    .\__pi_rst (\__pi_rst ),
    .\__pi_valid (\__pi_valid ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__mp_a_reg (\__mp_a_reg__gold ),
    .\__mp_b_reg (\__mp_b_reg__gold ),
    .\__mp_prod0 (\__mp_prod0__gold ),
    .\__mp_prod1 (\__mp_prod1__gold ),
    .\__mp_prod2 (\__mp_prod2__gold ),
    .\__mp_prod3 (\__mp_prod3__gold ),
    .\__mp_sum (\__mp_sum__gold ),
    .\__mp_sum01 (\__mp_sum01__gold ),
    .\__mp_sum23 (\__mp_sum23__gold ),
    .\__mp_sum_reg (\__mp_sum_reg__gold ),
    .\__mp_valid_reg (\__mp_valid_reg__gold ),
    .\__mp_valid_reg2 (\__mp_valid_reg2__gold ),
    .\__po_acc (\__po_acc__gold ),
    .\__po_acc_valid (\__po_acc_valid__gold )
  );
  \gate.mac_unit gate (
    .\__pi_a_vec (\__pi_a_vec ),
    .\__pi_b_vec (\__pi_b_vec ),
    .\__pi_clk (\__pi_clk ),
    .\__pi_rst (\__pi_rst ),
    .\__pi_valid (\__pi_valid ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__mp_a_reg (\__mp_a_reg__gate ),
    .\__mp_b_reg (\__mp_b_reg__gate ),
    .\__mp_prod0 (\__mp_prod0__gate ),
    .\__mp_prod1 (\__mp_prod1__gate ),
    .\__mp_prod2 (\__mp_prod2__gate ),
    .\__mp_prod3 (\__mp_prod3__gate ),
    .\__mp_sum (\__mp_sum__gate ),
    .\__mp_sum01 (\__mp_sum01__gate ),
    .\__mp_sum23 (\__mp_sum23__gate ),
    .\__mp_sum_reg (\__mp_sum_reg__gate ),
    .\__mp_valid_reg (\__mp_valid_reg__gate ),
    .\__mp_valid_reg2 (\__mp_valid_reg2__gate ),
    .\__po_acc (\__po_acc__gate ),
    .\__po_acc_valid (\__po_acc_valid__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(32, "assume") \__pi_a_vec__assume (\__pi_a_vec );
  miter_def_prop #(32, "assume") \__pi_b_vec__assume (\__pi_b_vec );
  miter_def_prop #(1, "assume") \__pi_clk__assume (\__pi_clk );
  miter_def_prop #(1, "assume") \__pi_rst__assume (\__pi_rst );
  miter_def_prop #(1, "assume") \__pi_valid__assume (\__pi_valid );
`endif
`ifndef DIRECT_CROSS_POINTS
`endif
`ifdef CHECK_MATCH_POINTS
  miter_cmp_prop #(32, "assert") \__mp_a_reg__assert (\__mp_a_reg__gold , \__mp_a_reg__gate );
  miter_cmp_prop #(32, "assert") \__mp_b_reg__assert (\__mp_b_reg__gold , \__mp_b_reg__gate );
  miter_cmp_prop #(16, "assert") \__mp_prod0__assert (\__mp_prod0__gold , \__mp_prod0__gate );
  miter_cmp_prop #(16, "assert") \__mp_prod1__assert (\__mp_prod1__gold , \__mp_prod1__gate );
  miter_cmp_prop #(16, "assert") \__mp_prod2__assert (\__mp_prod2__gold , \__mp_prod2__gate );
  miter_cmp_prop #(16, "assert") \__mp_prod3__assert (\__mp_prod3__gold , \__mp_prod3__gate );
  miter_cmp_prop #(18, "assert") \__mp_sum__assert (\__mp_sum__gold , \__mp_sum__gate );
  miter_cmp_prop #(17, "assert") \__mp_sum01__assert (\__mp_sum01__gold , \__mp_sum01__gate );
  miter_cmp_prop #(17, "assert") \__mp_sum23__assert (\__mp_sum23__gold , \__mp_sum23__gate );
  miter_cmp_prop #(18, "assert") \__mp_sum_reg__assert (\__mp_sum_reg__gold , \__mp_sum_reg__gate );
  miter_cmp_prop #(1, "assert") \__mp_valid_reg__assert (\__mp_valid_reg__gold , \__mp_valid_reg__gate );
  miter_cmp_prop #(1, "assert") \__mp_valid_reg2__assert (\__mp_valid_reg2__gold , \__mp_valid_reg2__gate );
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(24, "assert") \__po_acc__assert (\__po_acc__gold , \__po_acc__gate );
  miter_cmp_prop #(1, "assert") \__po_acc_valid__assert (\__po_acc_valid__gold , \__po_acc_valid__gate );
`endif
`ifdef COVER_DEF_CROSS_POINTS
  `ifdef DIRECT_CROSS_POINTS
  `else
  `endif
`endif
`ifdef COVER_DEF_GOLD_MATCH_POINTS
  miter_def_prop #(32, "cover") \__mp_a_reg__gold_cover (\__mp_a_reg__gold );
  miter_def_prop #(32, "cover") \__mp_b_reg__gold_cover (\__mp_b_reg__gold );
  miter_def_prop #(16, "cover") \__mp_prod0__gold_cover (\__mp_prod0__gold );
  miter_def_prop #(16, "cover") \__mp_prod1__gold_cover (\__mp_prod1__gold );
  miter_def_prop #(16, "cover") \__mp_prod2__gold_cover (\__mp_prod2__gold );
  miter_def_prop #(16, "cover") \__mp_prod3__gold_cover (\__mp_prod3__gold );
  miter_def_prop #(18, "cover") \__mp_sum__gold_cover (\__mp_sum__gold );
  miter_def_prop #(17, "cover") \__mp_sum01__gold_cover (\__mp_sum01__gold );
  miter_def_prop #(17, "cover") \__mp_sum23__gold_cover (\__mp_sum23__gold );
  miter_def_prop #(18, "cover") \__mp_sum_reg__gold_cover (\__mp_sum_reg__gold );
  miter_def_prop #(1, "cover") \__mp_valid_reg__gold_cover (\__mp_valid_reg__gold );
  miter_def_prop #(1, "cover") \__mp_valid_reg2__gold_cover (\__mp_valid_reg2__gold );
`endif
`ifdef COVER_DEF_GATE_MATCH_POINTS
  miter_def_prop #(32, "cover") \__mp_a_reg__gate_cover (\__mp_a_reg__gate );
  miter_def_prop #(32, "cover") \__mp_b_reg__gate_cover (\__mp_b_reg__gate );
  miter_def_prop #(16, "cover") \__mp_prod0__gate_cover (\__mp_prod0__gate );
  miter_def_prop #(16, "cover") \__mp_prod1__gate_cover (\__mp_prod1__gate );
  miter_def_prop #(16, "cover") \__mp_prod2__gate_cover (\__mp_prod2__gate );
  miter_def_prop #(16, "cover") \__mp_prod3__gate_cover (\__mp_prod3__gate );
  miter_def_prop #(18, "cover") \__mp_sum__gate_cover (\__mp_sum__gate );
  miter_def_prop #(17, "cover") \__mp_sum01__gate_cover (\__mp_sum01__gate );
  miter_def_prop #(17, "cover") \__mp_sum23__gate_cover (\__mp_sum23__gate );
  miter_def_prop #(18, "cover") \__mp_sum_reg__gate_cover (\__mp_sum_reg__gate );
  miter_def_prop #(1, "cover") \__mp_valid_reg__gate_cover (\__mp_valid_reg__gate );
  miter_def_prop #(1, "cover") \__mp_valid_reg2__gate_cover (\__mp_valid_reg2__gate );
`endif
`ifdef COVER_DEF_GOLD_OUTPUTS
  miter_def_prop #(24, "cover") \__po_acc__gold_cover (\__po_acc__gold );
  miter_def_prop #(1, "cover") \__po_acc_valid__gold_cover (\__po_acc_valid__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(24, "cover") \__po_acc__gate_cover (\__po_acc__gate );
  miter_def_prop #(1, "cover") \__po_acc_valid__gate_cover (\__po_acc_valid__gate );
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
module \gold.mac_unit (
  input  [ 31:0] \__pi_a_vec ,
  input  [ 31:0] \__pi_b_vec ,
  input  [  0:0] \__pi_clk ,
  input  [  0:0] \__pi_rst ,
  input  [  0:0] \__pi_valid ,
  output [ 31:0] \__mp_a_reg ,
  output [ 31:0] \__mp_b_reg ,
  output [ 15:0] \__mp_prod0 ,
  output [ 15:0] \__mp_prod1 ,
  output [ 15:0] \__mp_prod2 ,
  output [ 15:0] \__mp_prod3 ,
  output [ 17:0] \__mp_sum ,
  output [ 16:0] \__mp_sum01 ,
  output [ 16:0] \__mp_sum23 ,
  output [ 17:0] \__mp_sum_reg ,
  output [  0:0] \__mp_valid_reg ,
  output [  0:0] \__mp_valid_reg2 ,
  output [ 23:0] \__po_acc ,
  output [  0:0] \__po_acc_valid
);
endmodule
module \gate.mac_unit (
  input  [ 31:0] \__pi_a_vec ,
  input  [ 31:0] \__pi_b_vec ,
  input  [  0:0] \__pi_clk ,
  input  [  0:0] \__pi_rst ,
  input  [  0:0] \__pi_valid ,
  output [ 31:0] \__mp_a_reg ,
  output [ 31:0] \__mp_b_reg ,
  output [ 15:0] \__mp_prod0 ,
  output [ 15:0] \__mp_prod1 ,
  output [ 15:0] \__mp_prod2 ,
  output [ 15:0] \__mp_prod3 ,
  output [ 17:0] \__mp_sum ,
  output [ 16:0] \__mp_sum01 ,
  output [ 16:0] \__mp_sum23 ,
  output [ 17:0] \__mp_sum_reg ,
  output [  0:0] \__mp_valid_reg ,
  output [  0:0] \__mp_valid_reg2 ,
  output [ 23:0] \__po_acc ,
  output [  0:0] \__po_acc_valid
);
endmodule
