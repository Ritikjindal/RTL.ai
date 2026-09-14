module spreader
(
    input  wire ca_chip,
    input  wire nav_bit,

    output wire gps_chip
);

    assign gps_chip = ca_chip ^ nav_bit;

endmodule