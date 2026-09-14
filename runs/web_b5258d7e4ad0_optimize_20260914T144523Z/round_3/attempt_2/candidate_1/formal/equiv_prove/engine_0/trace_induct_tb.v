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
  reg [7:0] PI_in_data;
  reg [0:0] PI_in_valid;
  wire [0:0] PI_clk = clock;
  __eqcheck_top UUT (
    .rst(PI_rst),
    .in_data(PI_in_data),
    .in_valid(PI_in_valid),
    .clk(PI_clk)
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
    // UUT.$auto$async2sync.\cc:107:execute$139  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$143  = 1'b0;
    UUT.gate_inst.out_data = 19'b0000000000000000000;
    UUT.gate_inst.out_valid = 1'b0;
    UUT.gate_inst.p0_r = 19'b0000000000000000000;
    UUT.gate_inst.p1_r = 19'b0000000000000000000;
    UUT.gate_inst.p2_r = 19'b0000000000000000000;
    UUT.gate_inst.p3_r = 19'b0000000000000000000;
    UUT.gate_inst.p4_r = 19'b0000000000000000000;
    UUT.gate_inst.p5_r = 19'b0000000000000000000;
    UUT.gate_inst.t0 = 8'b01010100;
    UUT.gate_inst.t1 = 8'b01010011;
    UUT.gate_inst.t2 = 8'b10000001;
    UUT.gate_inst.t3 = 8'b01100000;
    UUT.gate_inst.t4 = 8'b11001111;
    UUT.gate_inst.t5 = 8'b01000000;
    UUT.gate_inst.vld = 1'b0;
    UUT.gate_inst.vld2 = 1'b0;
    UUT.gold_inst.out_data = 19'b0000000000000000000;
    UUT.gold_inst.out_valid = 1'b0;
    UUT.gold_inst.t0 = 8'b01111010;
    UUT.gold_inst.t1 = 8'b10111000;
    UUT.gold_inst.t2 = 8'b10000100;
    UUT.gold_inst.t3 = 8'b11111101;
    UUT.gold_inst.t4 = 8'b10000010;
    UUT.gold_inst.t5 = 8'b10010010;
    UUT.gold_inst.vld = 1'b0;
    UUT.gold_out_data_d1 = 19'b0000000000000000000;
    UUT.gold_out_valid_d1 = 1'b0;
    UUT.warmup = 8'b00010010;

    // state 0
    PI_rst = 1'b0;
    PI_in_data = 8'b00000000;
    PI_in_valid = 1'b0;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b00000000;
      PI_in_valid <= 1'b0;
    end

    // state 2
    if (cycle == 1) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b00000000;
      PI_in_valid <= 1'b0;
    end

    // state 3
    if (cycle == 2) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b00000000;
      PI_in_valid <= 1'b0;
    end

    // state 4
    if (cycle == 3) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b00000000;
      PI_in_valid <= 1'b0;
    end

    // state 5
    if (cycle == 4) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b00000000;
      PI_in_valid <= 1'b0;
    end

    // state 6
    if (cycle == 5) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b00000000;
      PI_in_valid <= 1'b0;
    end

    // state 7
    if (cycle == 6) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b00000000;
      PI_in_valid <= 1'b0;
    end

    // state 8
    if (cycle == 7) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b00000000;
      PI_in_valid <= 1'b0;
    end

    // state 9
    if (cycle == 8) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b00000000;
      PI_in_valid <= 1'b0;
    end

    // state 10
    if (cycle == 9) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b00000000;
      PI_in_valid <= 1'b0;
    end

    // state 11
    if (cycle == 10) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b00000000;
      PI_in_valid <= 1'b0;
    end

    // state 12
    if (cycle == 11) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b00000000;
      PI_in_valid <= 1'b0;
    end

    // state 13
    if (cycle == 12) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b00000000;
      PI_in_valid <= 1'b0;
    end

    // state 14
    if (cycle == 13) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b00000000;
      PI_in_valid <= 1'b0;
    end

    // state 15
    if (cycle == 14) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b00000000;
      PI_in_valid <= 1'b0;
    end

    // state 16
    if (cycle == 15) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b01010001;
      PI_in_valid <= 1'b1;
    end

    // state 17
    if (cycle == 16) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b00000000;
      PI_in_valid <= 1'b0;
    end

    // state 18
    if (cycle == 17) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b00000000;
      PI_in_valid <= 1'b0;
    end

    // state 19
    if (cycle == 18) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b00000000;
      PI_in_valid <= 1'b0;
    end

    // state 20
    if (cycle == 19) begin
      PI_rst <= 1'b0;
      PI_in_data <= 8'b00000000;
      PI_in_valid <= 1'b0;
    end

    genclock <= cycle < 20;
    cycle <= cycle + 1;
  end
endmodule
