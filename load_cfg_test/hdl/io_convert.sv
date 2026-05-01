//   io_convert.sv
//
// Contains helpful functions to generate and decode I/O packets
// See https://excalidraw.com/#json=5yaamnaTtA9HSw4If9jWU,zPSGLE3VWxDdw3VRdqMKvg

package io_convert;
    import rl_types::*;

    // ===================================================================================
    // ====================================== INPUT ======================================
    // ===================================================================================
    function automatic io_in_t mk_sram_pkt(logic [DELAY_WIDTH-1:0] s1, logic [DELAY_WIDTH-1:0] s2, logic s2_valid);
        io_in_t pkt;
        pkt = io_in_t'('0);

        pkt.type_i = DATA_I;
        pkt.in_pkt_u.data_i.payload.sram_data = '{
            sub1        : s1,
            sub2        : s2,
            sub2_valid  : s2_valid,
            pad         : '0
        };

        return pkt;
    endfunction

    function automatic io_in_t mk_seq_pkt(seq_e id, char_t c1, char_t c2, logic c2_valid);
        io_in_t pkt;
        pkt = io_in_t'('0);

        pkt.type_i = DATA_I;
        pkt.in_pkt_u.data_i.payload.seq_data = '{
            id          : id,
            pad         : '0,
            char1       : c1,
            char2_valid : c2_valid,
            char2       : c2
        };

        return pkt;
    endfunction

    function automatic io_in_t mk_indel_pkt(logic [DELAY_WIDTH-1:0] gap);
        io_in_t pkt;
        pkt = io_in_t'('0);

        pkt.type_i = OP_I;
        pkt.in_pkt_u.op_i.cmd = LOAD_INDEL_OP;
        pkt.in_pkt_u.op_i.payload.gap_pkt = '{
            pad   : '0,
            indel : gap
        };

        return pkt;
    endfunction

    function automatic io_in_t mk_reg_pkt(ctrl_status_reg_t reg_new);
        io_in_t pkt;
        pkt = io_in_t'('0);

        pkt.type_i = OP_I;
        pkt.in_pkt_u.op_i.cmd = LOAD_CONFIG_REG_OP;
        pkt.in_pkt_u.op_i.payload.reg_pkt = '{
            reg_i : reg_new
        };

        return pkt;
    endfunction

    function automatic io_in_t mk_cmd_pkt(control_unit_opcode_e op);
        io_in_t pkt;
        pkt = io_in_t'('0);

        pkt.type_i = OP_I;
        pkt.in_pkt_u.op_i.cmd = op;

        return pkt;
    endfunction

    // ====================================================================================
    // ====================================== OUTPUT ======================================
    // ====================================================================================
    function automatic io_out_t mk_dist_pkt(logic [DISTANCE_WIDTH-1:0] distance);
        io_out_t pkt;
        pkt = io_out_t'('0);

        pkt.type_o = RESULT;
        pkt.result.ret_t = DISTANCE_O;
        pkt.result.payload.distance = distance;

        return pkt;
    endfunction

    function automatic io_out_t mk_tb_pkt(tbk_t tb);
        io_out_t pkt;
        pkt = io_out_t'('0);

        pkt.type_o = RESULT;
        pkt.result.ret_t = TB_O;
        pkt.result.payload.tb = '{
            pad : '0,
            dir : tb
        };

        return pkt;
    endfunction

endpackage : io_convert
