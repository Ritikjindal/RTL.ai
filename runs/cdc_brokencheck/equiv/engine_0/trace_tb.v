`ifndef VERILATOR
module testbench;
  reg [4095:0] vcdfile;
  reg clock;
`else
module testbench(input clock, output reg genclock);
  initial genclock = 1;
`endif
  reg genclock = 1;
  reg [31:0] cycle = 0;
  reg [0:0] PI_enable;
  reg [0:0] PI_rst;
  reg [0:0] PI_clk_b;
  reg [0:0] PI_clk_a;
  __eqcheck_top UUT (
    .enable(PI_enable),
    .rst(PI_rst),
    .clk_b(PI_clk_b),
    .clk_a(PI_clk_a)
  );
`ifndef VERILATOR
  initial begin
    if ($value$plusargs("vcd=%s", vcdfile)) begin
      $dumpfile(vcdfile);
      $dumpvars(0, testbench);
    end
    #5 clock = 0;
    while (genclock) begin
      #5 clock = 0;
      #5 clock = 1;
    end
  end
`endif
  initial begin
`ifndef VERILATOR
    #1;
`endif
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$$0/seen_rst_clk_a[0:0]#sampled$56  = 1'b0;
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$$0/seen_rst_clk_b[0:0]#sampled$46  = 1'b0;
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$/seen_rst_clk_a#sampled$54  = 1'b0;
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$/seen_rst_clk_b#sampled$44  = 1'b0;
    // UUT.$auto$clk2fflogic.\cc:87:sample_control_edge$/clk_a#sampled$58  = 1'b1;
    // UUT.$auto$clk2fflogic.\cc:87:sample_control_edge$/clk_b#sampled$48  = 1'b1;
    // UUT.gate_inst.$auto$clk2fflogic.\cc:101:sample_data$/_00_#sampled$66  = 8'b00000000;
    // UUT.gate_inst.$auto$clk2fflogic.\cc:101:sample_data$/_01_#sampled$76  = 8'b00000000;
    // UUT.gate_inst.$auto$clk2fflogic.\cc:101:sample_data$/count_a#sampled$64  = 8'b00000000;
    // UUT.gate_inst.$auto$clk2fflogic.\cc:101:sample_data$/count_b#sampled$74  = 8'b00000000;
    // UUT.gate_inst.$auto$clk2fflogic.\cc:87:sample_control_edge$/clk_a#sampled$68  = 1'b1;
    // UUT.gate_inst.$auto$clk2fflogic.\cc:87:sample_control_edge$/clk_b#sampled$78  = 1'b1;
    // UUT.gold_inst.$auto$clk2fflogic.\cc:101:sample_data$/_00_#sampled$86  = 8'b00000000;
    // UUT.gold_inst.$auto$clk2fflogic.\cc:101:sample_data$/_01_#sampled$106  = 8'b00000000;
    // UUT.gold_inst.$auto$clk2fflogic.\cc:101:sample_data$/_02_#sampled$96  = 8'b00000000;
    // UUT.gold_inst.$auto$clk2fflogic.\cc:101:sample_data$/count_a#sampled$84  = 8'b00000001;
    // UUT.gold_inst.$auto$clk2fflogic.\cc:101:sample_data$/count_b#sampled$104  = 8'b00000000;
    // UUT.gold_inst.$auto$clk2fflogic.\cc:101:sample_data$/sync_stage1#sampled$94  = 8'b00000000;
    // UUT.gold_inst.$auto$clk2fflogic.\cc:87:sample_control_edge$/clk_a#sampled$88  = 1'b1;
    // UUT.gold_inst.$auto$clk2fflogic.\cc:87:sample_control_edge$/clk_b#sampled$108  = 1'b1;

    // state 0
    PI_enable = 1'b0;
    PI_rst = 1'b1;
    PI_clk_b = 1'b1;
    PI_clk_a = 1'b0;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_enable <= 1'b0;
      PI_rst <= 1'b1;
      PI_clk_b <= 1'b0;
      PI_clk_a <= 1'b1;
    end

    // state 2
    if (cycle == 1) begin
      PI_enable <= 1'b1;
      PI_rst <= 1'b0;
      PI_clk_b <= 1'b1;
      PI_clk_a <= 1'b0;
    end

    // state 3
    if (cycle == 2) begin
      PI_enable <= 1'b0;
      PI_rst <= 1'b0;
      PI_clk_b <= 1'b0;
      PI_clk_a <= 1'b1;
    end

    // state 4
    if (cycle == 3) begin
      PI_enable <= 1'b0;
      PI_rst <= 1'b0;
      PI_clk_b <= 1'b1;
      PI_clk_a <= 1'b0;
    end

    genclock <= cycle < 4;
    cycle <= cycle + 1;
  end
endmodule
