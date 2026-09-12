// RTL.ai benchmark circuit.
//
// Five independent asynchronous master clock domains. Each domain has:
//   - a reset synchronizer (async assert, sync de-assert)
//   - one generated clock from a divider, at a different ratio per domain
//   - a real payload block (LogikBench, MIT - see LICENSE.* in this directory)
//   - a capture register on the GENERATED clock
// Domains are joined in a ring by four-phase CDC handshakes, each crossing from
// one domain's generated clock into the next domain's master clock.
//
//   Domain  Payload    Standalone cells  Depth   Master   Divider
//   A       picorv32   18642             68      clk_a    /2
//   B       ddc        11844             37      clk_b    /4
//   C       sha256     10742             50      clk_c    /6
//   D       sad8x8      7610             39      clk_d    /8
//   E       crc32       1247             35      clk_e    /10
//
// Block inputs are driven from the incoming CDC data rather than tied to
// constants. Constant inputs let synthesis delete everything downstream that can
// no longer change, which silently shrinks the benchmark.
//
// Note: within a domain, the master and its divided clock are synchronous, so
// transfers between them are plain registers, not synchronizers. Only the
// domain-to-domain crossings are asynchronous and use handshakes.
`default_nettype wire
module benchmark_top (
    input  wire        clk_a,
    input  wire        clk_b,
    input  wire        clk_c,
    input  wire        clk_d,
    input  wire        clk_e,
    input  wire        rst_async,
    input  wire [15:0] stim,

    output wire [15:0] status_a,
    output wire [15:0] status_b,
    output wire [15:0] status_c,
    output wire [15:0] status_d,
    output wire [15:0] status_e,

    // Generated clocks brought to the top level so they can be constrained by a
    // stable name. Synthesis-generated internal instance names change whenever
    // the RTL changes, which would break the SDC on every optimization pass.
    output wire        clk_a_div,
    output wire        clk_b_div,
    output wire        clk_c_div,
    output wire        clk_d_div,
    output wire        clk_e_div
);

    // ---------------- reset synchronizers, one per domain ----------------
    wire rst_a, rst_b, rst_c, rst_d, rst_e;
    reset_sync u_rs_a (.clk(clk_a), .rst_async(rst_async), .rst_sync(rst_a));
    reset_sync u_rs_b (.clk(clk_b), .rst_async(rst_async), .rst_sync(rst_b));
    reset_sync u_rs_c (.clk(clk_c), .rst_async(rst_async), .rst_sync(rst_c));
    reset_sync u_rs_d (.clk(clk_d), .rst_async(rst_async), .rst_sync(rst_d));
    reset_sync u_rs_e (.clk(clk_e), .rst_async(rst_async), .rst_sync(rst_e));

    // ---------------- generated clocks ----------------
    clk_divider #(.DIV(2))  u_div_a (.clk_in(clk_a), .rst(rst_a), .clk_out(clk_a_div));
    clk_divider #(.DIV(4))  u_div_b (.clk_in(clk_b), .rst(rst_b), .clk_out(clk_b_div));
    clk_divider #(.DIV(6))  u_div_c (.clk_in(clk_c), .rst(rst_c), .clk_out(clk_c_div));
    clk_divider #(.DIV(8))  u_div_d (.clk_in(clk_d), .rst(rst_d), .clk_out(clk_d_div));
    clk_divider #(.DIV(10)) u_div_e (.clk_in(clk_e), .rst(rst_e), .clk_out(clk_e_div));

    // ---------------- inter-domain data ----------------
    wire [15:0] din_a, din_b, din_c, din_d, din_e;   // arriving from previous domain
    wire        dv_a,  dv_b,  dv_c,  dv_d,  dv_e;
    reg  [15:0] cap_a, cap_b, cap_c, cap_d, cap_e;   // captured on the DIVIDED clock
    wire [15:0] out_a, out_b, out_c, out_d, out_e;   // payload results

    assign status_a = cap_a;
    assign status_b = cap_b;
    assign status_c = cap_c;
    assign status_d = cap_d;
    assign status_e = cap_e;

    // ================= Domain A : picorv32 =================
    wire        cpu_mem_instr;
    wire [3:0]  cpu_mem_wstrb;
    wire        cpu_la_read, cpu_la_write;
    wire [31:0] cpu_la_addr, cpu_la_wdata;
    wire [3:0]  cpu_la_wstrb;
    wire        cpu_pcpi_valid;
    wire [31:0] cpu_pcpi_insn, cpu_pcpi_rs1, cpu_pcpi_rs2;
    wire [31:0] cpu_eoi;
    wire        cpu_trap;
    wire        cpu_mem_valid;
    wire [31:0] cpu_mem_addr;
    wire [31:0] cpu_mem_wdata;
    picorv32 u_cpu (
        .clk        (clk_a),
        .resetn     (~rst_a),
        .trap       (cpu_trap),
        .mem_valid  (cpu_mem_valid),
        .mem_instr  (cpu_mem_instr),
        .mem_ready  (din_a[0]),
        .mem_addr   (cpu_mem_addr),
        .mem_wdata  (cpu_mem_wdata),
        .mem_wstrb  (cpu_mem_wstrb),
        .mem_rdata  ({din_a, din_a}),
        .mem_la_read (cpu_la_read), .mem_la_write (cpu_la_write),
        .mem_la_addr (cpu_la_addr), .mem_la_wdata (cpu_la_wdata),
        .mem_la_wstrb (cpu_la_wstrb),
        .pcpi_valid (cpu_pcpi_valid), .pcpi_insn (cpu_pcpi_insn),
        .pcpi_rs1   (cpu_pcpi_rs1),   .pcpi_rs2   (cpu_pcpi_rs2),
        .pcpi_wr    (din_a[1]),
        .pcpi_rd    ({din_a, din_a}),
        .pcpi_wait  (din_a[2]),
        .pcpi_ready (din_a[3]),
        .irq        ({16'd0, din_a}),
        .eoi        (cpu_eoi)
    );

    // Fold every output into the result so none of them is dangling - an
    // unconnected output lets synthesis delete all the logic that drives it.
    assign out_a = cpu_mem_addr[15:0] ^ cpu_mem_wdata[15:0]
                 ^ cpu_la_addr[15:0]  ^ cpu_la_wdata[15:0]
                 ^ cpu_pcpi_insn[15:0] ^ cpu_pcpi_rs1[15:0] ^ cpu_pcpi_rs2[15:0]
                 ^ cpu_eoi[15:0]
                 ^ {8'd0, cpu_mem_wstrb, cpu_la_wstrb}
                 ^ {12'd0, cpu_trap, cpu_mem_instr, cpu_la_read, cpu_la_write}
                 ^ {15'd0, cpu_pcpi_valid};
    always @(posedge clk_a_div) begin
        if (rst_a) cap_a <= 16'd0;
        else       cap_a <= out_a;
    end

    // ================= Domain B : ddc =================
    wire signed [15:0] ddc_i, ddc_q;
    wire               ddc_ov;

    ddc u_ddc (
        .clk       (clk_b),
        .rst       (rst_b),
        .in_valid  (din_b[0]),
        .ftw       ({8'd0, din_b}),
        .in_data   (din_b),
        .out_valid (ddc_ov),
        .iout      (ddc_i),
        .qout      (ddc_q)
    );
    assign out_b = ddc_i ^ ddc_q;

    always @(posedge clk_b_div) begin
        if (rst_b) cap_b <= 16'd0;
        else       cap_b <= out_b;
    end

    // ================= Domain C : sha256 (active-low reset) =================
    wire [31:0] sha_rdata;
    wire        sha_error;

    sha256 u_sha (
        .clk        (clk_c),
        .reset_n    (~rst_c),
        .cs         (din_c[1]),
        .we         (din_c[0]),
        .address    (din_c[7:0]),
        .write_data ({16'd0, din_c}),
        .read_data  (sha_rdata),
        .error      (sha_error)
    );
    assign out_c = sha_rdata[15:0] ^ {15'd0, sha_error};

    always @(posedge clk_c_div) begin
        if (rst_c) cap_c <= 16'd0;
        else       cap_c <= out_c;
    end

    // ================= Domain D : sad8x8 =================
    wire [13:0] sad_val;
    wire        sad_ov;

    sad8x8 u_sad (
        .clk       (clk_d),
        .rst       (rst_d),
        .valid_in  (din_d[0]),
        .curblk    ({32{din_d}}),          // 32 x 16 = 512 bits
        .refblk    ({32{~din_d}}),
        .valid_out (sad_ov),
        .sad       (sad_val)
    );
    assign out_d = {1'b0, sad_ov, sad_val};

    always @(posedge clk_d_div) begin
        if (rst_d) cap_d <= 16'd0;
        else       cap_d <= out_d;
    end

    // ================= Domain E : crc32 =================
    wire        crc_ov;
    wire [31:0] crc_val;
    reg  [3:0]  crc_cnt;
    // Second DDC channel in this domain. Multi-channel instantiation of the same
    // IP is standard in real SoCs, and it balances domain E, which otherwise
    // holds only crc32.
    wire signed [15:0] ddc2_i, ddc2_q;
    wire               ddc2_ov;

    ddc u_ddc2 (
        .clk       (clk_e),
        .rst       (rst_e),
        .in_valid  (din_e[1]),
        .ftw       ({8'd0, din_e}),
        .in_data   (din_e),
        .out_valid (ddc2_ov),
        .iout      (ddc2_i),
        .qout      (ddc2_q)
    );
    always @(posedge clk_e) begin
        if (rst_e) crc_cnt <= 4'd0;
        else       crc_cnt <= crc_cnt + 4'd1;
    end

    crc32 u_crc (
        .clk       (clk_e),
        .rst       (rst_e),
        .in_valid  (din_e[0]),
        .in_data   ({4{din_e}}),           // 4 x 16 = 64 bits
        .in_last   (&crc_cnt),
        .in_bytes  (4'd8),
        .out_valid (crc_ov),
        .out_crc   (crc_val)
    );
    assign out_e = crc_val[15:0] ^ {15'd0, crc_ov}
                 ^ ddc2_i ^ ddc2_q ^ {15'd0, ddc2_ov};

    always @(posedge clk_e_div) begin
        if (rst_e) cap_e <= 16'd0;
        else       cap_e <= out_e;
    end

    // ================= CDC ring: A -> B -> C -> D -> E -> A =================
    // Each crossing goes from one domain's GENERATED clock into the next
    // domain's MASTER clock - a genuinely asynchronous crossing.

    cdc_handshake #(.WIDTH(16)) u_cdc_ab (
        .clk_src (clk_a_div), .clk_dst (clk_b),
        .rst_src (rst_a),     .rst_dst (rst_b),
        .send (1'b1), .data_in (cap_a), .busy (),
        .data_out (din_b), .data_valid (dv_b)
    );

    cdc_handshake #(.WIDTH(16)) u_cdc_bc (
        .clk_src (clk_b_div), .clk_dst (clk_c),
        .rst_src (rst_b),     .rst_dst (rst_c),
        .send (1'b1), .data_in (cap_b), .busy (),
        .data_out (din_c), .data_valid (dv_c)
    );

    cdc_handshake #(.WIDTH(16)) u_cdc_cd (
        .clk_src (clk_c_div), .clk_dst (clk_d),
        .rst_src (rst_c),     .rst_dst (rst_d),
        .send (1'b1), .data_in (cap_c), .busy (),
        .data_out (din_d), .data_valid (dv_d)
    );

    cdc_handshake #(.WIDTH(16)) u_cdc_de (
        .clk_src (clk_d_div), .clk_dst (clk_e),
        .rst_src (rst_d),     .rst_dst (rst_e),
        .send (1'b1), .data_in (cap_d), .busy (),
        .data_out (din_e), .data_valid (dv_e)
    );

    cdc_handshake #(.WIDTH(16)) u_cdc_ea (
        .clk_src (clk_e_div), .clk_dst (clk_a),
        .rst_src (rst_e),     .rst_dst (rst_a),
        .send (1'b1), .data_in (cap_e ^ stim), .busy (),
        .data_out (din_a), .data_valid (dv_a)
    );

endmodule