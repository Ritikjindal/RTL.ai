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
  wire [0:0] PI_clk = clock;
  reg [3:0] PI_cmd;
  reg [15:0] PI_in_data;
  reg [0:0] PI_in_valid;
  reg [0:0] PI_rst;
  __eqcheck_top UUT (
    .clk(PI_clk),
    .cmd(PI_cmd),
    .in_data(PI_in_data),
    .in_valid(PI_in_valid),
    .rst(PI_rst)
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
    // UUT.$auto$async2sync.\cc:107:execute$287  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$291  = 1'b1;
    UUT.gate_inst.acc = 24'b000000000000000000000000;
    UUT.gate_inst.acc_d = 24'b000000000000000000000000;
    UUT.gate_inst.acc_mid = 24'b000000000000000000000000;
    UUT.gate_inst.cntx_d = 24'b000000000000000000000000;
    UUT.gate_inst.count = 8'b00000000;
    UUT.gate_inst.ext_d = 24'b000000000000000000000000;
    UUT.gate_inst.held_d = 24'b000000000000000000000000;
    UUT.gate_inst.hold = 16'b0000000000000000;
    UUT.gate_inst.in_valid_d = 1'b0;
    UUT.gate_inst.length = 16'b0000000000000000;
    UUT.gate_inst.lenx_d = 24'b000000000000000000000000;
    UUT.gate_inst.out_data = 24'b000000000000000000000000;
    UUT.gate_inst.out_valid = 1'b0;
    UUT.gate_inst.state = 16'b0000000000000000;
    UUT.gate_inst.state_d = 16'b0000000000000000;
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
    PI_cmd = 4'b0000;
    PI_in_data = 16'b0000000000000000;
    PI_in_valid = 1'b0;
    PI_rst = 1'b1;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0101010110101010;
      PI_in_valid <= 1'b1;
      PI_rst <= 1'b0;
    end

    // state 2
    if (cycle == 1) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b1010010101011010;
      PI_in_valid <= 1'b1;
      PI_rst <= 1'b0;
    end

    // state 3
    if (cycle == 2) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b1;
      PI_rst <= 1'b0;
    end

    // state 4
    if (cycle == 3) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b1011100000000000;
      PI_in_valid <= 1'b1;
      PI_rst <= 1'b0;
    end

    // state 5
    if (cycle == 4) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0101011000000000;
      PI_in_valid <= 1'b1;
      PI_rst <= 1'b0;
    end

    // state 6
    if (cycle == 5) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b1111011111111100;
      PI_in_valid <= 1'b1;
      PI_rst <= 1'b0;
    end

    // state 7
    if (cycle == 6) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b1000101011110000;
      PI_in_valid <= 1'b1;
      PI_rst <= 1'b0;
    end

    // state 8
    if (cycle == 7) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0111111000000000;
      PI_in_valid <= 1'b1;
      PI_rst <= 1'b0;
    end

    // state 9
    if (cycle == 8) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b1010010001011010;
      PI_in_valid <= 1'b1;
      PI_rst <= 1'b0;
    end

    // state 10
    if (cycle == 9) begin
      PI_cmd <= 4'b1000;
      PI_in_data <= 16'b0100001100000000;
      PI_in_valid <= 1'b1;
      PI_rst <= 1'b0;
    end

    // state 11
    if (cycle == 10) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b1010010101011010;
      PI_in_valid <= 1'b1;
      PI_rst <= 1'b0;
    end

    // state 12
    if (cycle == 11) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
    end

    // state 13
    if (cycle == 12) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
    end

    // state 14
    if (cycle == 13) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
    end

    // state 15
    if (cycle == 14) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
    end

    genclock <= cycle < 15;
    cycle <= cycle + 1;
  end
endmodule
