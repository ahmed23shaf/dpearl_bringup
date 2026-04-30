import rl_types::*;
import io_convert::*;

module fpga_top (
    input  logic        clk125_p,          // AY24
    input  logic        clk125_n,          // AY23

    // ------- FPGA User I/O -------
    output logic [7:0] gpio_led,

    // Push buttons -- active high
    input logic gpio_sw_n,
    input logic cpu_reset,

    input logic [3:0] gpio_dip_sw,
    // -----------------------------

    // Chip --> FPGA
    input  logic        chip_fifo_rx_full,
    input  logic        chip_fifo_tx_empty,

    input  logic [12:0] chip_pkt_o,        // From chip pkt_o
    input  logic        chip_pkt_o_valid,  // From chip pkt_o_valid
    
    input  logic [8:0]  chip_reg_o,
    input  logic        chip_power_test_o,

    // FPGA --> Chip
    output logic        chip_clk,
    output logic        chip_rst_n,

    output logic [13:0] chip_pkt_i,
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
            logic       gpio_sw_n_sync, cpu_reset_sync;
            logic [3:0] gpio_dip_sw_sync;

            logic       gpio_sw_n_posedge;

            //      FPGA control states
            typedef enum logic { 
                IDLE_F,           // 0
                STORE_INDEL     // 1
            } fpga_state_e;

            fpga_state_e state, state_next;
            // logic [5:0] ctr, ctr_next; TODO use of counters to stall in states
  

    // ======== FPGA FSM  ========
    always_ff @ (posedge clk) begin : STATE_FF
       state = rst ? IDLE_F:state_next; 
    end

    always_comb begin   // Next state & output
        state_next = state;

        chip_rx_enqueue_next = 1'b0;
        chip_tx_dequeue_next = 1'b0;

        chip_pkt_i_next      = '0;

        // ctr_next = '0;

        case (state)
            IDLE_F: begin
                if (gpio_sw_n_posedge)
                    state_next = STORE_INDEL;
            end 
            STORE_INDEL: begin
                // if (ctr < 6'd1)
                // TODO use fifo_rx_full_reg before sending pkt
                chip_pkt_i_next = mk_indel_pkt({1'b0, gpio_dip_sw_sync});
                chip_rx_enqueue_next = 1'b1;
                state_next = IDLE_F;
            end
        endcase
    end

    // ======== Assign LEDs  ========
    always_ff @ (posedge clk) begin : LEDs
        if (rst)
            gpio_led <= '0;
        else begin
            gpio_led[0] <= chip_reg_o_reg.indel_loaded;
            gpio_led[1] <= gpio_sw_n_sync;
            gpio_led[2] <= chip_power_test_o_reg;

            gpio_led[7:4] <= gpio_dip_sw_sync;
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

    // ======== Input sanitization of switches + push buttons ========
    sync_debounce sync_n (.clk(clk), .d(gpio_sw_n), .q(gpio_sw_n_sync));
    sync_debounce sync_reset (.clk(clk), .d(cpu_reset), .q(cpu_reset_sync));

    generate
        for (genvar i = 0; i < 4; i++) begin
            sync_debounce sync_dip (.clk, .d(gpio_dip_sw[i]), .q(gpio_dip_sw_sync[i]));
        end
    endgenerate

    posedge_detector sw_n_i (.clk, .d(gpio_sw_n_sync), .q(gpio_sw_n_posedge));

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