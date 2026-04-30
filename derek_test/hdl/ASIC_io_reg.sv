import rl_types::*;

module ASIC_io_reg(
    // ASIC IO
    // FPGA --> Chip
    output  logic        chip_clk,
    output  logic        chip_rst_n,

    output  io_in_t      chip_pkt_i,
    output  logic        chip_fifo_rx_enqueue,
    output  logic        chip_fifo_tx_dequeue,

    // Chip --> FPGA
    input   logic               chip_fifo_rx_full,
    input   logic               chip_fifo_tx_empty,

    input   io_out_t            chip_pkt_o,        
    input   logic               chip_pkt_o_valid,  
    
    input   ctrl_status_reg_t   chip_reg_o,
    input   logic               chip_power_test_o,
    
    // Internal signal
    input   logic               FPGA_clk,
    input   logic               FPGA_rst_n,
    input   io_in_t             FPGA_pkt_i,
    input   logic               FPGA_fifo_rx_enqueue,
    input   logic               FPGA_fifo_tx_dequeue,
    
    output  logic               FPGA_fifo_rx_full,
    output  logic               FPGA_fifo_tx_empty,
    output  io_out_t            FPGA_pkt_o,
    output  logic               FPGA_pkt_o_valid,
    output  ctrl_status_reg_t   FPGA_reg_o,
    output  logic               FPGA_power_test_o

    );
    
    assign chip_clk = FPGA_clk;
    assign chip_rst_n = FPGA_rst_n;
    
    always_ff @(posedge FPGA_clk) begin
        // Register internal signal to chip IO
        chip_rst_n            <= FPGA_rst_n;
        chip_pkt_i            <= FPGA_pkt_i;
        chip_fifo_rx_enqueue  <= FPGA_fifo_rx_enqueue;
        chip_fifo_tx_dequeue  <= FPGA_fifo_tx_dequeue;
        // Register chip IO to internal signal
        FPGA_fifo_rx_full     <= chip_fifo_rx_full;
        FPGA_fifo_tx_empty    <= chip_fifo_tx_empty;
        FPGA_pkt_o            <= chip_pkt_o;
        FPGA_pkt_o_valid      <= chip_pkt_o_valid;
        FPGA_reg_o            <= chip_reg_o;
        FPGA_power_test_o     <= chip_power_test_o;
        
    end
    
endmodule
