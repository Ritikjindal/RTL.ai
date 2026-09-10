module __eqcheck_top (
    input wire clk,
    input wire rst
);

    wire gold_red;
    wire gate_red;
    wire gold_green;
    wire gate_green;
    wire gold_yellow;
    wire gate_yellow;

    gold gold_inst (
        .clk(clk),
        .rst(rst),
        .red(gold_red),
        .green(gold_green),
        .yellow(gold_yellow)
    );

    gate gate_inst (
        .clk(clk),
        .rst(rst),
        .red(gate_red),
        .green(gate_green),
        .yellow(gate_yellow)
    );

    // First cycle: force a real reset via $initstate before comparing,
    // so the proof isn't defeated by unconstrained initial register state.
    always @(posedge clk) begin
        if ($initstate) begin
            assume (rst);
        end else begin
            assert (gold_red == gate_red && gold_green == gate_green && gold_yellow == gate_yellow);
        end
    end

endmodule