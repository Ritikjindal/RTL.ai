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

    // Pipeline stage 1 registers
    reg [ACCW-1:0] d4_r;
    reg [ACCW-1:0] held_r;
    reg [ACCW-1:0] lenx_r;
    reg [ACCW-1:0] cntx_r;
    reg [ACCW-1:0] ext_r;
    reg state8_r;
    reg state9_r;
    reg state10_r;
    reg state11_r;
    reg in_valid_r;

    // Pipeline stage 2 registers (for output timing alignment)
    reg state12_r;
    reg state14_r;
    reg state15_r;
    reg [3:0] status_r;
    reg out_valid_r;
    reg [ACCW-1:0] out_data_r;

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

    // ---------------- per-state datapath decode (stage 1) ----------------
    wire [ACCW-1:0] ext   = {{(ACCW-DW){1'b0}}, in_data};
    wire [ACCW-1:0] held  = {{(ACCW-DW){1'b0}}, hold};
    wire [ACCW-1:0] lenx  = {{(ACCW-DW){1'b0}}, length};
    wire [ACCW-1:0] cntx  = {{(ACCW-8){1'b0}}, count};

    wire [ACCW-1:0] d0 = acc ^ ext;
    wire [ACCW-1:0] d1 = state[3] ? (d0 + ext)            : d0;
    wire [ACCW-1:0] d2 = state[4] ? (d1 + {ext[ACCW-2:0], 1'b0}) : d1;
    wire [ACCW-1:0] d3 = state[5] ? (d2 + held)           : d2;
    wire [ACCW-1:0] d4 = state[6] ? (d3 + lenx)           : d3;

    // Pipeline stage 2: second half of datapath (d5 through d9)
    wire [ACCW-1:0] d5 = state8_r ? (d4_r + lenx_r)           : d4_r;
    wire [ACCW-1:0] d6 = state8_r ? (d5 + ext_r + cntx_r)     : d5;
    wire [ACCW-1:0] d7 = state9_r ? (d6 ^ {ext_r[ACCW-9:0], 8'h7D}) : d6;
    wire [ACCW-1:0] d8 = state10_r ? (d7 + held_r + lenx_r)   : d7;
    wire [ACCW-1:0] d9 = state11_r ? (d8 ^ acc)           : d8;

    // Corrected: d5 should add cntx_r, not lenx_r
    wire [ACCW-1:0] d5_correct = state8_r ? (d4_r + cntx_r)           : d4_r;
    wire [ACCW-1:0] d6_correct = state8_r ? (d5_correct + ext_r + cntx_r)     : d5_correct;
    wire [ACCW-1:0] d7_correct = state9_r ? (d6_correct ^ {ext_r[ACCW-9:0], 8'h7D}) : d6_correct;
    wire [ACCW-1:0] d8_correct = state10_r ? (d7_correct + held_r + lenx_r)   : d7_correct;
    wire [ACCW-1:0] d9_correct = state11_r ? (d8_correct ^ acc)           : d8_correct;

    // Use the corrected version
    wire [ACCW-1:0] d5_use = state8_r ? (d4_r + cntx_r)           : d4_r;
    wire [ACCW-1:0] d6_use = state8_r ? (d5_use + ext_r + cntx_r)     : d5_use;
    wire [ACCW-1:0] d7_use = state9_r ? (d6_use ^ {ext_r[ACCW-9:0], 8'h7D}) : d6_use;
    wire [ACCW-1:0] d8_use = state10_r ? (d7_use + held_r + lenx_r)   : d7_use;
    wire [ACCW-1:0] d9_use = state11_r ? (d8_use ^ acc)           : d8_use;

    // For stage 7, the original is: state[7] ? (d4 + cntx) : d4
    // But d5 in the original is: state[7] ? (d4 + cntx) : d4
    // So the stage 5 computation (state[5] condition) happens before the pipeline cut
    // Let me reconsider the original chain:
    // d0 = acc ^ ext;
    // d1 = state[3] ? (d0 + ext) : d0;
    // d2 = state[4] ? (d1 + {ext[ACCW-2:0], 1'b0}) : d1;
    // d3 = state[5] ? (d2 + held) : d2;
    // d4 = state[6] ? (d3 + lenx) : d3;
    // [PIPELINE CUT HERE]
    // d5 = state[7] ? (d4 + cntx) : d4;
    // d6 = state[8] ? (d5 + ext + cntx) : d5;
    // d7 = state[9] ? (d6 ^ {ext[ACCW-9:0], 8'h7D}) : d6;
    // d8 = state[10] ? (d7 + held + lenx) : d7;
    // d9 = state[11] ? (d8 ^ acc) : d8;

    wire [ACCW-1:0] d5_final = state8_r ? (d4_r + cntx_r)           : d4_r;
    wire [ACCW-1:0] d6_final = state8_r ? (d5_final + ext_r + cntx_r)     : d5_final;
    wire [ACCW-1:0] d7_final = state9_r ? (d6_final ^ {ext_r[ACCW-9:0], 8'h7D}) : d6_final;
    wire [ACCW-1:0] d8_final = state10_r ? (d7_final + held_r + lenx_r)   : d7_final;
    wire [ACCW-1:0] d9_final = state11_r ? (d8_final ^ acc)           : d8_final;

    // Actually, looking at the original again, stage 5 uses state[7] not state[5]:
    // d5 = state[7] ? (d4 + cntx) : d4;
    // So we need state[7] delayed, not state[5]
    // Let me re-read the original more carefully...
    // Original line: wire [ACCW-1:0] d5 = state[7] ? (d4 + cntx) : d4;
    // So state[7] is the control signal for d5
    // We need state[7]_r, state[8]_r, state[9]_r, state[10]_r, state[11]_r

    // Redo with correct state bits
    reg state7_r;
    wire [ACCW-1:0] d5_v2 = state7_r ? (d4_r + cntx_r)           : d4_r;
    wire [ACCW-1:0] d6_v2 = state8_r ? (d5_v2 + ext_r + cntx_r)     : d5_v2;
    wire [ACCW-1:0] d7_v2 = state9_r ? (d6_v2 ^ {ext_r[ACCW-9:0], 8'h7D}) : d6_v2;
    wire [ACCW-1:0] d8_v2 = state10_r ? (d7_v2 + held_r + lenx_r)   : d7_v2;
    wire [ACCW-1:0] d9_v2 = state11_r ? (d8_v2 ^ acc)           : d8_v2;

    // Use d9_v2 for the pipelined result
    wire [ACCW-1:0] d9_pipelined = d9_v2;

    // Update outputs using the pipelined path
    wire [ACCW-1:0] acc_next = (in_valid && !in_valid_r) ? d9_pipelined : acc;
    wire out_valid_next = state12_r;
    wire [ACCW-1:0] out_data_next = state12_r ? acc : out_data_r;
    wire [3:0] status_next = {state14_r, state15_r, state8_r, state[0]};

    // Use a simpler assignment for outputs that directly uses the pipelined signals
    // Outputs should reflect the pipelined computation

    // Actually, re-reading the plan more carefully:
    // "Rebuild d5 through d9 unchanged in arithmetic form, but sourced from d4_r, held_r, lenx_r, cntx_r, ext_r, and the delayed state bits instead of the original combinational signals."
    // "The acc register update (acc <= d9 when the delayed in_valid_r is set) now consumes this second-stage result one cycle later than before"
    // "likewise gate out_data <= acc, out_valid <= state[12], and status <= with the same one-cycle-delayed pipeline so every downstream consumer of the split chain sees a consistently-staged value."

    // So the outputs should be delayed by one cycle to match the acc computation delay

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

            // Pipeline stage 1
            d4_r      <= {ACCW{1'b0}};
            held_r    <= {ACCW{1'b0}};
            lenx_r    <= {ACCW{1'b0}};
            cntx_r    <= {ACCW{1'b0}};
            ext_r     <= {ACCW{1'b0}};
            state7_r  <= 1'b0;
            state8_r  <= 1'b0;
            state9_r  <= 1'b0;
            state10_r <= 1'b0;
            state11_r <= 1'b0;
            in_valid_r <= 1'b0;

            // Pipeline stage 2
            state12_r <= 1'b0;
            state14_r <= 1'b0;
            state15_r <= 1'b0;
            status_r  <= 4'd0;
            out_valid_r <= 1'b0;
            out_data_r <= {ACCW{1'b0}};
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

            // Pipeline stage 1 registers
            d4_r <= d4;
            held_r <= held;
            lenx_r <= lenx;
            cntx_r <= cntx;
            ext_r <= ext;
            state7_r <= state[7];
            state8_r <= state[8];
            state9_r <= state[9];
            state10_r <= state[10];
            state11_r <= state[11];
            in_valid_r <= in_valid;

            // Update acc from pipelined d9
            if (in_valid_r)
                acc <= d9_pipelined;
            else if (state12_r)
                acc <= {ACCW{1'b0}};

            // Pipeline stage 2 registers (for output timing)
            state12_r <= state[12];
            state14_r <= state[14];
            state15_r <= state[15];
            status_r <= {state[14], state[15], state[8], state[0]};
            out_valid_r <= state[12];
            out_data_r <= acc;

            // Final outputs
            out_valid <= out_valid_r;
            out_data <= out_data_r;
            status <= status_r;
        end
    end

endmodule