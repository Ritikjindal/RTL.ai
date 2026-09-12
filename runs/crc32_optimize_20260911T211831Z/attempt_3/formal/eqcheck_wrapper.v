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

    // First cycle: force a real reset via $initstate before comparing,
    // so the proof isn't defeated by unconstrained initial register state.
    always @(posedge clk) begin
        if ($initstate) begin
            assume (rst);
        end else begin
            assert (gold_out_valid == gate_out_valid && gold_out_crc == gate_out_crc);
        end
    end

endmodule