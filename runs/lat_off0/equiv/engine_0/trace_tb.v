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
  reg [0:0] PI_rst;
  wire [0:0] PI_clk = clock;
  reg [7:0] PI_din;
  __eqcheck_top UUT (
    .rst(PI_rst),
    .clk(PI_clk),
    .din(PI_din)
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
    // UUT.$auto$async2sync.\cc:107:execute$23  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$27  = 1'b1;
    UUT.gate_inst.dout = 8'b10000000;
    UUT.gate_inst.stage1 = 8'b00000000;
    UUT.gold_inst.dout = 8'b00000000;

    // state 0
    PI_rst = 1'b1;
    PI_din = 8'b00000000;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_rst <= 1'b0;
      PI_din <= 8'b00000000;
    end

    // state 2
    if (cycle == 1) begin
      PI_rst <= 1'b0;
      PI_din <= 8'b00000000;
    end

    // state 3
    if (cycle == 2) begin
      PI_rst <= 1'b0;
      PI_din <= 8'b00000000;
    end

    genclock <= cycle < 3;
    cycle <= cycle + 1;
  end
endmodule
