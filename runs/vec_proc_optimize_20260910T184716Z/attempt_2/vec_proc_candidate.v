// Single-clock 8-lane vector processing unit.
//
// Cell count comes from 8 parallel 16-bit lanes.
// The control FSM is re-encoded from one-hot (12 bits) to binary (4 bits),
// reducing state register size and combinational decode logic while maintaining
// cycle-accurate equivalence.

module vec_proc (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [2:0]   op,
    input  wire [127:0] a_vec,
    input  wire [127:0] b_vec,
    output reg  [127:0] result_vec,
    output reg          done
);

    localparam [2:0] OP_ADD = 3'd0,
                     OP_SUB = 3'd1,
                     OP_MIN = 3'd2,
                     OP_MAX = 3'd3,
                     OP_SHL = 3'd4,
                     OP_SHR = 3'd5,
                     OP_AND = 3'd6,
                     OP_XOR = 3'd7;

    localparam [3:0] S_IDLE  = 4'd0;
    localparam [3:0] S_LOAD  = 4'd1;
    localparam [3:0] S_D1    = 4'd2;
    localparam [3:0] S_D2    = 4'd3;
    localparam [3:0] S_D3    = 4'd4;
    localparam [3:0] S_CALC  = 4'd5;
    localparam [3:0] S_D4    = 4'd6;
    localparam [3:0] S_D5    = 4'd7;
    localparam [3:0] S_D6    = 4'd8;
    localparam [3:0] S_STORE = 4'd9;
    localparam [3:0] S_D7    = 4'd10;
    localparam [3:0] S_DONE  = 4'd11;

    reg [3:0]   state;
    reg [127:0] a_reg, b_reg;
    reg [2:0]   op_reg;
    wire [127:0] lane_result;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : lanes
            wire [15:0] a_i = a_reg[i*16 +: 16];
            wire [15:0] b_i = b_reg[i*16 +: 16];
            reg  [15:0] r_i;

            always @(*) begin
                case (op_reg)
                    OP_ADD:  r_i = a_i + b_i;
                    OP_SUB:  r_i = a_i - b_i;
                    OP_MIN:  r_i = (a_i < b_i) ? a_i : b_i;
                    OP_MAX:  r_i = (a_i > b_i) ? a_i : b_i;
                    OP_SHL:  r_i = a_i << b_i[3:0];
                    OP_SHR:  r_i = a_i >> b_i[3:0];
                    OP_AND:  r_i = a_i & b_i;
                    OP_XOR:  r_i = a_i ^ b_i;
                    default: r_i = 16'd0;
                endcase
            end

            assign lane_result[i*16 +: 16] = r_i;
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            state      <= S_IDLE;
            a_reg      <= 128'd0;
            b_reg      <= 128'd0;
            op_reg     <= 3'd0;
            result_vec <= 128'd0;
            done       <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 1'b0;
                    if (start) state <= S_LOAD;
                end
                S_LOAD: begin
                    a_reg  <= a_vec;
                    b_reg  <= b_vec;
                    op_reg <= op;
                    state  <= S_D1;
                end
                S_D1:    state <= S_D2;
                S_D2:    state <= S_D3;
                S_D3:    state <= S_CALC;
                S_CALC:  state <= S_D4;
                S_D4:    state <= S_D5;
                S_D5:    state <= S_D6;
                S_D6:    state <= S_STORE;
                S_STORE: begin
                    result_vec <= lane_result;
                    state      <= S_D7;
                end
                S_D7:    state <= S_DONE;
                S_DONE: begin
                    done  <= 1'b1;
                    state <= S_IDLE;
                end
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule