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
  reg [0:0] PI_we;
  reg [0:0] PI_reset_n;
  reg [0:0] PI_cs;
  reg [7:0] PI_address;
  reg [31:0] PI_write_data;
  __eqcheck_top UUT (
    .clk(PI_clk),
    .we(PI_we),
    .reset_n(PI_reset_n),
    .cs(PI_cs),
    .address(PI_address),
    .write_data(PI_write_data)
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
    // UUT.$auto$async2sync.\cc:107:execute$2317  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$2321  = 1'b0;
    UUT.gate_inst._witness_.anyinit_procdff_2024 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2029 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2034 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2039 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2044 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2049 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2054 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2059 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2064 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2069 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2074 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2079 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2084 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2089 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2094 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2099 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2104 = 1'b0;
    UUT.gate_inst._witness_.anyinit_procdff_2109 = 256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2114 = 1'b0;
    UUT.gate_inst._witness_.anyinit_procdff_2119 = 1'b1;
    UUT.gate_inst._witness_.anyinit_procdff_2124 = 1'b0;
    UUT.gate_inst._witness_.anyinit_procdff_2129 = 1'b0;
    UUT.gate_inst._witness_.anyinit_procdff_2134 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2139 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2144 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2149 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2154 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2159 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2164 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2169 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2174 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2179 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2184 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2189 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2194 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2199 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2204 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2209 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2214 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2219 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2224 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2229 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2234 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2239 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2244 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2249 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2254 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2259 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2264 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2269 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2274 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2279 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2284 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2289 = 32'b00000000000000000000000000000000;
    UUT.gate_inst._witness_.anyinit_procdff_2294 = 6'b101110;
    UUT.gate_inst._witness_.anyinit_procdff_2299 = 2'b01;
    UUT.gate_inst._witness_.anyinit_procdff_2304 = 1'b1;
    UUT.gold_inst._witness_.anyinit_procdff_1739 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1744 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1749 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1754 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1759 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1764 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1769 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1774 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1779 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1784 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1789 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1794 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1799 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1804 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1809 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1814 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1819 = 1'b0;
    UUT.gold_inst._witness_.anyinit_procdff_1824 = 256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1829 = 1'b0;
    UUT.gold_inst._witness_.anyinit_procdff_1834 = 1'b1;
    UUT.gold_inst._witness_.anyinit_procdff_1839 = 1'b0;
    UUT.gold_inst._witness_.anyinit_procdff_1844 = 1'b0;
    UUT.gold_inst._witness_.anyinit_procdff_1849 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1854 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1859 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1864 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1869 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1874 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1879 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1884 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1889 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1894 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1899 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1904 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1909 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1914 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1919 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1924 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1929 = 2'b01;
    UUT.gold_inst._witness_.anyinit_procdff_1934 = 6'b101110;
    UUT.gold_inst._witness_.anyinit_procdff_1939 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1944 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1949 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1954 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1959 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1964 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1969 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1974 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1979 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1984 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1989 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1994 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_1999 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_2004 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_2009 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_2014 = 32'b00000000000000000000000000000000;
    UUT.gold_inst._witness_.anyinit_procdff_2019 = 1'b0;
    UUT.gate_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$1601 [6'b101110] = 32'b00000000000000000000000000000000;
    UUT.gate_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$1601 [6'b101111] = 32'b00000000000000000000000000000000;
    UUT.gate_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$1601 [6'b110000] = 32'b00000000000000000000000000000000;
    UUT.gate_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$1601 [6'b110001] = 32'b00000000000000000000000000000000;
    UUT.gate_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$1601 [6'b110010] = 32'b00000000000000000000000000000000;
    UUT.gate_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$1601 [6'b110011] = 32'b00000000000000000000000000000000;
    UUT.gate_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$1601 [6'b110100] = 32'b00000000000000000000000000000000;
    UUT.gate_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$1601 [6'b110101] = 32'b00000000000000000000000000000000;
    UUT.gate_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$1601 [6'b110110] = 32'b00000000000000000000000000000000;
    UUT.gate_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$1601 [6'b110111] = 32'b00000000000000000000000000000000;
    UUT.gate_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$1601 [6'b111000] = 32'b00000000000000000000000000000000;
    UUT.gate_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$1601 [6'b111001] = 32'b00000000000000000000000000000000;
    UUT.gate_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$1601 [6'b111010] = 32'b00000000000000000000000000000000;
    UUT.gate_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$1601 [6'b111011] = 32'b00000000000000000000000000000000;
    UUT.gate_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$1601 [6'b111100] = 32'b00000000000000000000000000000000;
    UUT.gate_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$1601 [6'b111101] = 32'b00000000000000000000000000000000;
    UUT.gate_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$1601 [6'b111110] = 32'b00000000000000000000000000000000;
    UUT.gate_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$1601 [6'b111111] = 32'b00000000000000000000000000000000;
    UUT.gate_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$1601 [6'b000000] = 32'b00000000000000000000000000000000;
    UUT.gold_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$98 [6'b101110] = 32'b00000000000000000000000000000000;
    UUT.gold_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$98 [6'b101111] = 32'b00000000000000000000000000000000;
    UUT.gold_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$98 [6'b110000] = 32'b00000000000000000000000000000000;
    UUT.gold_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$98 [6'b110001] = 32'b00000000000000000000000000000000;
    UUT.gold_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$98 [6'b110010] = 32'b00000000000000000000000000000000;
    UUT.gold_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$98 [6'b110011] = 32'b00000000000000000000000000000000;
    UUT.gold_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$98 [6'b110100] = 32'b00000000000000000000000000000000;
    UUT.gold_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$98 [6'b110101] = 32'b00000000000000000000000000000000;
    UUT.gold_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$98 [6'b110110] = 32'b00000000000000000000000000000000;
    UUT.gold_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$98 [6'b110111] = 32'b00000000000000000000000000000000;
    UUT.gold_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$98 [6'b111000] = 32'b00000000000000000000000000000000;
    UUT.gold_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$98 [6'b111001] = 32'b00000000000000000000000000000000;
    UUT.gold_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$98 [6'b111010] = 32'b00000000000000000000000000000000;
    UUT.gold_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$98 [6'b111011] = 32'b00000000000000000000000000000000;
    UUT.gold_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$98 [6'b111100] = 32'b00000000000000000000000000000000;
    UUT.gold_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$98 [6'b111101] = 32'b00000000000000000000000000000000;
    UUT.gold_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$98 [6'b111110] = 32'b00000000000000000000000000000000;
    UUT.gold_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$98 [6'b111111] = 32'b00000000000000000000000000000001;
    UUT.gold_inst.\/$flatten/core .\/k_constants_inst .$auto$proc_rom.\cc:155:do_switch$98 [6'b000000] = 32'b00000000000000000000000000000001;

    // state 0
    PI_we = 1'b0;
    PI_reset_n = 1'b1;
    PI_cs = 1'b0;
    PI_address = 8'b00000000;
    PI_write_data = 32'b00000000000000000000000000000000;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b1;
      PI_cs <= 1'b0;
      PI_address <= 8'b00000000;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    // state 2
    if (cycle == 1) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b1;
      PI_cs <= 1'b0;
      PI_address <= 8'b00000000;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    // state 3
    if (cycle == 2) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b1;
      PI_cs <= 1'b0;
      PI_address <= 8'b00000000;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    // state 4
    if (cycle == 3) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b1;
      PI_cs <= 1'b0;
      PI_address <= 8'b00000000;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    // state 5
    if (cycle == 4) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b1;
      PI_cs <= 1'b0;
      PI_address <= 8'b00000000;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    // state 6
    if (cycle == 5) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b1;
      PI_cs <= 1'b0;
      PI_address <= 8'b00000000;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    // state 7
    if (cycle == 6) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b1;
      PI_cs <= 1'b0;
      PI_address <= 8'b00000000;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    // state 8
    if (cycle == 7) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b1;
      PI_cs <= 1'b0;
      PI_address <= 8'b00000000;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    // state 9
    if (cycle == 8) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b1;
      PI_cs <= 1'b0;
      PI_address <= 8'b00000000;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    // state 10
    if (cycle == 9) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b1;
      PI_cs <= 1'b0;
      PI_address <= 8'b00000000;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    // state 11
    if (cycle == 10) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b1;
      PI_cs <= 1'b0;
      PI_address <= 8'b00000000;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    // state 12
    if (cycle == 11) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b1;
      PI_cs <= 1'b0;
      PI_address <= 8'b00000000;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    // state 13
    if (cycle == 12) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b1;
      PI_cs <= 1'b0;
      PI_address <= 8'b00000000;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    // state 14
    if (cycle == 13) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b1;
      PI_cs <= 1'b0;
      PI_address <= 8'b00000000;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    // state 15
    if (cycle == 14) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b1;
      PI_cs <= 1'b0;
      PI_address <= 8'b00000000;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    // state 16
    if (cycle == 15) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b1;
      PI_cs <= 1'b0;
      PI_address <= 8'b00000000;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    // state 17
    if (cycle == 16) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b1;
      PI_cs <= 1'b0;
      PI_address <= 8'b00000000;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    // state 18
    if (cycle == 17) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b1;
      PI_cs <= 1'b0;
      PI_address <= 8'b00000000;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    // state 19
    if (cycle == 18) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b1;
      PI_cs <= 1'b1;
      PI_address <= 8'b00001001;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    // state 20
    if (cycle == 19) begin
      PI_we <= 1'b0;
      PI_reset_n <= 1'b0;
      PI_cs <= 1'b0;
      PI_address <= 8'b00000000;
      PI_write_data <= 32'b00000000000000000000000000000000;
    end

    genclock <= cycle < 20;
    cycle <= cycle + 1;
  end
endmodule
