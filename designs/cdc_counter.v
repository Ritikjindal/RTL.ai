// Two clock domains:
//   clk_a - an 8-bit counter increments here
//   clk_b - the counter value is brought across with a 2-flop synchronizer
module cdc_counter (
    input  wire       clk_a,
    input  wire       clk_b,
    input  wire       rst,
    input  wire       enable,
    output reg  [7:0] count_a,
    output reg  [7:0] count_b
);

    // ---- clk_a domain ----
    always @(posedge clk_a) begin
        if (rst)
            count_a <= 8'd0;
        else if (enable)
            count_a <= count_a + 8'd1;
    end

    // ---- clk_b domain: 2-flop synchronizer ----
    reg [7:0] sync_stage1;

    always @(posedge clk_b) begin
        if (rst) begin
            sync_stage1 <= 8'd0;
            count_b     <= 8'd0;
        end else begin
            sync_stage1 <= count_a;
            count_b     <= sync_stage1;
        end
    end

endmodule