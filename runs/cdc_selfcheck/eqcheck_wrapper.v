module __eqcheck_top (
    input wire clk_a,
    input wire clk_b,
    input wire rst,
    input wire enable
);

    wire [7:0] gold_count_a;
    wire [7:0] gate_count_a;
    wire [7:0] gold_count_b;
    wire [7:0] gate_count_b;

    gold gold_inst (
        .clk_a(clk_a),
        .clk_b(clk_b),
        .rst(rst),
        .enable(enable),
        .count_a(gold_count_a),
        .count_b(gold_count_b)
    );

    gate gate_inst (
        .clk_a(clk_a),
        .clk_b(clk_b),
        .rst(rst),
        .enable(enable),
        .count_a(gate_count_a),
        .count_b(gate_count_b)
    );

    // Multiple clock domains detected (clk_a, clk_b).
    // Hold reset until EVERY domain has seen a reset edge, so both copies
    // start from identical known state; only then compare outputs, at every
    // timestep (neither clock is 'the' clock here).
    reg seen_rst_clk_a = 1'b0;
    always @(posedge clk_a) if (rst) seen_rst_clk_a <= 1'b1;
    reg seen_rst_clk_b = 1'b0;
    always @(posedge clk_b) if (rst) seen_rst_clk_b <= 1'b1;

    wire all_domains_reset = seen_rst_clk_a && seen_rst_clk_b;

    always @(*) begin
        if (!all_domains_reset) assume (rst);
        else assert (gold_count_a == gate_count_a && gold_count_b == gate_count_b);
    end

endmodule