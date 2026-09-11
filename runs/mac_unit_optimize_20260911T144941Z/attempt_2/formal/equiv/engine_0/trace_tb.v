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
  reg [31:0] PI_b_vec;
  reg [31:0] PI_a_vec;
  wire [0:0] PI_clk = clock;
  reg [0:0] PI_rst;
  reg [0:0] PI_valid;
  __eqcheck_top UUT (
    .b_vec(PI_b_vec),
    .a_vec(PI_a_vec),
    .clk(PI_clk),
    .rst(PI_rst),
    .valid(PI_valid)
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
    // UUT.$auto$async2sync.\cc:107:execute$282  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$286  = 1'b1;
    UUT.gate_inst.a_reg = 32'b00000000000000000000000000000000;
    UUT.gate_inst.acc = 24'b100000000000000000000000;
    UUT.gate_inst.acc_valid = 1'b0;
    UUT.gate_inst.b_reg = 32'b00000000000000000000000000000000;
    UUT.gate_inst.valid_reg = 1'b0;
    UUT.gold_inst.a_reg = 32'b00000000000000000000000000000000;
    UUT.gold_inst.acc = 24'b000000000000000000000000;
    UUT.gold_inst.acc_valid = 1'b0;
    UUT.gold_inst.b_reg = 32'b00000000000000000000000000000000;
    UUT.gold_inst.valid_reg = 1'b0;

    // state 0
    PI_b_vec = 32'b00000000000000000000000000000000;
    PI_a_vec = 32'b00000000000000000000000000000000;
    PI_rst = 1'b1;
    PI_valid = 1'b0;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_b_vec <= 32'b00000000000000000000000000000000;
      PI_a_vec <= 32'b00000000000000000000000000000000;
      PI_rst <= 1'b0;
      PI_valid <= 1'b1;
    end

    // state 2
    if (cycle == 1) begin
      PI_b_vec <= 32'b00000000000000000000000000000000;
      PI_a_vec <= 32'b00000000000000000000000000000000;
      PI_rst <= 1'b0;
      PI_valid <= 1'b0;
    end

    // state 3
    if (cycle == 2) begin
      PI_b_vec <= 32'b00000000000000000000000000000000;
      PI_a_vec <= 32'b00000000000000000000000000000000;
      PI_rst <= 1'b0;
      PI_valid <= 1'b0;
    end

    // state 4
    if (cycle == 3) begin
      PI_b_vec <= 32'b00000000000000000000000000000000;
      PI_a_vec <= 32'b00000000000000000000000000000000;
      PI_rst <= 1'b0;
      PI_valid <= 1'b0;
    end

    genclock <= cycle < 4;
    cycle <= cycle + 1;
  end
endmodule
