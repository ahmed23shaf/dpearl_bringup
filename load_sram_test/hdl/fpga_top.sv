import rl_types::*;
import io_convert::*;

module fpga_top (
    input  logic        clk125_p,          // AY24
    input  logic        clk125_n,          // AY23

    // ------- FPGA User I/O -------
    output logic [7:0] gpio_led,

    // Push buttons -- active high
    input logic gpio_sw_e,
    input logic cpu_reset,

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
            // !!!!!!!!!!!!!!! SET DESIRED score matrix for ATCG HERE !!!!!!!!!!!!!!!
            logic [DELAY_WIDTH-1:0] score_mat [10]; // 10 entries for 4x4 lower triangular (AA, TA, TT, CA, CT, CC, GA, GT, GC, GG)
            always_comb begin
                score_mat[0] = 5'd1; // AA
                score_mat[1] = 5'd2; // TA
                score_mat[2] = 5'd3; // TT
                score_mat[3] = 5'd4; // CA
                score_mat[4] = 5'd5; // CT
                score_mat[5] = 5'd6; // CC
                score_mat[6] = 5'd7; // GA
                score_mat[7] = 5'd8; // GT
                score_mat[8] = 5'd9; // GC
                score_mat[9] = 5'd10; // GG
            end

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
            logic gpio_sw_e_sync, cpu_reset_sync;

            //      FPGA control states
            typedef enum logic { 
                IDLE_F,           // 0
                STORE_SRAM     // 1
            } fpga_state_e;

            fpga_state_e state, state_next;
            logic [10:0] ctr, ctr_next; // TODO use of counters to stall in states
            logic [7:0]  score_matrix_idx, score_matrix_idx_next;


    // ======== FPGA FSM  ========
    always_ff @ (posedge clk) begin : STATE_FF
       state <= rst ? IDLE_F:state_next; 
       ctr <= rst ? '0:ctr_next;
       score_matrix_idx <= rst ? '0:score_matrix_idx_next;
    end

    always_comb begin   // Next state & output
        state_next = state;

        chip_rx_enqueue_next = 1'b0;
        chip_tx_dequeue_next = 1'b0;

        chip_pkt_i_next      = '0;

        ctr_next = '0;
        score_matrix_idx_next = '0;

        case (state)
            IDLE_F: begin
                if (gpio_e_posedge)
                    state_next = STORE_SRAM;
            end 
            STORE_SRAM: begin
                ctr_next = ctr + 1'b1;
                score_matrix_idx_next = score_matrix_idx;
                // TODO use fifo_rx_full_reg before sending pkt
                if (ctr == '0) begin
                    chip_pkt_i_next = mk_cmd_pkt(INIT_SRAM_OP);
                    chip_rx_enqueue_next = 1'b1;
                end
                else if (ctr[2:0] == 3'b0) begin // send a packet every 8 cycles (ctr modulo 8 == 0)

                    if (score_matrix_idx == 8'd210) begin // reached last entry
                        state_next = IDLE_F;

                        chip_pkt_i_next = mk_cmd_pkt(STOP_SRAM_OP);
                    end
                    else if ((8'd0 <= score_matrix_idx) && (score_matrix_idx < 8'd9)) begin  // if between indicies 0-9 (inclusive, for ATCG score matrix)
                        chip_pkt_i_next = mk_sram_pkt(score_mat[score_matrix_idx],
                                                      score_mat[score_matrix_idx+1],
                                                      1'b1);

                    end
                    else begin
                        chip_pkt_i_next = mk_sram_pkt(5'hFF,
                                                      5'hFF,
                                                      1'b1);
                    end
                    chip_rx_enqueue_next = 1'b1;
                    score_matrix_idx_next = score_matrix_idx + 2'd2;
                end
            end
        endcase
    end

    // ======== Assign LEDs  ========
    always_ff @ (posedge clk) begin : LEDs
        if (rst)
            gpio_led <= '0;
        else begin
            gpio_led[0] <= {chip_reg_o_reg.sram_loaded};
            gpio_led[1] <= gpio_sw_e_sync;
            gpio_led[2] <= chip_power_test_o_reg;
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
    sync_debounce sync_e (.clk(clk), .d(gpio_sw_e), .q(gpio_sw_e_sync));
    sync_debounce sync_reset (.clk(clk), .d(cpu_reset), .q(cpu_reset_sync));

    posedge_detector posedge_pb_e(.clk, .d(gpio_sw_e_sync), .q(gpio_e_posedge));

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