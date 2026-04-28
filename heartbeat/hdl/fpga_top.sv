import rl_types::*;

module fpga_top (
    input  logic        clk125_p,          // AY24
    input  logic        clk125_n,          // AY23

    // ------- FPGA User I/O -------
    output logic [7:0] gpio_led,

    // Push buttons -- active high
    input logic gpio_sw_n,
    input logic gpio_sw_e,
    input logic gpio_sw_s,
    input logic gpio_sw_w,
    input logic gpio_sw_c,
    input logic cpu_reset,

    // input logic gpio_dip_sw[3:0],
    // -----------------------------

    // Chip --> FPGA
    input  logic                chip_fifo_rx_full,
    input  logic                chip_fifo_tx_empty,

    input  io_out_t             chip_pkt_o,        // From chip pkt_o
    input  logic                chip_pkt_o_valid,  // From chip pkt_o_valid
    
    input  ctrl_status_reg_t    chip_reg_o,
    input  logic                chip_power_test_o,

    // FPGA --> Chip
    output logic        chip_clk,
    output logic        chip_rst_n,

    output io_in_t      chip_pkt_i,
    output logic        chip_rx_enqueue,
    output logic        chip_tx_dequeue
);
            logic clk;
            logic rst;

            //      Chip I/O registers
            io_in_t           chip_pkt_i_next;  //internal signals that will be driven into the output registers
            logic             chip_rx_enqueue_next;
            logic             chip_tx_dequeue_next;
            
            logic             chip_fifo_rx_full_reg;
            logic             chip_fifo_tx_empty_reg;
            io_out_t          chip_pkt_o_reg;
            logic             chip_pkt_o_valid_reg;
            ctrl_status_reg_t chip_reg_o_reg;
            logic             chip_power_test_o_reg;

            //      Synchronized pushbuttons
            logic gpio_sw_n_sync, gpio_sw_e_sync, gpio_sw_s_sync, 
                gpio_sw_w_sync, gpio_sw_c_sync, cpu_reset_sync;


    always_comb begin : TEMPORARY_REMOVE_SOON
        // For now, tie these to constant values so synthesis sees them as driven
        chip_pkt_i_next      = '0; 
        chip_rx_enqueue_next = 1'b0;
        chip_tx_dequeue_next = 1'b0;
    end

    // ======== Assign LEDs  ========
    always_ff @ (posedge clk) begin : LEDs
        if (rst)
            gpio_led <= '0;
        else begin
            gpio_led[0] <= {chip_power_test_o_reg};
            gpio_led[7:3] <= {gpio_sw_n_sync, 
                              gpio_sw_e_sync, 
                              gpio_sw_s_sync, 
                              gpio_sw_w_sync, 
                              gpio_sw_c_sync};
        end
    end


    // ======== Registering chip I/O ========
    always_ff @ (posedge clk) begin : INPUT
        if (rst) begin
            {chip_fifo_rx_full_reg,
             chip_fifo_tx_empty_reg,
             chip_pkt_o_reg,
             chip_pkt_o_valid_reg,
             chip_reg_o_reg,
             chip_power_test_o_reg} <= '0;
        end
        else begin
            chip_fifo_rx_full_reg  <= chip_fifo_rx_full;
            chip_fifo_tx_empty_reg <= chip_fifo_tx_empty;
            chip_pkt_o_reg         <= chip_pkt_o;
            chip_pkt_o_valid_reg   <= chip_pkt_o_valid;
            chip_reg_o_reg         <= chip_reg_o;
            chip_power_test_o_reg  <= chip_power_test_o;
        end
    end

    always_ff @ (posedge clk) begin : OUTPUT
        if (rst) begin
            chip_pkt_i      <= '0;
            chip_rx_enqueue <= 1'b0;
            chip_tx_dequeue <= 1'b0;
        end
        else begin
            chip_pkt_i      <= chip_pkt_i_next;
            chip_rx_enqueue <= chip_rx_enqueue_next;
            chip_tx_dequeue <= chip_tx_dequeue_next;
        end
    end

    // ======== Synch. pushbuttons ========
    sync_debounce sync_n (.clk(clk), .d(gpio_sw_n), .q(gpio_sw_n_sync));
    sync_debounce sync_e (.clk(clk), .d(gpio_sw_e), .q(gpio_sw_e_sync));
    sync_debounce sync_s (.clk(clk), .d(gpio_sw_s), .q(gpio_sw_s_sync));
    sync_debounce sync_w (.clk(clk), .d(gpio_sw_w), .q(gpio_sw_w_sync));
    sync_debounce sync_c (.clk(clk), .d(gpio_sw_c), .q(gpio_sw_c_sync));
    
    sync_debounce sync_reset (.clk(clk), .d(cpu_reset), .q(cpu_reset_sync));

    assign rst = cpu_reset_sync;

    // ======== Clocking & Reset ========
    assign chip_clk = clk;
    assign chip_rst_n = ~rst;

    // Differential --> Single ended clock generator
    IBUFDS u_ibufds_clk125 (
        .I (clk125_p),
        .IB(clk125_n),
        .O (clk) 
    );


endmodule : fpga_top