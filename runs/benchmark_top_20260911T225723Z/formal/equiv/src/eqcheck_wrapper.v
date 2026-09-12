module __eqcheck_top (
    input wire clk_a,
    input wire clk_b,
    input wire clk_c,
    input wire clk_d,
    input wire clk_e,
    input wire rst_async,
    input wire [15:0] stim
);

    wire [15:0] gold_status_a;
    wire [15:0] gate_status_a;
    wire [15:0] gold_status_b;
    wire [15:0] gate_status_b;
    wire [15:0] gold_status_c;
    wire [15:0] gate_status_c;
    wire [15:0] gold_status_d;
    wire [15:0] gate_status_d;
    wire [15:0] gold_status_e;
    wire [15:0] gate_status_e;
    wire gold_clk_a_div;
    wire gate_clk_a_div;
    wire gold_clk_b_div;
    wire gate_clk_b_div;
    wire gold_clk_c_div;
    wire gate_clk_c_div;
    wire gold_clk_d_div;
    wire gate_clk_d_div;
    wire gold_clk_e_div;
    wire gate_clk_e_div;

    gold gold_inst (
        .clk_a(clk_a),
        .clk_b(clk_b),
        .clk_c(clk_c),
        .clk_d(clk_d),
        .clk_e(clk_e),
        .rst_async(rst_async),
        .stim(stim),
        .status_a(gold_status_a),
        .status_b(gold_status_b),
        .status_c(gold_status_c),
        .status_d(gold_status_d),
        .status_e(gold_status_e),
        .clk_a_div(gold_clk_a_div),
        .clk_b_div(gold_clk_b_div),
        .clk_c_div(gold_clk_c_div),
        .clk_d_div(gold_clk_d_div),
        .clk_e_div(gold_clk_e_div)
    );

    gate gate_inst (
        .clk_a(clk_a),
        .clk_b(clk_b),
        .clk_c(clk_c),
        .clk_d(clk_d),
        .clk_e(clk_e),
        .rst_async(rst_async),
        .stim(stim),
        .status_a(gate_status_a),
        .status_b(gate_status_b),
        .status_c(gate_status_c),
        .status_d(gate_status_d),
        .status_e(gate_status_e),
        .clk_a_div(gate_clk_a_div),
        .clk_b_div(gate_clk_b_div),
        .clk_c_div(gate_clk_c_div),
        .clk_d_div(gate_clk_d_div),
        .clk_e_div(gate_clk_e_div)
    );

    // Multiple clock domains detected (clk_a, clk_b, clk_c, clk_d, clk_e).
    // Hold reset until EVERY domain has seen a reset edge, so both copies
    // start from identical known state; only then compare outputs, at every
    // timestep (neither clock is 'the' clock here).
    reg seen_rst_clk_a = 1'b0;
    always @(posedge clk_a) if (rst_async) seen_rst_clk_a <= 1'b1;
    reg seen_rst_clk_b = 1'b0;
    always @(posedge clk_b) if (rst_async) seen_rst_clk_b <= 1'b1;
    reg seen_rst_clk_c = 1'b0;
    always @(posedge clk_c) if (rst_async) seen_rst_clk_c <= 1'b1;
    reg seen_rst_clk_d = 1'b0;
    always @(posedge clk_d) if (rst_async) seen_rst_clk_d <= 1'b1;
    reg seen_rst_clk_e = 1'b0;
    always @(posedge clk_e) if (rst_async) seen_rst_clk_e <= 1'b1;

    wire all_domains_reset = seen_rst_clk_a && seen_rst_clk_b && seen_rst_clk_c && seen_rst_clk_d && seen_rst_clk_e;

    always @(*) begin
        if (!all_domains_reset) assume (rst_async);
        else assert (gold_status_a == gate_status_a && gold_status_b == gate_status_b && gold_status_c == gate_status_c && gold_status_d == gate_status_d && gold_status_e == gate_status_e && gold_clk_a_div == gate_clk_a_div && gold_clk_b_div == gate_clk_b_div && gold_clk_c_div == gate_clk_c_div && gold_clk_d_div == gate_clk_d_div && gold_clk_e_div == gate_clk_e_div);
    end

endmodule