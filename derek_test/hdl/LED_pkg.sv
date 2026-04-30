package LED_pkg;

    localparam int LED_WIDTH      = 8;
    localparam int LED_PAGE_WIDTH = 2;
    localparam int LED_DATA_WIDTH = LED_WIDTH - LED_PAGE_WIDTH;

    // ============================================================
    // Page selector (2 bits)
    // ============================================================
    typedef enum logic [LED_PAGE_WIDTH-1:0] {
        LED_PAGE_MODE   = 2'b00,
        LED_PAGE_STATUS = 2'b01,
        LED_PAGE_FIFO   = 2'b10,
        LED_PAGE_POWER  = 2'b11
    } LED_page_e;

    // ============================================================
    // Status payload (6 bits total)
    // ============================================================
    typedef union packed {
        // MODE PAGE
        struct packed {
            logic [LED_DATA_WIDTH-3-1:0] pad; // 3 bits
            logic power_test;
            logic tb_en;
            logic stream_mode;
        } mode;

        // STATUS PAGE
        struct packed {
            logic indel_loaded;
            logic sram_loaded;
            logic seq_p_loaded;
            logic seq_q_loaded;
            logic grid_initialized;
            logic result_ready;
        } status;

        // TEST CONTROLLER PAGE
        logic [LED_DATA_WIDTH-1:0] testctrl_state;

        // POWER PAGE
        struct packed {
            logic test_done;
            logic test_pass;
            logic dist_done;
            logic dist_pass;
            logic tb_done;
            logic tb_pass;
        } power;

    } LED_status_t;

    // ============================================================
    // Final LED output (8 bits total)
    // ============================================================
    typedef struct packed {
        LED_page_e   page;    // [7:6]
        LED_status_t status;  // [5:0]
    } LED_t;

endpackage : LED_pkg
