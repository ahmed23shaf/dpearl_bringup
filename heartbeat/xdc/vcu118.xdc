############################################################################
# Clocking
############################################################################
set_property PACKAGE_PIN AY24 [get_ports clk125_p]
set_property IOSTANDARD LVDS [get_ports clk125_p]
set_property PACKAGE_PIN AY23 [get_ports clk125_n]
set_property IOSTANDARD LVDS [get_ports clk125_n]
create_clock -period 8.000 -name clk125_virt -waveform {0.000 4.000} [get_ports clk125_p]

############################################################################
# User I/O
############################################################################
set_property PACKAGE_PIN AT32 [get_ports {gpio_led[0]}]
set_property PACKAGE_PIN AV34 [get_ports {gpio_led[1]}]
set_property PACKAGE_PIN AY30 [get_ports {gpio_led[2]}]
set_property PACKAGE_PIN BB32 [get_ports {gpio_led[3]}]
set_property PACKAGE_PIN BF32 [get_ports {gpio_led[4]}]
set_property PACKAGE_PIN AU37 [get_ports {gpio_led[5]}]
set_property PACKAGE_PIN AV36 [get_ports {gpio_led[6]}]
set_property PACKAGE_PIN BA37 [get_ports {gpio_led[7]}]
set_property IOSTANDARD LVCMOS12 [get_ports gpio_led[*]]

set_property PACKAGE_PIN BB24 [get_ports gpio_sw_n]
set_property PACKAGE_PIN BE23 [get_ports gpio_sw_e]
set_property PACKAGE_PIN BE22 [get_ports gpio_sw_s]
set_property PACKAGE_PIN BF22 [get_ports gpio_sw_w]
set_property PACKAGE_PIN BD23 [get_ports gpio_sw_c]
set_property IOSTANDARD LVCMOS18 [get_ports gpio_sw_*]

set_property PACKAGE_PIN L19 [get_ports cpu_reset]
set_property IOSTANDARD LVCMOS12 [get_ports cpu_reset]

############################################################################
# Chip Interface
############################################################################
# Clock/Reset
set_property PACKAGE_PIN AY9 [get_ports chip_clk]
set_property PACKAGE_PIN BA9 [get_ports chip_rst_n]

# FIFO Status
set_property PACKAGE_PIN AU11 [get_ports chip_fifo_rx_full]
set_property PACKAGE_PIN AV11 [get_ports chip_fifo_tx_empty]

# Data In/Out/Valid
set_property PACKAGE_PIN BB13 [get_ports {chip_pkt_o[0]}]
set_property PACKAGE_PIN BB12 [get_ports {chip_pkt_o[1]}]
set_property PACKAGE_PIN BA16 [get_ports {chip_pkt_o[2]}]
set_property PACKAGE_PIN BA15 [get_ports {chip_pkt_o[3]}]
set_property PACKAGE_PIN BC14 [get_ports {chip_pkt_o[4]}]
set_property PACKAGE_PIN BC13 [get_ports {chip_pkt_o[5]}]
set_property PACKAGE_PIN AY8  [get_ports {chip_pkt_o[6]}]
set_property PACKAGE_PIN AY7  [get_ports {chip_pkt_o[7]}]
set_property PACKAGE_PIN AW8  [get_ports {chip_pkt_o[8]}]
set_property PACKAGE_PIN AW7  [get_ports {chip_pkt_o[9]}]
set_property PACKAGE_PIN BB16 [get_ports {chip_pkt_o[10]}]
set_property PACKAGE_PIN BC16 [get_ports {chip_pkt_o[11]}]
set_property PACKAGE_PIN AV9  [get_ports {chip_pkt_o[12]}]
set_property PACKAGE_PIN AW13 [get_ports chip_pkt_o_valid]

set_property PACKAGE_PIN BE13 [get_ports {chip_pkt_i[0]}]
set_property PACKAGE_PIN BC15 [get_ports {chip_pkt_i[1]}]
set_property PACKAGE_PIN BD15 [get_ports {chip_pkt_i[2]}]
set_property PACKAGE_PIN BE15 [get_ports {chip_pkt_i[3]}]
set_property PACKAGE_PIN BF15 [get_ports {chip_pkt_i[4]}]
set_property PACKAGE_PIN BA14 [get_ports {chip_pkt_i[5]}]
set_property PACKAGE_PIN BB14 [get_ports {chip_pkt_i[6]}]
set_property PACKAGE_PIN AV8  [get_ports {chip_pkt_i[7]}]
set_property PACKAGE_PIN AR14 [get_ports {chip_pkt_i[8]}]
set_property PACKAGE_PIN AT14 [get_ports {chip_pkt_i[9]}]
set_property PACKAGE_PIN AP12 [get_ports {chip_pkt_i[10]}]
set_property PACKAGE_PIN AR12 [get_ports {chip_pkt_i[11]}]
set_property PACKAGE_PIN AW12 [get_ports {chip_pkt_i[12]}]
set_property PACKAGE_PIN AY12 [get_ports {chip_pkt_i[13]}]

# Register/Control/Power
set_property PACKAGE_PIN BF10 [get_ports {chip_reg_o[0]}]
set_property PACKAGE_PIN BF9  [get_ports {chip_reg_o[1]}]
set_property PACKAGE_PIN BC11 [get_ports {chip_reg_o[2]}]
set_property PACKAGE_PIN BD11 [get_ports {chip_reg_o[3]}]
set_property PACKAGE_PIN BD12 [get_ports {chip_reg_o[4]}]
set_property PACKAGE_PIN BE12 [get_ports {chip_reg_o[5]}]
set_property PACKAGE_PIN BF12 [get_ports {chip_reg_o[6]}]
set_property PACKAGE_PIN BF11 [get_ports {chip_reg_o[7]}]
set_property PACKAGE_PIN BE14 [get_ports {chip_reg_o[8]}]
set_property PACKAGE_PIN AY13 [get_ports chip_power_test_o]

set_property PACKAGE_PIN AW11 [get_ports chip_rx_enqueue]
set_property PACKAGE_PIN AY10 [get_ports chip_tx_dequeue]

# Set all Chip-related IO to 1.8V
set_property IOSTANDARD LVCMOS18 [get_ports chip_*]