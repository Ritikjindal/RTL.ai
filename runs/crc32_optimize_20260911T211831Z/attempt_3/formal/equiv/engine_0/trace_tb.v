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
  reg [0:0] PI_in_last;
  reg [3:0] PI_in_bytes;
  wire [0:0] PI_clk = clock;
  reg [0:0] PI_in_valid;
  reg [0:0] PI_rst;
  reg [63:0] PI_in_data;
  __eqcheck_top UUT (
    .in_last(PI_in_last),
    .in_bytes(PI_in_bytes),
    .clk(PI_clk),
    .in_valid(PI_in_valid),
    .rst(PI_rst),
    .in_data(PI_in_data)
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
    // UUT.$auto$async2sync.\cc:107:execute$1954  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$1958  = 1'b1;
    UUT.gate_inst.active = 1'b0;
    UUT.gate_inst.crc = 32'b00000000000000000000000000000000;
    UUT.gate_inst.out_crc = 32'b10000000000000000000000000000000;
    UUT.gate_inst.out_valid = 1'b0;
    UUT.gold_inst.active = 1'b0;
    UUT.gold_inst.crc = 32'b00000000000000000000000000000000;
    UUT.gold_inst.out_crc = 32'b00000000000000000000000000000000;
    UUT.gold_inst.out_valid = 1'b0;

    // state 0
    PI_in_last = 1'b0;
    PI_in_bytes = 4'b0000;
    PI_in_valid = 1'b0;
    PI_rst = 1'b1;
    PI_in_data = 64'b0000000000000000000000000000000000000000000000000000000000000000;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_in_last <= 1'b1;
      PI_in_bytes <= 4'b1100;
      PI_in_valid <= 1'b1;
      PI_rst <= 1'b0;
      PI_in_data <= 64'b1101000010101100011100110110001110001000110011101001100010010110;
    end

    // state 2
    if (cycle == 1) begin
      PI_in_last <= 1'b0;
      PI_in_bytes <= 4'b0000;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
      PI_in_data <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end

    // state 3
    if (cycle == 2) begin
      PI_in_last <= 1'b0;
      PI_in_bytes <= 4'b0000;
      PI_in_valid <= 1'b0;
      PI_rst <= 1'b0;
      PI_in_data <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end

    genclock <= cycle < 3;
    cycle <= cycle + 1;
  end
endmodule
