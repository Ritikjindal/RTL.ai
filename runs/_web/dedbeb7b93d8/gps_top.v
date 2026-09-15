module gps_top
(
    input  wire       clk,
    input  wire       rst,
    input  wire [5:0] prn_id,

    output wire       gps_chip
);

    wire ca_chip;
    wire prn_epoch;

    wire [10:0] nav_addr;
    wire nav_bit;

    //--------------------------------
    // CA Generator
    //--------------------------------

    CA_gen ca_inst
    (
        .clk(clk),
        .rst(rst),
        .prn_id(prn_id),

        .ca_chip(ca_chip),
        .prn_epoch(prn_epoch)
    );

    //--------------------------------
    // Navigation Controller
    //--------------------------------

    nav_controller nav_ctrl
    (
        .clk(clk),
        .rst(rst),

        .prn_epoch(prn_epoch),

        .nav_addr(nav_addr)
    );

    //--------------------------------
    // Navigation ROM
    //--------------------------------

    BRAM nav_rom
    (
        .addr(nav_addr),
        .data_out(nav_bit)
    );

    //--------------------------------
    // Spreader
    //--------------------------------

    spreader spr
    (
        .ca_chip(ca_chip),
        .nav_bit(nav_bit),

        .gps_chip(gps_chip)
    );

endmodule