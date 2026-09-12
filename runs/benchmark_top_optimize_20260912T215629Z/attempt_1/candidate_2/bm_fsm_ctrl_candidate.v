// This module owns the critical path of the full design (clock 'clk_e', worst slack -1.3 ns).
module bm_fsm_ctrl #(
    parameter integer DW   = 16,
    parameter integer ACCW = 24
) (
    input  wire            clk,
    input  wire            rst,
    input  wire            in_valid,
    input  wire [DW-1:0]   in_data,
    input  wire [3:0]      cmd,
    output reg             out_valid,
    output reg  [ACCW-1:0] out_data,
    output reg  [3:0]      status
);

    // ---------------- one-hot state encoding ----------------
    localparam [15:0] S_IDLE    = 16'b0000_0000_0000_0001;
    localparam [15:0] S_SYNC1   = 16'b0000_0000_0000_0010;
    localparam [15:0] S_SYNC2   = 16'b0000_0000_0000_0100;
    localparam [15:0] S_HDR0    = 16'b0000_0000_0000_1000;
    localparam [15:0] S_HDR1    = 16'b0000_0000_0001_0000;
    localparam [15:0] S_HDR2    = 16'b0000_0000_0010_0000;
    localparam [15:0] S_HDR3    = 16'b0000_0000_0100_0000;
    localparam [15:0] S_LEN     = 16'b0000_0000_1000_0000;
    localparam [15:0] S_PAYLOAD = 16'b0000_0001_0000_0000;
    localparam [15:0] S_ESCAPE  = 16'b0000_0010_0000_0000;
    localparam [15:0] S_CHK0    = 16'b0000_0100_0000_0000;
    localparam [15:0] S_CHK1    = 16'b0000_1000_0000_0000;
    localparam [15:0] S_FLUSH   = 16'b0001_0000_0000_0000;
    localparam [15:0] S_WAIT    = 16'b0010_0000_0000_0000;
    localparam [15:0] S_ERROR   = 16'b0100_0000_0000_0000;
    localparam [15:0] S_DONE    = 16'b1000_0000_0000_0000;

    localparam [DW-1:0] SYNC_A = 16'h55AA;
    localparam [DW-1:0] SYNC_B = 16'hA55A;
    localparam [DW-1:0] ESC_CH = 16'h7D7D;

    reg [15:0]    state;
    reg [ACCW-1:0] acc;
    reg [DW-1:0]  hold;
    reg [7:0]     count;
    reg [DW-1:0]  length;

    // Pipeline stage registers (inserted after d4)
    reg [ACCW-1:0] acc_mid;
    reg [15:0]    state_d;
    reg [ACCW-1:0] held_d;
    reg [ACCW-1:0] lenx_d;
    reg [ACCW-1:0] cntx_d;
    reg [ACCW-1:0] ext_d;
    reg [ACCW-1:0] acc_d;
    reg            in_valid_d;

    // ---------------- next state ----------------
    reg [15:0] next;

    always @* begin
        next = state;
        case (1'b1)                       // one-hot case
            state[0]:  next = (in_valid && in_data == SYNC_A) ? S_SYNC1 : S_IDLE;
            state[1]:  next = !in_valid ? S_SYNC1
                            : (in_data == SYNC_B) ? S_SYNC2 : S_IDLE;
            state[2]:  next = in_valid ? S_HDR0 : S_SYNC2;
            state[3]:  next = in_valid ? S_HDR1 : S_HDR0;
            state[4]:  next = in_valid ? S_HDR2 : S_HDR1;
            state[5]:  next = in_valid ? S_HDR3 : S_HDR2;
            state[6]:  next = in_valid ? S_LEN  : S_HDR3;
            state[7]:  next = !in_valid ? S_LEN
                            : (in_data == 16'd0) ? S_ERROR : S_PAYLOAD;
            state[8]:  next = !in_valid ? S_PAYLOAD
                            : (in_data == ESC_CH) ? S_ESCAPE
                            : (count + 8'd1 >= length[7:0]) ? S_CHK0 : S_PAYLOAD;
            state[9]:  next = in_valid ? S_PAYLOAD : S_ESCAPE;
            state[10]: next = in_valid ? S_CHK1 : S_CHK0;
            state[11]: next = !in_valid ? S_CHK1
                            : (in_data == acc[DW-1:0]) ? S_FLUSH : S_ERROR;
            state[12]: next = S_WAIT;
            state[13]: next = (cmd == 4'hF) ? S_DONE : S_WAIT;
            state[14]: next = (cmd == 4'h0) ? S_IDLE : S_ERROR;
            state[15]: next = S_IDLE;
            default:   next = S_IDLE;
        endcase
    end

    // ---------------- per-state datapath decode ----------------
    // First half of chain (combinational, same cycle)
    wire [ACCW-1:0] ext   = {{(ACCW-DW){1'b0}}, in_data};
    wire [ACCW-1:0] held  = {{(ACCW-DW){1'b0}}, hold};
    wire [ACCW-1:0] lenx  = {{(ACCW-DW){1'b0}}, length};
    wire [ACCW-1:0] cntx  = {{(ACCW-8){1'b0}}, count};

    wire [ACCW-1:0] d0 = acc ^ ext;
    wire [ACCW-1:0] d1 = state[3] ? (d0 + ext)            : d0;
    wire [ACCW-1:0] d2 = state[4] ? (d1 + {ext[ACCW-2:0], 1'b0}) : d1;
    wire [ACCW-1:0] d3 = state[5] ? (d2 + held)           : d2;
    wire [ACCW-1:0] d4 = state[6] ? (d3 + lenx)           : d3;

    // Second half of chain (combinational, uses delayed versions from pipeline stage)
    wire [ACCW-1:0] d5 = state_d[7] ? (acc_mid + cntx_d)           : acc_mid;
    wire [ACCW-1:0] d6 = state_d[8] ? (d5 + ext_d + cntx_d)     : d5;
    wire [ACCW-1:0] d7 = state_d[9] ? (d6 ^ {ext_d[ACCW-9:0], 8'h7D}) : d6;
    wire [ACCW-1:0] d8 = state_d[10] ? (d7 + held_d + lenx_d)   : d7;
    wire [ACCW-1:0] d9 = state_d[11] ? (d8 ^ acc_d)           : d8;

    // ---------------- sequential ----------------
    always @(posedge clk) begin
        if (rst) begin
            state     <= S_IDLE;
            acc       <= {ACCW{1'b0}};
            hold      <= {DW{1'b0}};
            count     <= 8'd0;
            length    <= {DW{1'b0}};
            out_data  <= {ACCW{1'b0}};
            out_valid <= 1'b0;
            status    <= 4'd0;

            // Pipeline stage reset
            acc_mid   <= {ACCW{1'b0}};
            state_d   <= S_IDLE;
            held_d    <= {ACCW{1'b0}};
            lenx_d    <= {ACCW{1'b0}};
            cntx_d    <= {ACCW{1'b0}};
            ext_d     <= {ACCW{1'b0}};
            acc_d     <= {ACCW{1'b0}};
            in_valid_d <= 1'b0;
        end else begin
            state <= next;

            if (in_valid)
                hold <= in_data;

            if (state[7] && in_valid)
                length <= in_data;

            if (state[8] && in_valid)
                count <= count + 8'd1;
            else if (state[0] || state[15])
                count <= 8'd0;

            // Capture pipeline stage: d4 and all signals needed for second half
            acc_mid  <= d4;
            state_d  <= state;
            held_d   <= held;
            lenx_d   <= lenx;
            cntx_d   <= cntx;
            ext_d    <= ext;
            acc_d    <= acc;
            in_valid_d <= in_valid;

            // Update acc and outputs based on delayed d9
            if (in_valid_d)
                acc <= d9;
            else if (state_d[12])
                acc <= {ACCW{1'b0}};

            out_valid <= state_d[12];
            if (state_d[12])
                out_data <= acc;

            status <= {state_d[14], state_d[15], state_d[8], state_d[0]};
        end
    end

endmodule