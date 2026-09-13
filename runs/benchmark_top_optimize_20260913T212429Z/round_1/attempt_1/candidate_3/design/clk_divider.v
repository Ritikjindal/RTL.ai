// Parameterised clock divider. Generates one divided clock per master domain.
// Ratios are deliberately small (2..8) so the divided domain's behaviour is
// reachable within a bounded formal check.
module clk_divider #(
    parameter integer DIV = 2          // divide-by-N, N >= 2
) (
    input  wire clk_in,
    input  wire rst,
    output reg  clk_out
);

    localparam integer HALF = (DIV / 2);

    reg [7:0] count;

    always @(posedge clk_in) begin
        if (rst) begin
            count   <= 8'd0;
            clk_out <= 1'b0;
        end else if (count == HALF - 1) begin
            count   <= 8'd0;
            clk_out <= ~clk_out;
        end else begin
            count   <= count + 8'd1;
        end
    end

endmodule