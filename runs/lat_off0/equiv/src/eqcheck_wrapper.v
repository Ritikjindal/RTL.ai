module __eqcheck_top (
    input wire clk,
    input wire rst,
    input wire [7:0] din
);

    wire [7:0] gold_dout;
    wire [7:0] gate_dout;

    gold gold_inst (
        .clk(clk),
        .rst(rst),
        .din(din),
        .dout(gold_dout)
    );

    gate gate_inst (
        .clk(clk),
        .rst(rst),
        .din(din),
        .dout(gate_dout)
    );

    // First cycle: force a real reset via $initstate before comparing,
    // so the proof isn't defeated by unconstrained initial register state.
    always @(posedge clk) begin
        if ($initstate) begin
            assume (rst);
        end else begin
            assert (gold_dout == gate_dout);
        end
    end

endmodule