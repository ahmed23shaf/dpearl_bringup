`include "mk_pkt.svh"
import rl_types::*;

module test_controller (
    input   logic               clk,
    input   logic               rst_n,
    input   logic               step_advance, // signal from push button to step forward the state machine

    // Output signal to chip
    output  io_in_t             pkt_i,
    output  logic               fifo_rx_enqueue,
    output  logic               fifo_tx_dequeue,

    // Input signal from chip
    input   logic               fifo_rx_full,
    input   logic               fifo_tx_empty,
    input   io_out_t            pkt_o,
    input   logic               pkt_o_valid,
    input   ctrl_status_reg_t   reg_o,
    input   logic               power_test_o,

    // Output signal to LED to show status
    output  logic               test_done,
    output  logic               test_pass,
    output  logic               dist_done,
    output  logic               dist_pass,
    output  logic               tb_done,
    output  logic               tb_pass,
    output  logic [5:0]         testctrl_state
);

    typedef enum logic [5:0] {
        ST_BOOT              = 6'b000000, // LED FIFO page = 0x00
        ST_SEND_CFG          = 6'b000001, // LED FIFO page = 0x01
        ST_WAIT_CFG          = 6'b000010, // LED FIFO page = 0x02
        ST_SEND_INDEL        = 6'b000011, // LED FIFO page = 0x03
        ST_WAIT_INDEL        = 6'b000100, // LED FIFO page = 0x04
        ST_SEND_INIT_SRAM    = 6'b000101, // LED FIFO page = 0x05
        ST_WAIT_INIT_SRAM    = 6'b000110, // LED FIFO page = 0x06
        ST_SEND_SRAM         = 6'b000111, // LED FIFO page = 0x07
        ST_ADVANCE_SRAM      = 6'b001000, // LED FIFO page = 0x08
        ST_SEND_STOP_SRAM    = 6'b001001, // LED FIFO page = 0x09
        ST_WAIT_SRAM_DONE    = 6'b001010, // LED FIFO page = 0x0A
        ST_SEND_LOAD_SEQ     = 6'b001011, // LED FIFO page = 0x0B
        ST_WAIT_LOAD_SEQ     = 6'b001100, // LED FIFO page = 0x0C
        ST_SEND_P            = 6'b001101, // LED FIFO page = 0x0D
        ST_ADVANCE_P         = 6'b001110, // LED FIFO page = 0x0E
        ST_WAIT_P_DONE       = 6'b001111, // LED FIFO page = 0x0F
        ST_SEND_Q            = 6'b010000, // LED FIFO page = 0x10
        ST_ADVANCE_Q         = 6'b010001, // LED FIFO page = 0x11
        ST_WAIT_Q_DONE       = 6'b010010, // LED FIFO page = 0x12
        ST_SEND_INIT_GRID    = 6'b010011, // LED FIFO page = 0x13
        ST_WAIT_GRID_DONE    = 6'b010100, // LED FIFO page = 0x14
        ST_SEND_RUN          = 6'b010101, // LED FIFO page = 0x15
        ST_WAIT_RESULT_READY = 6'b010110, // LED FIFO page = 0x16
        ST_SEND_GET_RESULTS  = 6'b010111, // LED FIFO page = 0x17
        ST_WAIT_TX_DATA      = 6'b011000, // LED FIFO page = 0x18
        ST_ASSERT_TX_DEQ     = 6'b011001, // LED FIFO page = 0x19
        ST_WAIT_RESULT_PKT   = 6'b011010, // LED FIFO page = 0x1A
        ST_WAIT_RESULT_STEP  = 6'b011011, // LED FIFO page = 0x1B
        ST_SEND_OUTPUT_TB    = 6'b011100, // LED FIFO page = 0x1C
        ST_WAIT_TB_TX_DATA   = 6'b011101, // LED FIFO page = 0x1D
        ST_ASSERT_TB_DEQ     = 6'b011110, // LED FIFO page = 0x1E
        ST_WAIT_TB_PKT       = 6'b011111, // LED FIFO page = 0x1F
        ST_WAIT_TB_STEP      = 6'b100000, // LED FIFO page = 0x20
        ST_SEND_RESET_GRID   = 6'b100001, // LED FIFO page = 0x21
        ST_WAIT_RESET_DONE   = 6'b100010, // LED FIFO page = 0x22
        ST_DONE              = 6'b100011  // LED FIFO page = 0x23
    } state_t;

    localparam int BOOT_DELAY_CYCLES = 8;
    localparam int NUM_TEST_BASES = 20;
    localparam int NUM_TEST_SCORES = (NUM_TEST_BASES * (NUM_TEST_BASES + 1)) / 2;
    localparam int NUM_SRAM_PKTS = (NUM_TEST_SCORES + 1) / 2;
    localparam int NUM_SEQ_PKTS = (SEQ_LEN + 1) / 2;

    localparam logic TEST_STREAM_MODE = 1'b0;
    localparam logic TEST_TB_EN = 1'b1;
    localparam logic [DELAY_WIDTH-1:0] TEST_INDEL = 'd10;
    localparam logic [DISTANCE_WIDTH_IO-1:0] EXPECTED_DISTANCE = DISTANCE_WIDTH_IO'('d325);
    localparam int EXPECTED_TB_LEN = 31;

    localparam logic [DELAY_WIDTH-1:0] TEST_SCORES [0:NUM_TEST_SCORES-1] = '{
        'd8, 'd13, 'd7, 'd14, 'd12, 'd6, 'd14, 'd14, 'd11, 'd6, 'd12, 'd15,
        'd15, 'd15, 'd3, 'd13, 'd11, 'd12, 'd12, 'd15, 'd7, 'd13, 'd12, 'd12,
        'd10, 'd16, 'd10, 'd7, 'd12, 'd14, 'd12, 'd13, 'd15, 'd14, 'd14, 'd6,
        'd14, 'd12, 'd11, 'd13, 'd15, 'd12, 'd12, 'd14, 'd4, 'd13, 'd15, 'd15,
        'd15, 'd13, 'd15, 'd15, 'd16, 'd15, 'd8, 'd13, 'd14, 'd15, 'd16, 'd13,
        'd14, 'd15, 'd16, 'd15, 'd10, 'd8, 'd13, 'd10, 'd12, 'd13, 'd15, 'd11,
        'd11, 'd14, 'd13, 'd15, 'd14, 'd7, 'd13, 'd13, 'd14, 'd15, 'd13, 'd12,
        'd14, 'd15, 'd14, 'd11, 'd10, 'd13, 'd7, 'd14, 'd15, 'd15, 'd15, 'd14,
        'd15, 'd15, 'd15, 'd13, 'd12, 'd12, 'd15, 'd12, 'd6, 'd13, 'd14, 'd14,
        'd13, 'd15, 'd13, 'd13, 'd14, 'd14, 'd15, 'd15, 'd13, 'd14, 'd16, 'd5,
        'd11, 'd13, 'd11, 'd12, 'd13, 'd12, 'd12, 'd12, 'd13, 'd14, 'd14, 'd12,
        'd13, 'd14, 'd13, 'd8, 'd12, 'd13, 'd12, 'd13, 'd13, 'd13, 'd13, 'd14,
        'd14, 'd13, 'd13, 'd13, 'd13, 'd14, 'd13, 'd11, 'd7, 'd15, 'd15, 'd16,
        'd16, 'd14, 'd14, 'd15, 'd14, 'd14, 'd15, 'd14, 'd15, 'd13, 'd11, 'd16,
        'd15, 'd14, 'd1, 'd14, 'd14, 'd14, 'd15, 'd14, 'd13, 'd14, 'd15, 'd10,
        'd13, 'd13, 'd14, 'd13, 'd9, 'd15, 'd14, 'd14, 'd10, 'd5, 'd12, 'd15,
        'd15, 'd15, 'd13, 'd14, 'd14, 'd15, 'd15, 'd9, 'd11, 'd14, 'd11, 'd13,
        'd14, 'd14, 'd12, 'd15, 'd13, 'd8
    };

    localparam char_t TEST_P_SEQ [0:SEQ_LEN-1] = '{
        char_t'(0),  char_t'(3),  char_t'(10), char_t'(5),  char_t'(7),  char_t'(16),
        char_t'(14), char_t'(11), char_t'(12), char_t'(17), char_t'(19), char_t'(4),
        char_t'(8),  char_t'(18), char_t'(1),  char_t'(9),  char_t'(15), char_t'(13),
        char_t'(6),  char_t'(2),  char_t'(2),  char_t'(19), char_t'(7),  char_t'(16),
        char_t'(10), char_t'(9),  char_t'(0)
    };

    localparam char_t TEST_Q_SEQ [0:SEQ_LEN-1] = '{
        char_t'(1),  char_t'(7),  char_t'(12), char_t'(18), char_t'(5),  char_t'(16),
        char_t'(14), char_t'(13), char_t'(0),  char_t'(10), char_t'(8),  char_t'(2),
        char_t'(15), char_t'(19), char_t'(6),  char_t'(3),  char_t'(9),  char_t'(4),
        char_t'(17), char_t'(11), char_t'(10), char_t'(1),  char_t'(3),  char_t'(7),
        char_t'(18), char_t'(16), char_t'(0)
    };
    localparam tbk_t EXPECTED_TB_STREAM [0:EXPECTED_TB_LEN-1] = '{
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b1, tl: 1'b0, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b0, top: 1'b1, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b0, top: 1'b1, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b0, top: 1'b1, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b1, tl: 1'b0, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b1, tl: 1'b0, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b1, top: 1'b0, disabled: 1'b0},
        tbk_t'{left: 1'b0, tl: 1'b0, top: 1'b0, disabled: 1'b0}
    };

    state_t state, state_next;

    logic [$clog2(BOOT_DELAY_CYCLES + 1)-1:0] boot_count, boot_count_next;
    logic [$clog2(NUM_SRAM_PKTS + 1)-1:0] sram_pkt_idx, sram_pkt_idx_next;
    logic [$clog2(NUM_SEQ_PKTS + 1)-1:0] p_pkt_idx, p_pkt_idx_next;
    logic [$clog2(NUM_SEQ_PKTS + 1)-1:0] q_pkt_idx, q_pkt_idx_next;
    logic [$clog2(EXPECTED_TB_LEN + 1)-1:0] tb_pkt_idx, tb_pkt_idx_next;

    io_in_t pkt_i_next;
    logic fifo_rx_enqueue_next;
    logic fifo_tx_dequeue_next;

    logic [DISTANCE_WIDTH_IO-1:0] result_distance, result_distance_next;
    logic result_valid_seen, result_valid_seen_next;
    logic dist_done_next;
    logic dist_pass_next;
    logic tb_done_next;
    logic tb_pass_next;

    function automatic io_in_t mk_test_reg_pkt();
        ctrl_status_reg_t reg_cfg;
        reg_cfg = '0;
        reg_cfg.stream_mode = TEST_STREAM_MODE;
        reg_cfg.tb_en = TEST_TB_EN;
        return mk_reg_pkt(reg_cfg);
    endfunction

    function automatic logic [DELAY_WIDTH-1:0] test_sram_score(int score_idx);
        return TEST_SCORES[score_idx];
    endfunction

    function automatic io_in_t mk_test_sram_pkt(int pkt_idx);
        int score_idx;
        io_in_t pkt;

        score_idx = pkt_idx * 2;
        if ((score_idx + 1) < NUM_TEST_SCORES)
            pkt = mk_sram_pkt(test_sram_score(score_idx), test_sram_score(score_idx + 1), 1'b1);
        else
            pkt = mk_sram_pkt(test_sram_score(score_idx), '0, 1'b0);

        return pkt;
    endfunction

    function automatic char_t test_seq_char(seq_e id, int char_idx);
        if (id == SEQ_P)
            return TEST_P_SEQ[char_idx];
        else
            return TEST_Q_SEQ[char_idx];
    endfunction

    function automatic io_in_t mk_test_seq_pkt(seq_e id, int pkt_idx);
        int char_idx;
        logic tail_pkt;

        tail_pkt = (pkt_idx == (NUM_SEQ_PKTS - 1)) && ((SEQ_LEN % 2) == 1);
        char_idx = SEQ_LEN - 2 - (2 * pkt_idx);

        if (tail_pkt)
            return mk_seq_pkt(id, test_seq_char(id, 0), '0, 1'b0);

        return mk_seq_pkt(
            id,
            test_seq_char(id, char_idx + 1),
            test_seq_char(id, char_idx),
            1'b1
        );
    endfunction

    always_comb begin
        state_next = state;
        boot_count_next = boot_count;
        sram_pkt_idx_next = sram_pkt_idx;
        p_pkt_idx_next = p_pkt_idx;
        q_pkt_idx_next = q_pkt_idx;
        tb_pkt_idx_next = tb_pkt_idx;
        result_distance_next = result_distance;
        result_valid_seen_next = result_valid_seen;
        dist_done_next = dist_done;
        dist_pass_next = dist_pass;
        tb_done_next = tb_done;
        tb_pass_next = tb_pass;

        pkt_i_next = pkt_i;
        fifo_rx_enqueue_next = 1'b0;
        fifo_tx_dequeue_next = 1'b0;

        unique case (state)
            ST_BOOT: begin
                if (boot_count == BOOT_DELAY_CYCLES - 1)
                    state_next = ST_SEND_CFG;
                else
                    boot_count_next = boot_count + 1'b1;
            end

            ST_SEND_CFG: begin
                if (!fifo_rx_full) begin
                    pkt_i_next = mk_test_reg_pkt();
                    fifo_rx_enqueue_next = 1'b1;
                    state_next = ST_WAIT_CFG;
                end
            end

            ST_WAIT_CFG: begin
                // Major-group step point: one button push starts the indel transaction.
                if (step_advance)
                    state_next = ST_SEND_INDEL;
            end

            ST_SEND_INDEL: begin
                if (!fifo_rx_full) begin
                    pkt_i_next = mk_indel_pkt(TEST_INDEL);
                    fifo_rx_enqueue_next = 1'b1;
                    state_next = ST_WAIT_INDEL;
                end
            end

            ST_WAIT_INDEL: begin
                // Wait for indel load to finish, then wait for the next step push.
                if (reg_o.indel_loaded && step_advance)
                    state_next = ST_SEND_INIT_SRAM;
            end

            ST_SEND_INIT_SRAM: begin
                if (!fifo_rx_full) begin
                    pkt_i_next = mk_cmd_pkt(INIT_SRAM_OP);
                    fifo_rx_enqueue_next = 1'b1;
                    state_next = ST_WAIT_INIT_SRAM;
                end
            end

            ST_WAIT_INIT_SRAM: begin
                // Major-group step point: one button push starts the full SRAM burst load.
                if (step_advance)
                    state_next = ST_SEND_SRAM;
            end

            ST_SEND_SRAM: begin
                if (!fifo_rx_full) begin
                    pkt_i_next = mk_test_sram_pkt(sram_pkt_idx);
                    fifo_rx_enqueue_next = 1'b1;
                    state_next = ST_ADVANCE_SRAM;
                end
            end

            ST_ADVANCE_SRAM: begin
                if (sram_pkt_idx == NUM_SRAM_PKTS - 1)
                    state_next = ST_SEND_STOP_SRAM;
                else begin
                    sram_pkt_idx_next = sram_pkt_idx + 1'b1;
                    state_next = ST_SEND_SRAM;
                end
            end

            ST_SEND_STOP_SRAM: begin
                if (!fifo_rx_full) begin
                    pkt_i_next = mk_cmd_pkt(STOP_SRAM_OP);
                    fifo_rx_enqueue_next = 1'b1;
                    state_next = ST_WAIT_SRAM_DONE;
                end
            end

            ST_WAIT_SRAM_DONE: begin
                // Wait for SRAM load completion, then wait for a step push to load sequences.
                if (reg_o.sram_loaded && step_advance)
                    state_next = ST_SEND_LOAD_SEQ;
            end

            ST_SEND_LOAD_SEQ: begin
                if (!fifo_rx_full) begin
                    pkt_i_next = mk_cmd_pkt(LOAD_SEQ_OP);
                    fifo_rx_enqueue_next = 1'b1;
                    state_next = ST_WAIT_LOAD_SEQ;
                end
            end

            ST_WAIT_LOAD_SEQ: begin
                // Major-group step point: one button push sends the full P sequence burst.
                if (step_advance)
                    state_next = ST_SEND_P;
            end

            ST_SEND_P: begin
                if (!fifo_rx_full) begin
                    pkt_i_next = mk_test_seq_pkt(SEQ_P, p_pkt_idx);
                    fifo_rx_enqueue_next = 1'b1;
                    state_next = ST_ADVANCE_P;
                end
            end

            ST_ADVANCE_P: begin
                if (p_pkt_idx == NUM_SEQ_PKTS - 1)
                    state_next = ST_WAIT_P_DONE;
                else begin
                    p_pkt_idx_next = p_pkt_idx + 1'b1;
                    state_next = ST_SEND_P;
                end
            end

            ST_WAIT_P_DONE: begin
                // Wait for full P load completion, then step into the Q burst.
                if (reg_o.seq_p_loaded && step_advance)
                    state_next = ST_SEND_Q;
            end

            ST_SEND_Q: begin
                if (!fifo_rx_full) begin
                    pkt_i_next = mk_test_seq_pkt(SEQ_Q, q_pkt_idx);
                    fifo_rx_enqueue_next = 1'b1;
                    state_next = ST_ADVANCE_Q;
                end
            end

            ST_ADVANCE_Q: begin
                if (q_pkt_idx == NUM_SEQ_PKTS - 1)
                    state_next = ST_WAIT_Q_DONE;
                else begin
                    q_pkt_idx_next = q_pkt_idx + 1'b1;
                    state_next = ST_SEND_Q;
                end
            end

            ST_WAIT_Q_DONE: begin
                // Wait for full Q load completion, then step into grid initialization.
                if (reg_o.seq_q_loaded && step_advance)
                    state_next = ST_SEND_INIT_GRID;
            end

            ST_SEND_INIT_GRID: begin
                if (!fifo_rx_full) begin
                    pkt_i_next = mk_cmd_pkt(INIT_GRID_OP);
                    fifo_rx_enqueue_next = 1'b1;
                    state_next = ST_WAIT_GRID_DONE;
                end
            end

            ST_WAIT_GRID_DONE: begin
                // Wait for grid initialization to finish, then step into RUN.
                if (reg_o.grid_initialized && step_advance)
                    state_next = ST_SEND_RUN;
            end

            ST_SEND_RUN: begin
                if (!fifo_rx_full) begin
                    pkt_i_next = mk_cmd_pkt(RUN_OP);
                    fifo_rx_enqueue_next = 1'b1;
                    state_next = ST_WAIT_RESULT_READY;
                end
            end

            ST_WAIT_RESULT_READY: begin
                // Wait for computation completion, then step into result readback.
                if (reg_o.result_ready && step_advance)
                    state_next = ST_SEND_GET_RESULTS;
            end

            ST_SEND_GET_RESULTS: begin
                if (!fifo_rx_full) begin
                    pkt_i_next = mk_cmd_pkt(GET_RESULTS_OP);
                    fifo_rx_enqueue_next = 1'b1;
                    state_next = ST_WAIT_TX_DATA;
                end
            end

            ST_WAIT_TX_DATA: begin
                if (!fifo_tx_empty)
                    state_next = ST_ASSERT_TX_DEQ;
            end

            ST_ASSERT_TX_DEQ: begin
                fifo_tx_dequeue_next = 1'b1;
                state_next = ST_WAIT_RESULT_PKT;
            end

            ST_WAIT_RESULT_PKT: begin
                if (pkt_o_valid) begin
                    if ((pkt_o.type_o == RESULT) && (pkt_o.result.ret_t == DISTANCE_O)) begin
                        result_distance_next = pkt_o.result.payload.distance;
                        result_valid_seen_next = 1'b1;
                        dist_done_next = 1'b1;
                        if (pkt_o.result.payload.distance != EXPECTED_DISTANCE)
                            dist_pass_next = 1'b0;
                    end
                    state_next = ST_WAIT_RESULT_STEP;
                end
            end

            ST_WAIT_RESULT_STEP: begin
                if (step_advance) begin
                    if (TEST_TB_EN)
                        state_next = ST_SEND_OUTPUT_TB;
                    else
                        state_next = ST_SEND_RESET_GRID;
                end
            end

            ST_SEND_OUTPUT_TB: begin
                if (!fifo_rx_full) begin
                    pkt_i_next = mk_cmd_pkt(OUTPUT_TB_OP);
                    fifo_rx_enqueue_next = 1'b1;
                    state_next = ST_WAIT_TB_TX_DATA;
                end
            end

            ST_WAIT_TB_TX_DATA: begin
                if (!fifo_tx_empty)
                    state_next = ST_ASSERT_TB_DEQ;
            end

            ST_ASSERT_TB_DEQ: begin
                fifo_tx_dequeue_next = 1'b1;
                state_next = ST_WAIT_TB_PKT;
            end

            ST_WAIT_TB_PKT: begin
                if (pkt_o_valid) begin
                    if ((pkt_o.type_o == RESULT) && (pkt_o.result.ret_t == TB_O)) begin
                        if ((tb_pkt_idx >= EXPECTED_TB_LEN) ||
                            (pkt_o.result.payload.tb.dir != EXPECTED_TB_STREAM[tb_pkt_idx]))
                            tb_pass_next = 1'b0;

                        if (tb_pkt_idx == (EXPECTED_TB_LEN - 1)) begin
                            tb_done_next = 1'b1;
                            state_next = ST_WAIT_TB_STEP;
                        end
                        else begin
                            tb_pkt_idx_next = tb_pkt_idx + 1'b1;
                            state_next = ST_WAIT_TB_TX_DATA;
                        end
                    end
                end
            end

            ST_WAIT_TB_STEP: begin
                if (step_advance)
                    state_next = ST_SEND_RESET_GRID;
            end

            ST_SEND_RESET_GRID: begin
                if (!fifo_rx_full) begin
                    pkt_i_next = mk_cmd_pkt(RESET_GRID_OP);
                    fifo_rx_enqueue_next = 1'b1;
                    state_next = ST_WAIT_RESET_DONE;
                end
            end

            ST_WAIT_RESET_DONE: begin
                if (!reg_o.seq_p_loaded && !reg_o.seq_q_loaded &&
                    !reg_o.grid_initialized && !reg_o.result_ready)
                    state_next = ST_DONE;
            end

            ST_DONE: begin
                state_next = ST_DONE;
            end

            default: begin
                state_next = ST_BOOT;
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_BOOT;
            boot_count <= '0;
            sram_pkt_idx <= '0;
            p_pkt_idx <= '0;
            q_pkt_idx <= '0;
            tb_pkt_idx <= '0;
            result_distance <= '0;
            result_valid_seen <= 1'b0;
            dist_done <= 1'b0;
            dist_pass <= 1'b1;
            tb_done <= 1'b0;
            tb_pass <= 1'b1;
            test_done <= 1'b0;
            test_pass <= 1'b0;
            testctrl_state <= '0;
            pkt_i <= '0;
            fifo_rx_enqueue <= 1'b0;
            fifo_tx_dequeue <= 1'b0;
        end
        else begin
            state <= state_next;
            boot_count <= boot_count_next;
            sram_pkt_idx <= sram_pkt_idx_next;
            p_pkt_idx <= p_pkt_idx_next;
            q_pkt_idx <= q_pkt_idx_next;
            tb_pkt_idx <= tb_pkt_idx_next;
            result_distance <= result_distance_next;
            result_valid_seen <= result_valid_seen_next;
            dist_done <= dist_done_next;
            dist_pass <= dist_pass_next;
            tb_done <= tb_done_next;
            tb_pass <= tb_pass_next;
            test_done <= dist_done_next & tb_done_next;
            test_pass <= dist_done_next & tb_done_next & dist_pass_next & tb_pass_next;
            testctrl_state <= state_next;
            pkt_i <= pkt_i_next;
            fifo_rx_enqueue <= fifo_rx_enqueue_next;
            fifo_tx_dequeue <= fifo_tx_dequeue_next;
        end
    end

endmodule : test_controller
