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
  reg [3:0] PI_cmd;
  wire [0:0] PI_clk = clock;
  reg [15:0] PI_in_data;
  reg [0:0] PI_in_valid;
  reg [0:0] PI_rst;
  __eqcheck_top UUT (
    .cmd(PI_cmd),
    .clk(PI_clk),
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
    // UUT.$auto$async2sync.\cc:107:execute$242  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$246  = 1'b0;
    UUT.gate_inst.acc = 24'b000000000000000000000000;
    UUT.gate_inst.count = 8'b00000000;
    UUT.gate_inst.hold = 16'b0000000000000000;
    UUT.gate_inst.length = 16'b0000000000000000;
    UUT.gate_inst.out_data = 24'b100000000100000000000000;
    UUT.gate_inst.out_valid = 1'b0;
    UUT.gate_inst.state = 16'b0010000000000000;
    UUT.gate_inst.status = 4'b0000;
    UUT.gold_inst.acc = 24'b000000000000000000000000;
    UUT.gold_inst.count = 8'b00000000;
    UUT.gold_inst.hold = 16'b0000000000000000;
    UUT.gold_inst.length = 16'b0000000000000000;
    UUT.gold_inst.out_data = 24'b100000000100000000000000;
    UUT.gold_inst.out_valid = 1'b0;
    UUT.gold_inst.state = 16'b0000000000000010;
    UUT.gold_inst.status = 4'b0000;

    // state 0
    PI_cmd = 4'b0000;
    PI_in_data = 16'b0000000000000000;
    PI_in_valid = 1'b0;
    PI_rst = 1'b0;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
    end

    // state 2
    if (cycle == 1) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
    end

    // state 3
    if (cycle == 2) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
    end

    // state 4
    if (cycle == 3) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
    end

    // state 5
    if (cycle == 4) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
    end

    // state 6
    if (cycle == 5) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
    end

    // state 7
    if (cycle == 6) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
    end

    // state 8
    if (cycle == 7) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
    end

    // state 9
    if (cycle == 8) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
    end

    // state 10
    if (cycle == 9) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
    end

    // state 11
    if (cycle == 10) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b0;
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

    // state 16
    if (cycle == 15) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0101010110101010;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
    end

    // state 17
    if (cycle == 16) begin
      PI_cmd <= 4'b1111;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
    end

    // state 18
    if (cycle == 17) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b1;
      PI_rst <= 1'b0;
    end

    // state 19
    if (cycle == 18) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
    end

    // state 20
    if (cycle == 19) begin
      PI_cmd <= 4'b0000;
      PI_in_data <= 16'b0000000000000000;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
    end

    genclock <= cycle < 20;
    cycle <= cycle + 1;
  end
endmodule
