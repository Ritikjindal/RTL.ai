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

    // Latency offset of 1 cycle(s): the candidate produces its
    // outputs later than the baseline (added pipeline stages), so the baseline's
    // outputs are delayed by that many cycles before being compared.
    reg [7:0] gold_dout_d1;

    always @(posedge clk) begin
        gold_dout_d1 <= gold_dout;
    end

    // Comparison is suppressed until the delay pipeline has filled.
    reg [7:0] warmup = 8'd0;
    always @(posedge clk) begin
        if (rst) warmup <= 8'd0;
        else if (warmup < 8'd1) warmup <= warmup + 8'd1;
    end

    // First cycle: force a real reset via $initstate before comparing,
    // so the proof isn't defeated by unconstrained initial register state.
    always @(posedge clk) begin
        if ($initstate) begin
            assume (rst);
        end else begin
            if (warmup >= 8'd1) assert (gold_dout_d1 == gate_dout);
        end
    end

endmodule