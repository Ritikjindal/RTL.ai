// designs/benchmark_top.v — RTL.ai benchmark circuit.
//
// Structure required by the brief:
//   * 5 independent asynchronous master clock domains (clk_a..clk_e)
//   * >=1 generated clock per master (clk_?_div, divide ratios 2/4/6/8/10)
//   * clock domain crossings between every adjacent pair (ring A->B->C->D->E->A)
//   * ~50K standard cells of payload logic
//
// Design intent: every payload block is SINGLE-CLOCK with fully reset state, deep
// unpipelined arithmetic, and no stateful feedback. That is what makes each one both
// a valid target for RTL restructuring and formally provable in isolation. All CDC
// lives here in the top level and is never optimized -- an equivalence proof across a
// CDC boundary would not mean what it appears to mean, and a two-clock module cannot
// use latency-offset checking at all.
//
// Payload inputs are driven by per-domain LFSRs so synthesis cannot constant-fold the
// arithmetic away, and every output is reduced into a top-level port so none of it is
// dead logic.

`default_nettype wire

module benchmark_top (
    input  wire        clk_a,
    input  wire        clk_b,
    input  wire        clk_c,
    input  wire        clk_d,
    input  wire        clk_e,
    input  wire        rst_async,

    // Generated clocks exposed as ports so the SDC can constrain them by name rather
    // than by synthesis-generated net names, which change every run.
    output wire        clk_a_div,
    output wire        clk_b_div,
    output wire        clk_c_div,
    output wire        clk_d_div,
    output wire        clk_e_div,

    output wire [31:0] out_a,
    output wire [31:0] out_b,
    output wire [31:0] out_c,
    output wire [31:0] out_d,
    output wire [31:0] out_e
);

    // Instance counts per domain. Tune these to hit the ~50K cell target.
    localparam integer N_A = 10;  // mac_unit      : 4-lane 8x8 MAC
    localparam integer N_B = 11;  // bm_fir6       : 6-tap FIR, serial accumulate
    localparam integer N_C = 6;   // bm_dot4       : 4-element 12x12 dot product
    localparam integer N_D = 5;   // bm_mac8       : 8-lane MAC, serial add chain
    localparam integer N_E = 5;   // bm_fsm_ctrl : 16-state one-hot protocol FSM

    // ---------------------------------------------------------------- resets
    wire rst_a, rst_b, rst_c, rst_d, rst_e;

    reset_sync u_rs_a (.clk(clk_a), .rst_async(rst_async), .rst_sync(rst_a));
    reset_sync u_rs_b (.clk(clk_b), .rst_async(rst_async), .rst_sync(rst_b));
    reset_sync u_rs_c (.clk(clk_c), .rst_async(rst_async), .rst_sync(rst_c));
    reset_sync u_rs_d (.clk(clk_d), .rst_async(rst_async), .rst_sync(rst_d));
    reset_sync u_rs_e (.clk(clk_e), .rst_async(rst_async), .rst_sync(rst_e));

    // ----------------------------------------------------- reset replication
    // rst_? drives every flop in its domain -- over a thousand loads -- and Yosys
    // builds no buffer tree, so an un-replicated reset dominates the critical path
    // with several ns on a single inverter. One registered copy per payload instance
    // bounds the fanout. (* keep *) stops opt_merge collapsing the copies into one.
    (* keep = "true" *) reg [N_A-1:0] rst_a_rep;
    (* keep = "true" *) reg [N_B-1:0] rst_b_rep;
    (* keep = "true" *) reg [N_C-1:0] rst_c_rep;
    (* keep = "true" *) reg [N_D-1:0] rst_d_rep;
    (* keep = "true" *) reg [N_E-1:0] rst_e_rep;

    always @(posedge clk_a) rst_a_rep <= {N_A{rst_a}};
    always @(posedge clk_b) rst_b_rep <= {N_B{rst_b}};
    always @(posedge clk_c) rst_c_rep <= {N_C{rst_c}};
    always @(posedge clk_d) rst_d_rep <= {N_D{rst_d}};
    always @(posedge clk_e) rst_e_rep <= {N_E{rst_e}};

    // ------------------------------------------------------ generated clocks
    clk_divider #(.DIV(2))  u_div_a (.clk_in(clk_a), .rst(rst_a), .clk_out(clk_a_div));
    clk_divider #(.DIV(4))  u_div_b (.clk_in(clk_b), .rst(rst_b), .clk_out(clk_b_div));
    clk_divider #(.DIV(6))  u_div_c (.clk_in(clk_c), .rst(rst_c), .clk_out(clk_c_div));
    clk_divider #(.DIV(8))  u_div_d (.clk_in(clk_d), .rst(rst_d), .clk_out(clk_d_div));
    clk_divider #(.DIV(10)) u_div_e (.clk_in(clk_e), .rst(rst_e), .clk_out(clk_e_div));

    // ------------------------------------------------------- stimulus LFSRs
    reg [31:0] lfsr_a, lfsr_b, lfsr_c, lfsr_d, lfsr_e;

    always @(posedge clk_a)
        if (rst_a) lfsr_a <= 32'h0000_0001;
        else       lfsr_a <= {lfsr_a[30:0], lfsr_a[31]^lfsr_a[21]^lfsr_a[1]^lfsr_a[0]};

    always @(posedge clk_b)
        if (rst_b) lfsr_b <= 32'h1234_5678;
        else       lfsr_b <= {lfsr_b[30:0], lfsr_b[31]^lfsr_b[21]^lfsr_b[1]^lfsr_b[0]};

    always @(posedge clk_c)
        if (rst_c) lfsr_c <= 32'h9ABC_DEF0;
        else       lfsr_c <= {lfsr_c[30:0], lfsr_c[31]^lfsr_c[21]^lfsr_c[1]^lfsr_c[0]};

    always @(posedge clk_d)
        if (rst_d) lfsr_d <= 32'h0F0F_0F0F;
        else       lfsr_d <= {lfsr_d[30:0], lfsr_d[31]^lfsr_d[21]^lfsr_d[1]^lfsr_d[0]};

    always @(posedge clk_e)
        if (rst_e) lfsr_e <= 32'hDEAD_BEEF;
        else       lfsr_e <= {lfsr_e[30:0], lfsr_e[31]^lfsr_e[21]^lfsr_e[1]^lfsr_e[0]};

    genvar i;

    // ================================================ domain A: mac_unit x N_A
    wire [23:0] a_acc [0:N_A-1];

    generate
        for (i = 0; i < N_A; i = i + 1) begin : g_mac_unit
            mac_unit u_mac (
                .clk       (clk_a),
                .rst       (rst_a_rep[i]),
                .valid     (lfsr_a[0]),
                .a_vec     (lfsr_a ^ (i * 32'h0101_0101)),
                .b_vec     ({lfsr_a[15:0], lfsr_a[31:16]} ^ (i * 32'h0000_1111)),
                .acc       (a_acc[i]),
                .acc_valid ()
            );
        end
    endgenerate

    // ================================================= domain B: bm_fir6 x N_B
    wire [18:0] b_out [0:N_B-1];

    generate
        for (i = 0; i < N_B; i = i + 1) begin : g_fir6
            bm_fir6 u_fir (
                .clk       (clk_b),
                .rst       (rst_b_rep[i]),
                .in_valid  (lfsr_b[1]),
                .in_data   (lfsr_b[7:0] ^ (8'd17 * i)),
                .out_valid (),
                .out_data  (b_out[i])
            );
        end
    endgenerate

    // ================================================= domain C: bm_dot4 x N_C
    wire [27:0] c_acc [0:N_C-1];

    generate
        for (i = 0; i < N_C; i = i + 1) begin : g_dot4
            bm_dot4 u_dot (
                .clk       (clk_c),
                .rst       (rst_c_rep[i]),
                .in_valid  (lfsr_c[2]),
                .a_vec     ({lfsr_c[15:0], lfsr_c ^ (i * 32'h0002_0002)}),
                .b_vec     ({lfsr_c[31:16], lfsr_c ^ (i * 32'h0030_0030)}),
                .out_valid (),
                .acc       (c_acc[i])
            );
        end
    endgenerate

    // ================================================= domain D: bm_mac8 x N_D
    wire [20:0] d_acc [0:N_D-1];

    generate
        for (i = 0; i < N_D; i = i + 1) begin : g_mac8
            bm_mac8 u_mac8 (
                .clk       (clk_d),
                .rst       (rst_d_rep[i]),
                .in_valid  (lfsr_d[3]),
                .a_vec     ({lfsr_d, lfsr_d ^ (i * 32'h0404_0404)}),
                .b_vec     ({lfsr_d ^ 32'hFFFF_0000, lfsr_d ^ (i * 32'h0055_0055)}),
                .out_valid (),
                .acc       (d_acc[i])
            );
        end
    endgenerate

    // ============================================ domain E: bm_fsm_ctrl x N_E
    wire [23:0] e_out [0:N_E-1];

    generate
        for (i = 0; i < N_E; i = i + 1) begin : g_fsm
            bm_fsm_ctrl u_fsm (
                .clk       (clk_e),
                .rst       (rst_e_rep[i]),
                .in_valid  (lfsr_e[4]),
                .in_data   (lfsr_e[15:0] ^ (16'd7 * i)),
                .cmd       (lfsr_e[19:16]),
                .out_valid (),
                .out_data  (e_out[i]),
                .status    ()
            );
        end
    endgenerate

    // ------------------------------------------------- per-domain reductions
    // XOR-reduce each domain's payload outputs. Written as loops so the instance
    // counts above can be changed without editing any expressions here.
    integer k;

    reg [23:0] a_red_r;
    reg [18:0] b_red_r;
    reg [27:0] c_red_r;
    reg [20:0] d_red_r;
    reg [23:0] e_red_r;

    always @* begin
        a_red_r = 24'd0;
        for (k = 0; k < N_A; k = k + 1) a_red_r = a_red_r ^ a_acc[k];
    end

    always @* begin
        b_red_r = 19'd0;
        for (k = 0; k < N_B; k = k + 1) b_red_r = b_red_r ^ b_out[k];
    end

    always @* begin
        c_red_r = 28'd0;
        for (k = 0; k < N_C; k = k + 1) c_red_r = c_red_r ^ c_acc[k];
    end

    always @* begin
        d_red_r = 21'd0;
        for (k = 0; k < N_D; k = k + 1) d_red_r = d_red_r ^ d_acc[k];
    end

    always @* begin
        e_red_r = 24'd0;
        for (k = 0; k < N_E; k = k + 1) e_red_r = e_red_r ^ e_out[k];
    end

    wire [23:0] a_red = a_red_r;
    wire [18:0] b_red = b_red_r;
    wire [27:0] c_red = c_red_r;
    wire [20:0] d_red = d_red_r;
    wire [23:0] e_red = e_red_r;

    // ---------------------------------------------- divided-clock accumulators
    // Every generated clock drives real logic, so none of the five is dangling.
    reg [15:0] dcnt_a, dcnt_b, dcnt_c, dcnt_d, dcnt_e;

    always @(posedge clk_a_div) if (rst_a) dcnt_a <= 16'd0; else dcnt_a <= dcnt_a + a_red[15:0];
    always @(posedge clk_b_div) if (rst_b) dcnt_b <= 16'd0; else dcnt_b <= dcnt_b + b_red[15:0];
    always @(posedge clk_c_div) if (rst_c) dcnt_c <= 16'd0; else dcnt_c <= dcnt_c + c_red[15:0];
    always @(posedge clk_d_div) if (rst_d) dcnt_d <= 16'd0; else dcnt_d <= dcnt_d + d_red[15:0];
    always @(posedge clk_e_div) if (rst_e) dcnt_e <= 16'd0; else dcnt_e <= dcnt_e + e_red[15:0];

    // ------------------------------------------------------------------- CDC
    // Ring of data crossings A->B->C->D->E->A, each a four-phase req/ack handshake
    // with the data held stable for the whole transfer.
    wire [15:0] x_ab, x_bc, x_cd, x_de, x_ea;
    wire        v_ab, v_bc, v_cd, v_de, v_ea;
    wire        busy_ab, busy_bc, busy_cd, busy_de, busy_ea;

    reg send_ab, send_bc, send_cd, send_de, send_ea;

    always @(posedge clk_a) if (rst_a) send_ab <= 1'b0; else send_ab <= ~busy_ab;
    always @(posedge clk_b) if (rst_b) send_bc <= 1'b0; else send_bc <= ~busy_bc;
    always @(posedge clk_c) if (rst_c) send_cd <= 1'b0; else send_cd <= ~busy_cd;
    always @(posedge clk_d) if (rst_d) send_de <= 1'b0; else send_de <= ~busy_de;
    always @(posedge clk_e) if (rst_e) send_ea <= 1'b0; else send_ea <= ~busy_ea;

    cdc_handshake #(.WIDTH(16)) u_cdc_ab (
        .clk_src(clk_a), .clk_dst(clk_b), .rst_src(rst_a), .rst_dst(rst_b),
        .send(send_ab), .data_in(a_red[15:0]), .busy(busy_ab),
        .data_out(x_ab), .data_valid(v_ab));

    cdc_handshake #(.WIDTH(16)) u_cdc_bc (
        .clk_src(clk_b), .clk_dst(clk_c), .rst_src(rst_b), .rst_dst(rst_c),
        .send(send_bc), .data_in(b_red[15:0]), .busy(busy_bc),
        .data_out(x_bc), .data_valid(v_bc));

    cdc_handshake #(.WIDTH(16)) u_cdc_cd (
        .clk_src(clk_c), .clk_dst(clk_d), .rst_src(rst_c), .rst_dst(rst_d),
        .send(send_cd), .data_in(c_red[15:0]), .busy(busy_cd),
        .data_out(x_cd), .data_valid(v_cd));

    cdc_handshake #(.WIDTH(16)) u_cdc_de (
        .clk_src(clk_d), .clk_dst(clk_e), .rst_src(rst_d), .rst_dst(rst_e),
        .send(send_de), .data_in(d_red[15:0]), .busy(busy_de),
        .data_out(x_de), .data_valid(v_de));

    cdc_handshake #(.WIDTH(16)) u_cdc_ea (
        .clk_src(clk_e), .clk_dst(clk_a), .rst_src(rst_e), .rst_dst(rst_a),
        .send(send_ea), .data_in(e_red[15:0]), .busy(busy_ea),
        .data_out(x_ea), .data_valid(v_ea));

    // Single-bit control crossings, two-flop synchronizers.
    wire s_ab, s_bc, s_cd, s_de, s_ea;

    cdc_sync u_s_ab (.clk_dst(clk_b), .rst(rst_b), .sig_src(lfsr_a[31]), .sig_dst(s_ab));
    cdc_sync u_s_bc (.clk_dst(clk_c), .rst(rst_c), .sig_src(lfsr_b[31]), .sig_dst(s_bc));
    cdc_sync u_s_cd (.clk_dst(clk_d), .rst(rst_d), .sig_src(lfsr_c[31]), .sig_dst(s_cd));
    cdc_sync u_s_de (.clk_dst(clk_e), .rst(rst_e), .sig_src(lfsr_d[31]), .sig_dst(s_de));
    cdc_sync u_s_ea (.clk_dst(clk_a), .rst(rst_a), .sig_src(lfsr_e[31]), .sig_dst(s_ea));

    // CDC receive registers. Without these nothing reads the handshake outputs and
    // Yosys deletes the crossings as dead logic.
    reg [15:0] rx_a, rx_b, rx_c, rx_d, rx_e;

    always @(posedge clk_a) if (rst_a) rx_a <= 16'd0; else if (v_ea) rx_a <= x_ea;
    always @(posedge clk_b) if (rst_b) rx_b <= 16'd0; else if (v_ab) rx_b <= x_ab;
    always @(posedge clk_c) if (rst_c) rx_c <= 16'd0; else if (v_bc) rx_c <= x_bc;
    always @(posedge clk_d) if (rst_d) rx_d <= 16'd0; else if (v_cd) rx_d <= x_cd;
    always @(posedge clk_e) if (rst_e) rx_e <= 16'd0; else if (v_de) rx_e <= x_de;

    // --------------------------------------------------------------- outputs
    assign out_a = {7'd0, s_ea, dcnt_a} ^ {8'd0,  a_red} ^ {16'd0, rx_a};
    assign out_b = {7'd0, s_ab, dcnt_b} ^ {13'd0, b_red} ^ {16'd0, rx_b};
    assign out_c = {7'd0, s_bc, dcnt_c} ^ {4'd0,  c_red} ^ {16'd0, rx_c};
    assign out_d = {7'd0, s_cd, dcnt_d} ^ {11'd0, d_red} ^ {16'd0, rx_d};
    assign out_e = {7'd0, s_de, dcnt_e} ^ {8'd0,  e_red} ^ {16'd0, rx_e};

endmodule