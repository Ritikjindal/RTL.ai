module __eqcheck_top (
    input wire clk,
    input wire rst,
    input wire in_valid,
    input wire [63:0] in_data,
    input wire in_last,
    input wire [3:0] in_bytes
);

    wire gold_out_valid;
    wire gate_out_valid;
    wire [31:0] gold_out_crc;
    wire [31:0] gate_out_crc;

    gold gold_inst (
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .in_data(in_data),
        .in_last(in_last),
        .in_bytes(in_bytes),
        .out_valid(gold_out_valid),
        .out_crc(gold_out_crc)
    );

    gate gate_inst (
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .in_data(in_data),
        .in_last(in_last),
        .in_bytes(in_bytes),
        .out_valid(gate_out_valid),
        .out_crc(gate_out_crc)
    );

    // Latency offset of 1 cycle(s): the candidate produces its
    // outputs later than the baseline (added pipeline stages), so the baseline's
    // outputs are delayed by that many cycles before being compared.
    reg gold_out_valid_d1;
    reg [31:0] gold_out_crc_d1;

    always @(posedge clk) begin
        gold_out_valid_d1 <= gold_out_valid;
        gold_out_crc_d1 <= gold_out_crc;
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
            if (warmup >= 8'd1) assert (gold_out_valid_d1 == gate_out_valid && gold_out_crc_d1 == gate_out_crc);
        end
    end

endmodule