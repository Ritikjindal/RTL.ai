module __eqcheck_top (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [511:0] curblk,
    input wire [511:0] refblk
);

    wire gold_valid_out;
    wire gate_valid_out;
    wire [13:0] gold_sad;
    wire [13:0] gate_sad;

    gold gold_inst (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .curblk(curblk),
        .refblk(refblk),
        .valid_out(gold_valid_out),
        .sad(gold_sad)
    );

    gate gate_inst (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .curblk(curblk),
        .refblk(refblk),
        .valid_out(gate_valid_out),
        .sad(gate_sad)
    );

    // First cycle: force a real reset via $initstate before comparing,
    // so the proof isn't defeated by unconstrained initial register state.
    always @(posedge clk) begin
        if ($initstate) begin
            assume (rst);
        end else begin
            assert (gold_valid_out == gate_valid_out && gold_sad == gate_sad);
        end
    end

endmodule