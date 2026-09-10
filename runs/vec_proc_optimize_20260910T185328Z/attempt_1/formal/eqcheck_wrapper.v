module __eqcheck_top (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [2:0] op,
    input wire [127:0] a_vec,
    input wire [127:0] b_vec
);

    wire [127:0] gold_result_vec;
    wire [127:0] gate_result_vec;
    wire gold_done;
    wire gate_done;

    gold gold_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .op(op),
        .a_vec(a_vec),
        .b_vec(b_vec),
        .result_vec(gold_result_vec),
        .done(gold_done)
    );

    gate gate_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .op(op),
        .a_vec(a_vec),
        .b_vec(b_vec),
        .result_vec(gate_result_vec),
        .done(gate_done)
    );

    // Multiple clock domains detected (clk).
    // Hold reset until EVERY domain has seen a reset edge, so both copies
    // start from identical known state; only then compare outputs, at every
    // timestep (neither clock is 'the' clock here).
    reg seen_rst_clk = 1'b0;
    always @(posedge clk) if (rst) seen_rst_clk <= 1'b1;

    wire all_domains_reset = seen_rst_clk;

    always @(*) begin
        if (!all_domains_reset) assume (rst);
        else assert (gold_result_vec == gate_result_vec && gold_done == gate_done);
    end

endmodule