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
                LED_out.status.mode.tb_en       = ctrl.tb_en;
                LED_out.status.mode.stream_mode = ctrl.stream_mode;
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
                LED_out.status.fifo.fifo_rx_full  = fifo_rx_full;
                LED_out.status.fifo.fifo_tx_empty = fifo_tx_empty;
            end

            // POWER PAGE
            LED_PAGE_POWER: begin
                LED_out.status.power.power_test = power_test;
            end

        endcase
    end

    assign LED = LED_out;

endmodule