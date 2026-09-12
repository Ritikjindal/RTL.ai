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
  __eqcheck_top UUT (
    .in_valid(PI_in_valid),
    .in_data(PI_in_data),
    .rst(PI_rst),
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
    // UUT.$auto$async2sync.\cc:107:execute$243  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$247  = 1'b1;
    UUT.gate_inst.out_data = 16'b0000000000000000;
    UUT.gate_inst.out_valid = 1'b0;
    UUT.gate_inst.partial_sum_reg_A = 36'b000000000000000000000000000000000000;
    UUT.gate_inst.partial_sum_reg_B = 36'b000000000000000000000000000000000000;
    UUT.gate_inst.\shift[0]  = 16'b0000000000000000;
    UUT.gate_inst.\shift[1]  = 16'b0000000000000000;
    UUT.gate_inst.\shift[2]  = 16'b0000000000000000;
    UUT.gate_inst.\shift[3]  = 16'b0000000000000000;
    UUT.gate_inst.\shift[4]  = 16'b0000000000000000;
    UUT.gate_inst.\shift[5]  = 16'b0000000000000000;
    UUT.gate_inst.\shift[6]  = 16'b0000000000000000;
    UUT.gate_inst.\shift[7]  = 16'b0000000000000000;
    UUT.gate_inst.valid_pipe1 = 1'b0;
    UUT.gold_inst.out_data = 16'b1000000000000000;
    UUT.gold_inst.out_valid = 1'b0;
    UUT.gold_inst.\shift[0]  = 16'b0000000000000000;
    UUT.gold_inst.\shift[1]  = 16'b0000000000000000;
    UUT.gold_inst.\shift[2]  = 16'b0000000000000000;
    UUT.gold_inst.\shift[3]  = 16'b0000000000000000;
    UUT.gold_inst.\shift[4]  = 16'b0000000000000000;
    UUT.gold_inst.\shift[5]  = 16'b0000000000000000;
    UUT.gold_inst.\shift[6]  = 16'b0000000000000000;
    UUT.gold_inst.\shift[7]  = 16'b0000000000000000;
    UUT.gold_out_data_d1 = 16'b1000000000000000;
    UUT.gold_out_valid_d1 = 1'b1;
    UUT.warmup = 8'b00000000;

    // state 0
    PI_in_valid = 1'b0;
    PI_in_data = 16'b0000000000000000;
    PI_rst = 1'b1;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_in_valid <= 1'b1;
      PI_in_data <= 16'b1010111010010101;
      PI_rst <= 1'b0;
    end

    // state 2
    if (cycle == 1) begin
      PI_in_valid <= 1'b1;
      PI_in_data <= 16'b0000000000000000;
      PI_rst <= 1'b0;
    end

    // state 3
    if (cycle == 2) begin
      PI_in_valid <= 1'b1;
      PI_in_data <= 16'b0000000000000000;
      PI_rst <= 1'b0;
    end

    // state 4
    if (cycle == 3) begin
      PI_in_valid <= 1'b1;
      PI_in_data <= 16'b0000000000000000;
      PI_rst <= 1'b0;
    end

    // state 5
    if (cycle == 4) begin
      PI_in_valid <= 1'b1;
      PI_in_data <= 16'b0000000000000000;
      PI_rst <= 1'b0;
    end

    // state 6
    if (cycle == 5) begin
      PI_in_valid <= 1'b1;
      PI_in_data <= 16'b0000000000000000;
      PI_rst <= 1'b0;
    end

    // state 7
    if (cycle == 6) begin
      PI_in_valid <= 1'b1;
      PI_in_data <= 16'b0000000000000000;
      PI_rst <= 1'b0;
    end

    // state 8
    if (cycle == 7) begin
      PI_in_valid <= 1'b1;
      PI_in_data <= 16'b0000000000000000;
      PI_rst <= 1'b0;
    end

    // state 9
    if (cycle == 8) begin
      PI_in_valid <= 1'b0;
      PI_in_data <= 16'b0000000000000000;
      PI_rst <= 1'b0;
    end

    // state 10
    if (cycle == 9) begin
      PI_in_valid <= 1'b0;
      PI_in_data <= 16'b0000000000000000;
      PI_rst <= 1'b0;
    end

    // state 11
    if (cycle == 10) begin
      PI_in_valid <= 1'b0;
      PI_in_data <= 16'b0000000000000000;
      PI_rst <= 1'b0;
    end

    // state 12
    if (cycle == 11) begin
      PI_in_valid <= 1'b0;
      PI_in_data <= 16'b0000000000000000;
      PI_rst <= 1'b0;
    end

    genclock <= cycle < 12;
    cycle <= cycle + 1;
  end
endmodule
