// DELIBERATELY NOT EQUIVALENT to cdc_counter.v - single-stage sync instead of two.
module cdc_counter (
    input  wire       clk_a,
    input  wire       clk_b,
    input  wire       rst,
    input  wire       enable,
    output reg  [7:0] count_a,
    output reg  [7:0] count_b
);

    always @(posedge clk_a) begin
        if (rst)
            count_a <= 8'd0;
        else if (enable)
            count_a <= count_a + 8'd1;
    end

    always @(posedge clk_b) begin
        if (rst)
            count_b <= 8'd0;
        else
            count_b <= count_a;
    end

endmodule