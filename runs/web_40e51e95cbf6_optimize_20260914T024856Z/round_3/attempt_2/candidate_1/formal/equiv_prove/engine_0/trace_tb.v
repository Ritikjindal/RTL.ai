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
  reg [0:0] PI_in_valid;
  reg [15:0] PI_in_data;
  reg [0:0] PI_rst;
  wire [0:0] PI_clk = clock;
  reg [3:0] PI_cmd;
  __eqcheck_top UUT (
    .in_valid(PI_in_valid),
    .in_data(PI_in_data),
    .rst(PI_rst),
    .clk(PI_clk),
    .cmd(PI_cmd)
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
    // UUT.$auto$async2sync.\cc:107:execute$311  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$315  = 1'b1;
    UUT.gate_inst.acc = 24'b000000000000000000000000;
    UUT.gate_inst.acc_r = 24'b000000000000000000000000;
    UUT.gate_inst.cntx_r = 24'b000000000000000000000000;
    UUT.gate_inst.count = 8'b00000000;
    UUT.gate_inst.d4_r = 24'b000000000000000000000000;
    UUT.gate_inst.ext_r = 24'b000000000000000000000000;
    UUT.gate_inst.held_r = 24'b000000000000000000000000;
    UUT.gate_inst.hold = 16'b0000000000000000;
    UUT.gate_inst.length = 16'b0000000000000000;
    UUT.gate_inst.lenx_r = 24'b000000000000000000000000;
    UUT.gate_inst.out_data = 24'b000000000000000000000000;
    UUT.gate_inst.out_valid = 1'b0;
    UUT.gate_inst.state = 16'b0000000000000000;
    UUT.gate_inst.state0_r = 1'b0;
    UUT.gate_inst.state10_r = 1'b0;
    UUT.gate_inst.state11_r = 1'b0;
    UUT.gate_inst.state12_r = 1'b0;
    UUT.gate_inst.state12_r2 = 1'b0;
    UUT.gate_inst.state14_r = 1'b0;
    UUT.gate_inst.state15_r = 1'b0;
    UUT.gate_inst.state5_r = 1'b0;
    UUT.gate_inst.state8_r = 1'b0;
    UUT.gate_inst.state9_r = 1'b0;
    UUT.gate_inst.status = 4'b0000;
    UUT.gold_inst.acc = 24'b000000000000000000000000;
    UUT.gold_inst.count = 8'b00000000;
    UUT.gold_inst.hold = 16'b0000000000000000;
    UUT.gold_inst.length = 16'b0000000000000000;
    UUT.gold_inst.out_data = 24'b100000000000000000000000;
    UUT.gold_inst.out_valid = 1'b0;
    UUT.gold_inst.state = 16'b0000000000000000;
    UUT.gold_inst.status = 4'b1000;
    UUT.gold_out_data_d1 = 24'b100000000000000000000000;
    UUT.gold_out_valid_d1 = 1'b1;
    UUT.gold_status_d1 = 4'b1000;
    UUT.warmup = 8'b00000000;

    // state 0
    PI_in_valid = 1'b0;
    PI_in_data = 16'b0000000000000000;
    PI_rst = 1'b1;
    PI_cmd = 4'b0000;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_in_valid <= 1'b1;
      PI_in_data <= 16'b0101010110101010;
      PI_rst <= 1'b0;
      PI_cmd <= 4'b0000;
    end

    // state 2
    if (cycle == 1) begin
      PI_in_valid <= 1'b1;
      PI_in_data <= 16'b1010010101011010;
      PI_rst <= 1'b0;
      PI_cmd <= 4'b0000;
    end

    // state 3
    if (cycle == 2) begin
      PI_in_valid <= 1'b1;
      PI_in_data <= 16'b0000000000000000;
      PI_rst <= 1'b0;
      PI_cmd <= 4'b0000;
    end

    // state 4
    if (cycle == 3) begin
      PI_in_valid <= 1'b1;
      PI_in_data <= 16'b0000000000000000;
      PI_rst <= 1'b0;
      PI_cmd <= 4'b0000;
    end

    // state 5
    if (cycle == 4) begin
      PI_in_valid <= 1'b1;
      PI_in_data <= 16'b1001110000110000;
      PI_rst <= 1'b0;
      PI_cmd <= 4'b0000;
    end

    // state 6
    if (cycle == 5) begin
      PI_in_valid <= 1'b1;
      PI_in_data <= 16'b0000000000000000;
      PI_rst <= 1'b0;
      PI_cmd <= 4'b0000;
    end

    // state 7
    if (cycle == 6) begin
      PI_in_valid <= 1'b1;
      PI_in_data <= 16'b1010010101011010;
      PI_rst <= 1'b0;
      PI_cmd <= 4'b0000;
    end

    // state 8
    if (cycle == 7) begin
      PI_in_valid <= 1'b1;
      PI_in_data <= 16'b1000000000000000;
      PI_rst <= 1'b0;
      PI_cmd <= 4'b0000;
    end

    // state 9
    if (cycle == 8) begin
      PI_in_valid <= 1'b1;
      PI_in_data <= 16'b1000000001111101;
      PI_rst <= 1'b0;
      PI_cmd <= 4'b1000;
    end

    // state 10
    if (cycle == 9) begin
      PI_in_valid <= 1'b1;
      PI_in_data <= 16'b0000000000000000;
      PI_rst <= 1'b0;
      PI_cmd <= 4'b0000;
    end

    // state 11
    if (cycle == 10) begin
      PI_in_valid <= 1'b1;
      PI_in_data <= 16'b1010010101011010;
      PI_rst <= 1'b0;
      PI_cmd <= 4'b0000;
    end

    // state 12
    if (cycle == 11) begin
      PI_in_valid <= 1'b0;
      PI_in_data <= 16'b0000000000000000;
      PI_rst <= 1'b0;
      PI_cmd <= 4'b0000;
    end

    // state 13
    if (cycle == 12) begin
      PI_in_valid <= 1'b0;
      PI_in_data <= 16'b0000000000000000;
      PI_rst <= 1'b0;
      PI_cmd <= 4'b0000;
    end

    // state 14
    if (cycle == 13) begin
      PI_in_valid <= 1'b0;
      PI_in_data <= 16'b0000000000000000;
      PI_rst <= 1'b0;
      PI_cmd <= 4'b0000;
    end

    // state 15
    if (cycle == 14) begin
      PI_in_valid <= 1'b0;
      PI_in_data <= 16'b0000000000000000;
      PI_rst <= 1'b0;
      PI_cmd <= 4'b0000;
    end

    genclock <= cycle < 15;
    cycle <= cycle + 1;
  end
endmodule
