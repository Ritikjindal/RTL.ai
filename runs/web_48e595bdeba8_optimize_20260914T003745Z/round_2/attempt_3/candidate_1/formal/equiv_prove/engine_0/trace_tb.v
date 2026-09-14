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
  reg [31:0] PI_a_vec;
  reg [31:0] PI_b_vec;
  wire [0:0] PI_clk = clock;
  reg [0:0] PI_rst;
  reg [0:0] PI_in_valid;
  __eqcheck_top UUT (
    .a_vec(PI_a_vec),
    .b_vec(PI_b_vec),
    .clk(PI_clk),
    .rst(PI_rst),
    .in_valid(PI_in_valid)
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
    // UUT.$auto$async2sync.\cc:107:execute$85  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$89  = 1'b1;
    UUT.gate_inst.a_reg = 32'b00000000000000000000000000000000;
    UUT.gate_inst.acc = 20'b00000000000000000000;
    UUT.gate_inst.b_reg = 32'b00000000000000000000000000000000;
    UUT.gate_inst.out_valid = 1'b0;
    UUT.gate_inst.sum_reg = 17'b00000000000000000;
    UUT.gate_inst.vld = 1'b0;
    UUT.gate_inst.vld2 = 1'b0;
    UUT.gold_acc_d1 = 20'b10000000000000000000;
    UUT.gold_inst.a_reg = 32'b00000000000000000000000000000000;
    UUT.gold_inst.acc = 20'b10000000000000000000;
    UUT.gold_inst.b_reg = 32'b00000000000000000000000000000000;
    UUT.gold_inst.out_valid = 1'b0;
    UUT.gold_inst.vld = 1'b0;
    UUT.gold_out_valid_d1 = 1'b1;
    UUT.warmup = 8'b00000000;

    // state 0
    PI_a_vec = 32'b00000000000000000000000000000000;
    PI_b_vec = 32'b00000000000000000000000000000000;
    PI_rst = 1'b1;
    PI_in_valid = 1'b0;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_a_vec <= 32'b11101101000110010101111110101000;
      PI_b_vec <= 32'b01010011010111000001100100101111;
      PI_rst <= 1'b0;
      PI_in_valid <= 1'b1;
    end

    // state 2
    if (cycle == 1) begin
      PI_a_vec <= 32'b00000000000000000000000000000000;
      PI_b_vec <= 32'b00000000000000000000000000000000;
      PI_rst <= 1'b0;
      PI_in_valid <= 1'b0;
    end

    // state 3
    if (cycle == 2) begin
      PI_a_vec <= 32'b00000000000000000000000000000000;
      PI_b_vec <= 32'b00000000000000000000000000000000;
      PI_rst <= 1'b0;
      PI_in_valid <= 1'b0;
    end

    // state 4
    if (cycle == 3) begin
      PI_a_vec <= 32'b00000000000000000000000000000000;
      PI_b_vec <= 32'b00000000000000000000000000000000;
      PI_rst <= 1'b0;
      PI_in_valid <= 1'b0;
    end

    // state 5
    if (cycle == 4) begin
      PI_a_vec <= 32'b00000000000000000000000000000000;
      PI_b_vec <= 32'b00000000000000000000000000000000;
      PI_rst <= 1'b0;
      PI_in_valid <= 1'b0;
    end

    genclock <= cycle < 5;
    cycle <= cycle + 1;
  end
endmodule
