import rl_types::*;

module top_level (
    // CLOCK signal
    input  logic        clk125_p,          
    input  logic        clk125_n,          
    
    // Board signal
    input  logic        BOARD_reset,             
    input  logic        BOARD_LED_button,
    input  logic        BOARD_step_button,
    output logic [7:0]  BOARD_LED,
    
    // TX RX UART signal
    // input  logic        UART_TX,
    // output logic        UART_RX,
    
    // FPGA --> Chip
    output logic        chip_clk,
    output logic        chip_rst_n,

    output logic [13:0] chip_pkt_i,
    output logic        chip_fifo_rx_enqueue,
    output logic        chip_fifo_tx_dequeue,

    // Chip --> FPGA
    input  logic                chip_fifo_rx_full,
    input  logic                chip_fifo_tx_empty,

    input  logic [12:0]         chip_pkt_o,        
    input  logic                chip_pkt_o_valid,  
    
    input  logic [8:0]          chip_reg_o,
    input  logic                chip_power_test_o

    
);
    
    // ==== Clocking & Reset ====
    logic               clk;
    logic               clk_locked;
    logic               rst_sync;
    logic               rst_n_sync;
    // ==== FPGA internal signals ====
    io_in_t             FPGA_pkt_i;
    logic               FPGA_fifo_rx_enqueue;
    logic               FPGA_fifo_tx_dequeue;
    
    logic               FPGA_fifo_rx_full;
    logic               FPGA_fifo_tx_empty;
    io_out_t            FPGA_pkt_o;
    logic               FPGA_pkt_o_valid;
    ctrl_status_reg_t   FPGA_reg_o;
    logic               FPGA_power_test_o;
    // ==== Test Controller Signals ====
    logic               test_done;
    logic               test_pass;
    logic               dist_done;
    logic               dist_pass;
    logic               tb_done;
    logic               tb_pass;
    logic [5:0]         testctrl_state;
    logic               step_advance;

    // ==== LED controller ====
    logic               led_page_switch;
    
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

    // Step button debouncer. In button mode, sync_debounce returns a clean
    // 1-cycle pulse on each debounced rising edge.
    sync_debounce u_debouncer_step (
        .clk(clk),
        .mode_sel(1'b1),
        .d(BOARD_step_button & clk_locked),
        .q(step_advance)
    );

    // Differential --> Single ended clock generator
    clock u_clock (
        .clk_in1_n(clk125_n),
        .clk_in1_p(clk125_p),
        .reset(BOARD_reset),
        .locked(clk_locked),
        .clk_out1(clk)
    );
       
    
    // Register the signal from chip 
    ASIC_io_reg u_ASIC_io_reg (
        // FPGA --> Chip
        .chip_clk(chip_clk),
        .chip_rst_n(chip_rst_n),
    
        .chip_pkt_i(chip_pkt_i),
        .chip_fifo_rx_enqueue(chip_fifo_rx_enqueue),
        .chip_fifo_tx_dequeue(chip_fifo_tx_dequeue),
    
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
        .FPGA_fifo_rx_enqueue(FPGA_fifo_rx_enqueue),
        .FPGA_fifo_tx_dequeue(FPGA_fifo_tx_dequeue),
        
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
        .power_test(FPGA_power_test_o),
        .testctrl_state(testctrl_state),
        .test_done(test_done),
        .test_pass(test_pass),
        .dist_done(dist_done),
        .dist_pass(dist_pass),
        .tb_done(tb_done),
        .tb_pass(tb_pass),
        .LED(BOARD_LED)
    );
    
    // Controller
    test_controller u_test_controller (
        .clk(clk),
        .rst_n(rst_n_sync),
        .step_advance(step_advance),
        .pkt_i(FPGA_pkt_i),
        .fifo_rx_enqueue(FPGA_fifo_rx_enqueue),
        .fifo_tx_dequeue(FPGA_fifo_tx_dequeue),
        .fifo_rx_full(FPGA_fifo_rx_full),
        .fifo_tx_empty(FPGA_fifo_tx_empty),
        .pkt_o(FPGA_pkt_o),
        .pkt_o_valid(FPGA_pkt_o_valid),
        .reg_o(FPGA_reg_o),
        .power_test_o(FPGA_power_test_o),
        .test_done(test_done),
        .test_pass(test_pass),
        .dist_done(dist_done),
        .dist_pass(dist_pass),
        .tb_done(tb_done),
        .tb_pass(tb_pass),
        .testctrl_state(testctrl_state)
    );

endmodule : top_level
