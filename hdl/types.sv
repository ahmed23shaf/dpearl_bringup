package rl_types;

    //      Race logic types
    //

    // ~~~~~~~~~~~~ Parameters ~~~~~~~~~~~~
    localparam SEQ_LEN            = 27;
    localparam NUM_SYMBOLS        = 20;      // 4 for ATCG, 20 for BLOSUM
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    localparam NUM_SYMBOLS_MAX    = 20;     // Upper bound of encodings that are supported
    localparam MIN_DELAY          = 1;
    localparam MAX_DELAY          = 31;
    
    localparam PREFIX_MATCH_SUB = MIN_DELAY; // (-, -) substitution score
    localparam PREFIX_CHAR_SUB  = MAX_DELAY; // (-, a) or (a, -)
    localparam CHAR_POSTFIX_SUB = MIN_DELAY; // (a, *)

    localparam GRID_LEN          = SEQ_LEN + 1;
    localparam NUM_SCORES        = (NUM_SYMBOLS*(NUM_SYMBOLS+1)) / 2; // entries in lower triangular score matrix (including diagonal)
    localparam NUM_SCORES_MAX    = (NUM_SYMBOLS_MAX*(NUM_SYMBOLS_MAX+1)) / 2;
    localparam MAX_DISTANCE      = 2*GRID_LEN*MAX_DELAY;

    localparam DISTANCE_WIDTH  = $clog2(MAX_DISTANCE);
    localparam SYMBOL_WIDTH    = $clog2(NUM_SYMBOLS_MAX);
    localparam DELAY_WIDTH     = $clog2(MAX_DELAY);
    localparam GRID_WIDTH      = $clog2(GRID_LEN);
    localparam SEQ_WIDTH       = $clog2(SEQ_LEN);
    
    localparam SRAM_DATA_WIDTH = 6; 
    localparam SRAM_ADDR_WIDTH = $clog2(NUM_SCORES_MAX);

    typedef struct packed {
        logic   hor;    // Either left or right
        logic   diag;   // Top left or bottom right
        logic   ver;    // Top or bottom
    } edge_vec_t;

    // Path reconstruction traceback packet
    typedef struct packed {
        logic   left;
        logic   tl;
        logic   top;
        logic   disabled;
    } tbk_t;

    // Delay and flag options
    // NOTE: Indel is purposely left out as it'll be treated differently than signals below
    typedef struct packed {
        logic [DELAY_WIDTH-1:0] sub;
        logic                   postfix;
        logic                   disabled;
    } cell_cfg_t;

    // Traceback direction 
    typedef enum logic [1:0] { 
        TOP,
        TOP_LEFT,
        LEFT,
        NONE
    } tb_dir_t;

    // ==============================================================================
    //          Global definitions for I/O controller and control unit.
    //
    //  Upper bound support for BLOSUM62 matrices
    //  All I/O packets are fixed to the below (overriden) params from rl_types.
    // ==============================================================================

    localparam SEQ_LEN_IO      = 30;

    localparam GRID_LEN_IO     = SEQ_LEN_IO + 1;
    localparam MAX_DISTANCE_IO = 2*GRID_LEN_IO*MAX_DELAY;

    localparam DISTANCE_WIDTH_IO = $clog2(MAX_DISTANCE_IO);
    localparam GRID_WIDTH_IO     = $clog2(GRID_LEN_IO);
    
    // --- Control unit states ---
    typedef enum logic[3:0] { 
        IDLE,           //0
        LOAD_SRAM,      //1
        LOAD_INDEL,     //2
        LOAD_CONFIG,    //3
        LOAD_SEQ,       //4
        INIT_GRID,      //5
        RUNNING,        //6
        RESULT_READY,   //7
        OUTPUT_RESULT,  //8
        TRACE_BACK,     //9
        RESET_GRID,     //10
        ERROR,          //11
        DEBUG           //12
    } control_unit_state_e;

    localparam IN_IO_DEPTH  = 8;
    localparam OUT_IO_DEPTH = 8;

    localparam logic [SYMBOL_WIDTH-1:0] POSTFIX_CHAR = '1;
    localparam logic [SYMBOL_WIDTH-1:0] PREFIX_CHAR  = POSTFIX_CHAR-1;

    typedef logic [SYMBOL_WIDTH-1:0] char_t;   // Symbol encoding

    typedef enum logic {OP_I = 1'b0, DATA_I = 1'b1} in_pkt_e;
    typedef enum logic {SEQ_P = 1'b0, SEQ_Q = 1'b1} seq_e;
    typedef enum logic {STATUS = 1'b0, RESULT = 1'b1} out_pkt_e;
    typedef enum logic {DISTANCE_O = 1'b0, TB_O = 1'b1} result_pkt_e;

    // ---- Command opcodes ----
    typedef enum logic [3:0] {  
        INIT_SRAM_OP,
        STOP_SRAM_OP,
        LOAD_CONFIG_REG_OP,
        LOAD_INDEL_OP,
        LOAD_SEQ_OP,
        INIT_GRID_OP,
        RUN_OP,
        START_RACE_OP,
        STOP_COMP_OP,
        GET_RESULTS_OP,
        OUTPUT_TB_OP,
        RESET_GRID_OP
    } control_unit_opcode_e;

    typedef struct packed {
        // (control) fields, RW
        logic   tb_en;        
        logic   stream_mode;

        // (status) fields, R
        logic   indel_loaded;
        logic   sram_loaded;      
        logic   seq_p_loaded;     
        logic   seq_q_loaded;     
        logic   grid_initialized; 
        logic   result_ready;    
        logic   error; 
    } ctrl_status_reg_t;

    localparam OPCODE_WIDTH  = $bits(control_unit_opcode_e);
    localparam IN_PKT_WIDTH  = 14;  // chosen to fit minimum needs
    localparam OUT_PKT_WIDTH = 13;

    // ---- Input packets ----
    typedef struct packed {
        union packed {
            struct packed {
                logic [(IN_PKT_WIDTH-(1+1+2*DELAY_WIDTH))-1:0] pad;
                logic [DELAY_WIDTH-1:0] sub1;
                logic                   sub2_valid;
                logic [DELAY_WIDTH-1:0] sub2;
            } sram_data;

            struct packed {
                seq_e   id;
                logic   [(IN_PKT_WIDTH-(1+1+2*$bits(char_t)+1))-1:0] pad;
                char_t  char1;
                logic   char2_valid;
                char_t  char2;
            } seq_data;
        } payload;
    } in_data_pkt;

    typedef struct packed {
        control_unit_opcode_e cmd;
        
        union packed {
            struct packed {
                logic [(IN_PKT_WIDTH-(1+OPCODE_WIDTH+DELAY_WIDTH))-1:0] pad;
                char_t indel;
            } gap_pkt;

            struct packed {
                // logic [(IN_PKT_WIDTH-(1+OPCODE_WIDTH+$bits(ctrl_status_reg_t)))-1:0] pad;
                ctrl_status_reg_t reg_i;
            } reg_pkt;
        } payload;
    } in_op_pkt;

    typedef struct packed {
        in_pkt_e type_i;

        union packed {
            in_data_pkt data_i;
            in_op_pkt   op_i;
        } in_pkt_u;
    } io_in_t;

    // ---- Output packets ----
    typedef struct packed {
        result_pkt_e ret_t;

        union packed {
            logic [DISTANCE_WIDTH_IO-1:0] distance;

            struct packed {
                logic [(OUT_PKT_WIDTH-(1+1+$bits(tbk_t)))-1:0] pad;
                tbk_t dir;
            } tb;
        } payload;
    } out_result_pkt;

    typedef struct packed {
        out_pkt_e       type_o;
        out_result_pkt result;
    } io_out_t;

endpackage : rl_types

// For SIM use ONLY
package seq_pkg;
    localparam PREFIX_BASE = "-";
    localparam POSTFIX_BASE = "?";

    localparam byte DNA_BASES[4] = { "A", "T", "C", "G" };
    localparam byte BLOSUM62_BASES[20] = {
        "A","R","N","D","C","Q","E","G","H","I",
        "L","K","M","F","P","S","T","W","Y","V"
    };
endpackage : seq_pkg