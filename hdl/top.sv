import rl_types::*;

module top (
    // VCU118 Physical Pins (125MHz Differential Pair)
    input  logic        clk125_p,          // AY24
    input  logic        clk125_n,          // AY23
    input  logic        cpu_reset,         // L19 -- ACTIVE HIGH

    // FPGA --> Chip
    output logic        chip_rst_n,

    output io_in_t      chip_pkt_i,
    output logic        chip_rx_enqueue,
    output logic        chip_tx_dequeue,

    // Chip --> FPGA
    input  logic                chip_fifo_rx_full,
    input  logic                chip_fifo_tx_empty,

    input  io_out_t             chip_pkt_o,        // From chip pkt_o
    input  logic                chip_pkt_o_valid,  // From chip pkt_o_valid
    
    input  ctrl_status_reg_t    chip_reg_o,
    input  logic                chip_power_test_o,

    // ...
);
    // ==== Clocking & Reset ====
    logic clk;
    logic rst_n;


    // Differential --> Single ended clock generator
    IBUFDS u_ibufds_clk125 (
        .I (clk125_p),
        .IB(clk125_n),
        .O (clk) 
    );

    // TODO Reset Synchronizer: Converts async button press to sync rst_n
    assign chip_rst_n = rst_n;
    // ...

    // TODO Chip interface HDL here

endmodule : top
