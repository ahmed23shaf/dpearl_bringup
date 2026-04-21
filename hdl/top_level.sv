import rl_types::*;

module top_level (
    // CLOCK signal
    input  logic        clk125_p,          // AY24
    input  logic        clk125_n,          // AY23
    
    // Board signal
    input  logic        BOARD_reset,             // L19 -- ACTIVE HIGH
    input  logic        BOARD_LED_button,
    output logic [7:0]  BOARD_LED,
    
    // TX RX UART signal
    input  logic        UART_TX,
    output logic        UART_RX,
    
    // FPGA --> Chip
    output logic        chip_clk,
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
    input  logic                chip_power_test_o

    
);
    
    // ==== Clocking & Reset ====
    logic       clk;
    logic       clk_locked;
    logic       rst_sync;
    logic       rst_n_sync;
    // ==== FPGA internal signals ====
    io_in_t     FPGA_pkt_i;
    logic       FPGA_rx_enqueue;
    logic       FPGA_tx_dequeue;
    
    logic       FPGA_fifo_rx_full;
    logic       FPGA_fifo_tx_empty;
    io_out_t    FPGA_pkt_o;
    logic       FPGA_pkt_o_valid;
    logic       FPGA_reg_o;
    logic       FPGA_power_test_o;

    // ==== LED controller ====
    logic       led_page_switch;
    
    // Reset button debouncer
    sync_debounce u_debouncer_rst (
        .clk(clk), 
        .mode_sel(1'b1),
        .d(BOARD_reset & clk_locked), // Ensure rst_sync generated when clock is stable
        .q(rst_sync)
    );

    assign rst_n_sync = ~rst_sync;
    
    // LED page switch button debouncer
    sync_debounce u_debouncer_led (
        .clk(clk),
        .mode_sel(1'b1),
        .d(BOARD_LED_button & clk_locked),// Ensure led_page_switch generated when clock is stable
        .q(led_page_switch)
    );

    // Differential --> Single ended clock generator
    clock_source u_clock (
        .sysclk_125_clk_n(clk125_n),
        .sysclk_125_clk_p(clk125_p),
        .reset(BOARD_reset),
        .clk_locked(clk_locked),
        .clk_out_200(clk)
    );
    
    // Register the signal from chip 
    ASIC_io_reg u_ASIC_io_reg (
        // FPGA --> Chip
        .chip_clk(chip_clk),
        .chip_rst_n(chip_rst_n),
    
        .chip_pkt_i(chip_pkt_i),
        .chip_rx_enqueue(chip_rx_enqueue),
        .chip_tx_dequeue(chip_tx_dequeue),
    
        // Chip --> FPGA
        .chip_fifo_rx_full(chip_fifo_rx_full),
        .chip_fifo_tx_empty(chip_fifo_tx_empty),
    
        .chip_pkt_o(chip_pkt_o),        
        .chip_pkt_o_valid(chip_pkt_o_valid),  
        
        .chip_reg_o(chip_reg_o),
        .chip_power_test_o(chip_power_test_o),
        
        // Internal signal
        .FPGA_clk(clk),
        .FPGA_rst_n(~rst_sync),
        .FPGA_pkt_i(FPGA_pkt_i),
        .FPGA_rx_enqueue(FPGA_rx_enqueue),
        .FPGA_tx_dequeue(FPGA_tx_dequeue),
        
        .FPGA_fifo_rx_full(FPGA_fifo_rx_full),
        .FPGA_fifo_tx_empty(FPGA_fifo_tx_empty),
        .FPGA_pkt_o(FPGA_pkt_o),
        .FPGA_pkt_o_valid(FPGA_pkt_o_valid),
        .FPGA_reg_o(FPGA_reg_o),
        .FPGA_power_test_o(FPGA_power_test_o)
    );
    
    // LED status controller
    LED_ctrl u_led_ctrl (
        .clk(clk),
        .rst_n(rst_n_sync),
        .led_page_switch(led_page_switch),
        .ctrl(FPGA_reg_o),
        .fifo_rx_full(FPGA_fifo_rx_full),
        .fifo_tx_empty(FPGA_fifo_tx_empty),
        .power_test(FPGA_power_test_o)
    );
    
    // Controller
    
    

endmodule : top_level
