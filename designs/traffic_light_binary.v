module traffic_light (
    input  wire clk,
    input  wire rst,
    output reg  red,
    output reg  green,
    output reg  yellow
);

    // Binary encoding: 3 states packed into 2 bits.
    localparam [1:0] S_RED    = 2'b00;
    localparam [1:0] S_GREEN  = 2'b01;
    localparam [1:0] S_YELLOW = 2'b10;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst)
            state <= S_RED;
        else begin
            case (state)
                S_RED:    state <= S_GREEN;
                S_GREEN:  state <= S_YELLOW;
                S_YELLOW: state <= S_RED;
                default:  state <= S_RED;
            endcase
        end
    end

    always @(*) begin
        red    = (state == S_RED);
        green  = (state == S_GREEN);
        yellow = (state == S_YELLOW);
    end

endmodule