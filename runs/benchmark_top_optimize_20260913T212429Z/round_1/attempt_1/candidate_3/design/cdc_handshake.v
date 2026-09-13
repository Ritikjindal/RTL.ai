// Four-phase request/acknowledge handshake carrying a data word across clock
// domains.
//
// Only a single control bit (req) actually crosses into the destination domain,
// through a two-flop synchronizer; the data bus is held stable by the source
// until acknowledged and is only sampled once that request has been
// synchronized. This is the standard "data-hold / MCP" crossing, and is why the
// data bits do not each need their own synchronizer - per-bit synchronizers
// would let the bits skew independently, which is the classic multi-bit CDC bug.
//
// Each side is reset by its own domain's synchronized reset.
module cdc_handshake #(
    parameter integer WIDTH = 16
) (
    input  wire             clk_src,
    input  wire             clk_dst,
    input  wire             rst_src,
    input  wire             rst_dst,

    input  wire             send,
    input  wire [WIDTH-1:0] data_in,
    output reg              busy,

    output reg  [WIDTH-1:0] data_out,
    output reg              data_valid
);

    reg              req;
    reg  [WIDTH-1:0] data_hold;
    reg              ack;
    wire             req_sync;
    wire             ack_sync;

    // ---------------- source domain ----------------
    always @(posedge clk_src) begin
        if (rst_src) begin
            req       <= 1'b0;
            busy      <= 1'b0;
            data_hold <= {WIDTH{1'b0}};
        end else if (send && !busy) begin
            data_hold <= data_in;
            req       <= 1'b1;
            busy      <= 1'b1;
        end else if (ack_sync) begin
            req  <= 1'b0;
            busy <= 1'b0;
        end
    end

    // ---------------- control bits crossing both ways ----------------
    cdc_sync u_req_sync (
        .clk_dst (clk_dst),
        .rst     (rst_dst),
        .sig_src (req),
        .sig_dst (req_sync)
    );

    cdc_sync u_ack_sync (
        .clk_dst (clk_src),
        .rst     (rst_src),
        .sig_src (ack),
        .sig_dst (ack_sync)
    );

    // ---------------- destination domain ----------------
    always @(posedge clk_dst) begin
        if (rst_dst) begin
            ack        <= 1'b0;
            data_out   <= {WIDTH{1'b0}};
            data_valid <= 1'b0;
        end else if (req_sync && !ack) begin
            data_out   <= data_hold;
            data_valid <= 1'b1;
            ack        <= 1'b1;
        end else if (!req_sync) begin
            ack        <= 1'b0;
            data_valid <= 1'b0;
        end
    end

endmodule