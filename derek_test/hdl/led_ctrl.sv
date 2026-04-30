import LED_pkg::*;

module LED_ctrl(
    input  logic             clk,
    input  logic             rst_n,
    input  logic             led_page_switch,   // 1-cycle pulse

    // signals to observe
    input  ctrl_status_reg_t ctrl,
    input  logic             fifo_rx_full,
    input  logic             fifo_tx_empty,
    input  logic             power_test,
    input  logic [5:0]       testctrl_state,
    input  logic             test_done,
    input  logic             test_pass,
    input  logic             dist_done,
    input  logic             dist_pass,
    input  logic             tb_done,
    input  logic             tb_pass,
    
    // output led
    output LED_t             LED
);

    // ============================================================
    // Page FSM
    // ============================================================
    LED_page_e page, page_next;

    always_ff @(posedge clk) begin
        if (!rst_n)
            page <= LED_PAGE_MODE;
        else
            page <= page_next;
    end

    always_comb begin
        page_next = page;

        if (led_page_switch) begin
            case (page)
                LED_PAGE_MODE:   page_next = LED_PAGE_STATUS;
                LED_PAGE_STATUS: page_next = LED_PAGE_FIFO;
                LED_PAGE_FIFO:   page_next = LED_PAGE_POWER;
                LED_PAGE_POWER:  page_next = LED_PAGE_MODE;
                default:         page_next = LED_PAGE_MODE;
            endcase
        end
    end

    // ============================================================
    // LED Mapping
    // ============================================================
    LED_t LED_out;

    always_comb begin
        LED_out = '0;
        LED_out.page = page;

        case (page)

            // MODE PAGE
            LED_PAGE_MODE: begin
                // MODE page now also carries a constant power-good bit.
                // LED[7:6] = 2'b00 selects MODE page.
                // LED[5:3] = unused
                // LED[2]   = power_test
                // LED[1]   = tb_en
                // LED[0]   = stream_mode
                LED_out.status.mode.tb_en       = ctrl.tb_en;
                LED_out.status.mode.stream_mode = ctrl.stream_mode;
                LED_out.status.mode.power_test  = power_test;
            end

            // STATUS PAGE
            LED_PAGE_STATUS: begin
                LED_out.status.status = '{
                    indel_loaded:     ctrl.indel_loaded,
                    sram_loaded:      ctrl.sram_loaded,
                    seq_p_loaded:     ctrl.seq_p_loaded,
                    seq_q_loaded:     ctrl.seq_q_loaded,
                    grid_initialized: ctrl.grid_initialized,
                    result_ready:     ctrl.result_ready
                };
            end

            // FIFO PAGE
            LED_PAGE_FIFO: begin
                // Temporary test-controller state page during bring-up.
                // LED[7:6] = 2'b10 selects this page.
                // LED[5:0] = current test_controller state enum value.
                LED_out.status.testctrl_state = testctrl_state;
            end

            // POWER PAGE
            LED_PAGE_POWER: begin
                // Temporary self-test summary page for the fixed BLOSUM vector.
                // LED[7:6] = 2'b11 selects POWER page.
                // LED[5]   = test_done  : distance and traceback comparisons both completed
                // LED[4]   = test_pass  : overall pass (distance pass && traceback pass)
                // LED[3]   = dist_done  : distance packet was received and checked
                // LED[2]   = dist_pass  : distance matched the expected golden value
                // LED[1]   = tb_done    : traceback stream was fully received and checked
                // LED[0]   = tb_pass    : traceback stream matched the expected golden path
                LED_out.status.power = '{
                    test_done : test_done,
                    test_pass : test_pass,
                    dist_done : dist_done,
                    dist_pass : dist_pass,
                    tb_done   : tb_done,
                    tb_pass   : tb_pass
                };
            end

        endcase
    end

    assign LED = LED_out;

endmodule
