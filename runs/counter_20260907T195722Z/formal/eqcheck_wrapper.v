module __eqcheck_top (
    input wire clk,
    input wire rst
);

    wire [7:0] gold_count;
    wire [7:0] gate_count;

    gold gold_inst (
        .clk(clk),
        .rst(rst),
        .count(gold_count)
    );

    gate gate_inst (
        .clk(clk),
        .rst(rst),
        .count(gate_count)
    );

    // First cycle: force a real reset via $initstate before comparing,
    // so the proof isn't defeated by unconstrained initial register state.
    always @(posedge clk) begin
        if ($initstate) begin
            assume (rst);
        end else begin
            assert (gold_count == gate_count);
        end
    end

endmodule