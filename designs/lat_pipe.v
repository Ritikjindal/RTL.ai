module lat_test (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] din,
    output reg  [7:0] dout
);
    reg [7:0] stage1;
    always @(posedge clk) begin
        if (rst) begin
            stage1 <= 8'd0;
            dout   <= 8'd0;
        end else begin
            stage1 <= din + 8'd1;
            dout   <= stage1;
        end
    end
endmodule