module lat_test (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] din,
    output reg  [7:0] dout
);
    always @(posedge clk) begin
        if (rst) dout <= 8'd0;
        else     dout <= din + 8'd1;
    end
endmodule