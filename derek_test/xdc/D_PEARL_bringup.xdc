#    // CLOCK signal
#    input  logic        clk125_p,          // AY24
#    input  logic        clk125_n,          // AY23
    
#    // Board signal
#    input  logic        BOARD_reset,             // L19 -- ACTIVE HIGH
#    input  logic        BOARD_LED_button,
#    output logic [7:0]  BOARD_LED,
    
#    // TX RX UART signal
#    input  logic        UART_TX,
#    output logic        UART_RX,
    
#    // FPGA --> Chip
#    output logic        chip_clk,
#    output logic        chip_rst_n,

#    output io_in_t      chip_pkt_i,
#    output logic        chip_fifo_rx_enqueue,
#    output logic        chip_fifo_tx_dequeue,

#    // Chip --> FPGA
#    input  logic                chip_fifo_rx_full,
#    input  logic                chip_fifo_tx_empty,

#    input  io_out_t             chip_pkt_o,        // From chip pkt_o
#    input  logic                chip_pkt_o_valid,  // From chip pkt_o_valid
    
#    input  ctrl_status_reg_t    chip_reg_o,
#    input  logic                chip_power_test_o


# Clock
set_property PACKAGE_PIN AY24 [get_ports clk125_p]
set_property PACKAGE_PIN AY23 [get_ports clk125_n]
set_property IOSTANDARD LVDS [get_ports {clk125p clk125_n}]

# Board reset
set_property PACKAGE_PIN BD23 [get_ports BOARD_reset] # user button center
set_property IOSTANDARD LVCMOS18 [get_ports BOARD_reset]

# Board LED
set_property PACKAGE_PIN AT32 [get_ports {BOARD_LED[0]}]
set_property PACKAGE_PIN AV34 [get_ports {BOARD_LED[1]}]
set_property PACKAGE_PIN AY30 [get_ports {BOARD_LED[2]}]
set_property PACKAGE_PIN BB32 [get_ports {BOARD_LED[3]}]
set_property PACKAGE_PIN BF32 [get_ports {BOARD_LED[4]}]
set_property PACKAGE_PIN AU37 [get_ports {BOARD_LED[5]}]
set_property PACKAGE_PIN AV36 [get_ports {BOARD_LED[6]}]
set_property PACKAGE_PIN BA37 [get_ports {BOARD_LED[7]}]

set_property IOSTANDARD LVCMOS12 [get_ports BOARD_LED[*]]

# LED page switch button
set_property PACKAGE_PIN BF32 [get_ports BOARD_LED_button] # user button west 
set_property IOSTANDARD LVCMOS18 [get_ports BOARD_LED_button]

# FPGA <--> CHIP
set_property PACKAGE_PIN AY9 [get_ports chip_clk] # FPGA: FMC_HPC1_LA00_CC_P, FMC: J1_1
set_property PACKAGE_PIN BA9 [get_ports chip_rst_n] # FPGA: FMC_HPC1_LA00_CC_N, FMC: J1_3

set_property PACKAGE_PIN BF10 [get_ports {chip_reg_o[0]}] # FPGA: FMC_HPC_LA01_CC_P, FMC: J1_5
set_property PACKAGE_PIN BF9  [get_ports {chip_reg_o[1]}] # FPGA: FMC_HPC_LA01_CC_N, FMC: J1_7
set_property PACKAGE_PIN BC11 [get_ports {chip_reg_o[2]}] # FPGA: FMC_HPC_LA02_P,    FMC: J1_9
set_property PACKAGE_PIN BD11 [get_ports {chip_reg_o[3]}] # FPGA: FMC_HPC_LA02_N,    FMC: J1_11
set_property PACKAGE_PIN BD12 [get_ports {chip_reg_o[4]}] # FPGA: FMC_HPC_LA03_P,    FMC: J1_13
set_property PACKAGE_PIN BE12 [get_ports {chip_reg_o[5]}] # FPGA: FMC_HPC_LA03_N,    FMC: J1_15
set_property PACKAGE_PIN BF12 [get_ports {chip_reg_o[6]}] # FPGA: FMC_HPC_LA04_P,    FMC: J1_17
set_property PACKAGE_PIN BF11 [get_ports {chip_reg_o[7]}] # FPGA: FMC_HPC_LA04_N,    FMC: J1_19
set_property PACKAGE_PIN BE14 [get_ports {chip_reg_o[8]}] # FPGA: FMC_HPC_LA05_P,    FMC: J1_21

set_property PACKAGE_PIN BB13 [get_ports {chip_pkt_o[0]}]  # FPGA: FMC_HPC_LA10_P, FMC: J1_2
set_property PACKAGE_PIN BB12 [get_ports {chip_pkt_o[1]}]  # FPGA: FMC_HPC_LA10_N, FMC: J1_4
set_property PACKAGE_PIN BA16 [get_ports {chip_pkt_o[2]}]  # FPGA: FMC_HPC_LA11_P, FMC: J1_6
set_property PACKAGE_PIN BA15 [get_ports {chip_pkt_o[3]}]  # FPGA: FMC_HPC_LA11_N, FMC: J1_8
set_property PACKAGE_PIN BC14 [get_ports {chip_pkt_o[4]}]  # FPGA: FMC_HPC_LA12_P, FMC: J1_10
set_property PACKAGE_PIN BC13 [get_ports {chip_pkt_o[5]}]  # FPGA: FMC_HPC_LA12_N, FMC: J1_12
set_property PACKAGE_PIN AY8  [get_ports {chip_pkt_o[6]}]  # FPGA: FMC_HPC_LA13_P, FMC: J1_14
set_property PACKAGE_PIN AY7  [get_ports {chip_pkt_o[7]}]  # FPGA: FMC_HPC_LA13_N, FMC: J1_16
set_property PACKAGE_PIN AW8  [get_ports {chip_pkt_o[8]}]  # FPGA: FMC_HPC_LA14_P, FMC: J1_18
set_property PACKAGE_PIN AW7  [get_ports {chip_pkt_o[9]}]  # FPGA: FMC_HPC_LA14_N, FMC: J1_20
set_property PACKAGE_PIN BB16 [get_ports {chip_pkt_o[10]}] # FPGA: FMC_HPC_LA15_P, FMC: J1_22
set_property PACKAGE_PIN BC16 [get_ports {chip_pkt_o[11]}] # FPGA: FMC_HPC_LA15_N, FMC: J1_24
set_property PACKAGE_PIN AV9  [get_ports {chip_pkt_o[12]}] # FPGA: FMC_HPC_LA16_P, FMC: J1_26

set_property PACKAGE_PIN BE13 [get_ports {chip_pkt_i[0]}]  # FPGA: FMC_HPC_LA06_N,    FMC: J1_27
set_property PACKAGE_PIN BC15 [get_ports {chip_pkt_i[1]}]  # FPGA: FMC_HPC_LA07_P,    FMC: J1_29
set_property PACKAGE_PIN BD15 [get_ports {chip_pkt_i[2]}]  # FPGA: FMC_HPC_LA07_N,    FMC: J1_31
set_property PACKAGE_PIN BE15 [get_ports {chip_pkt_i[3]}]  # FPGA: FMC_HPC_LA08_P,    FMC: J1_33
set_property PACKAGE_PIN BF15 [get_ports {chip_pkt_i[4]}]  # FPGA: FMC_HPC_LA08_N,    FMC: J1_35
set_property PACKAGE_PIN BA14 [get_ports {chip_pkt_i[5]}]  # FPGA: FMC_HPC_LA09_P,    FMC: J1_37
set_property PACKAGE_PIN BB14 [get_ports {chip_pkt_i[6]}]  # FPGA: FMC_HPC_LA09_N,    FMC: J1_39
set_property PACKAGE_PIN AV8  [get_ports {chip_pkt_i[7]}]  # FPGA: FMC_HPC_LA16_N,    FMC: J1_28
set_property PACKAGE_PIN AR14 [get_ports {chip_pkt_i[8]}]  # FPGA: FMC_HPC_LA17_CC_P, FMC: J1_30
set_property PACKAGE_PIN AT14 [get_ports {chip_pkt_i[9]}]  # FPGA: FMC_HPC_LA17_CC_N, FMC: J1_32
set_property PACKAGE_PIN AP12 [get_ports {chip_pkt_i[10]}] # FPGA: FMC_HPC_LA18_CC_P, FMC: J1_34
set_property PACKAGE_PIN AR12 [get_ports {chip_pkt_i[11]}] # FPGA: FMC_HPC_LA18_CC_N, FMC: J1_36
set_property PACKAGE_PIN AW12 [get_ports {chip_pkt_i[12]}] # FPGA: FMC_HPC_LA19_P,    FMC: J1_38
set_property PACKAGE_PIN AY12 [get_ports {chip_pkt_i[13]}] # FPGA: FMC_HPC_LA19_N,    FMC: J1_40

set_property PACKAGE_PIN AW11 [get_ports {chip_fifo_rx_enqueue}] # FPGA: FMC_HPC_LA20_P FMC: J20_1
set_property PACKAGE_PIN AY10 [get_ports {chip_fifo_tx_dequeue}] # FPGA: FMC_HPC_LA20_N FMC: J20_3
set_property PACKAGE_PIN AU11 [get_ports {chip_fifo_rx_full}]    # FPGA: FMC_HPC_LA21_P FMC: J20_5
set_property PACKAGE_PIN AV11 [get_ports {chip_fifo_tx_empty}]   # FPGA: FMC_HPC_LA21_N FMC: J20_7
set_property PACKAGE_PIN AW13 [get_ports {chip_pkt_o_valid}]     # FPGA: FMC_HPC_LA22_P FMC: J20_9
set_property PACKAGE_PIN AY13 [get_ports {chip_power_test_o}]    # FPGA: FMC_HPC_LA22_N FMC: J20_11


# FPGA <--> CHIP (1.8V output)
set_property IOSTANDARD LVCMOS18 [get_ports chip_clk] 
set_property IOSTANDARD LVCMOS18 [get_ports chip_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports {chip_reg_o[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports {chip_pkt_o[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports {chip_pkt_i[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports {chip_fifo_rx_enqueue}]
set_property IOSTANDARD LVCMOS18 [get_ports {chip_fifo_tx_dequeue}]
set_property IOSTANDARD LVCMOS18 [get_ports {chip_fifo_rx_full}]
set_property IOSTANDARD LVCMOS18 [get_ports {chip_fifo_tx_empty}]
set_property IOSTANDARD LVCMOS18 [get_ports {chip_pkt_o_valid}]
set_property IOSTANDARD LVCMOS18 [get_ports {chip_power_test_o}]
# FPGA <--> CHIP (1.2V output)
#set_property IOSTANDARD LVCMOS12 [get_ports chip_clk] 
#set_property IOSTANDARD LVCMOS12 [get_ports chip_rst_n]
#set_property IOSTANDARD LVCMOS12 [get_ports {chip_reg_o[*]}]
#set_property IOSTANDARD LVCMOS12 [get_ports {chip_pkt_o[*]}]
#set_property IOSTANDARD LVCMOS12 [get_ports {chip_pkt_i[*]}]
#set_property IOSTANDARD LVCMOS12 [get_ports {chip_fifo_rx_enqueue}]
#set_property IOSTANDARD LVCMOS12 [get_ports {chip_fifo_tx_dequeue}]
#set_property IOSTANDARD LVCMOS12 [get_ports {chip_fifo_rx_full}]
#set_property IOSTANDARD LVCMOS12 [get_ports {chip_fifo_tx_empty}]
#set_property IOSTANDARD LVCMOS12 [get_ports {chip_pkt_o_valid}]
#set_property IOSTANDARD LVCMOS12 [get_ports {chip_power_test_o}]