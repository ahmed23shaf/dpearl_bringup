############################################################################
# VCU118 System Clock Constraints
############################################################################
set_property PACKAGE_PIN AY24 [get_ports clk125_p]
set_property IOSTANDARD LVDS [get_ports clk125_p]

set_property PACKAGE_PIN AY23 [get_ports clk125_n]
set_property IOSTANDARD LVDS [get_ports clk125_n]

# Create clock object for 125MHz
create_clock -period 8.000 -name clk125_virt -waveform {0.000 4.000} [get_ports clk125_p]

############################################################################
# FPGA User I/O Annotations
############################################################################

# --- User LEDs ---
set_property PACKAGE_PIN AT32 [get_ports {gpio_led[0]}]
set_property PACKAGE_PIN AV34 [get_ports {gpio_led[1]}]
set_property PACKAGE_PIN AY30 [get_ports {gpio_led[2]}]
set_property PACKAGE_PIN BB32 [get_ports {gpio_led[3]}]
set_property PACKAGE_PIN BF32 [get_ports {gpio_led[4]}]
set_property PACKAGE_PIN AU37 [get_ports {gpio_led[5]}]
set_property PACKAGE_PIN AV36 [get_ports {gpio_led[6]}]
set_property PACKAGE_PIN BA37 [get_ports {gpio_led[7]}]
set_property IOSTANDARD LVCMOS12 [get_ports {gpio_led[*]}]

# --- User Pushbuttons ---
set_property PACKAGE_PIN BB24 [get_ports gpio_sw_n]
set_property PACKAGE_PIN BE23 [get_ports gpio_sw_e]
set_property PACKAGE_PIN BE22 [get_ports gpio_sw_s]
set_property PACKAGE_PIN BF22 [get_ports gpio_sw_w]
set_property PACKAGE_PIN BD23 [get_ports gpio_sw_c]
set_property IOSTANDARD LVCMOS18 [get_ports gpio_sw_*]

# --- CPU Reset ---
set_property PACKAGE_PIN L19 [get_ports cpu_reset]
set_property IOSTANDARD LVCMOS12 [get_ports cpu_reset]

# --- DIP Switches ---
set_property PACKAGE_PIN B17 [get_ports {gpio_dip_sw[0]}]
set_property PACKAGE_PIN G16 [get_ports {gpio_dip_sw[1]}]
set_property PACKAGE_PIN J16 [get_ports {gpio_dip_sw[2]}]
set_property PACKAGE_PIN D21 [get_ports {gpio_dip_sw[3]}]
set_property IOSTANDARD LVCMOS12 [get_ports {gpio_dip_sw[*]}]

############################################################################
# Chip-to-FPGA Interface (Assign to your specific FMC connector pins)
############################################################################
# NOTE: Replace 'PLACEHOLDER_PIN' with the actual FMC bank pins from your board design.
# set_property PACKAGE_PIN PLACEHOLDER_PIN [get_ports chip_fifo_rx_full]
# set_property PACKAGE_PIN PLACEHOLDER_PIN [get_ports chip_fifo_tx_empty]
# set_property IOSTANDARD LVCMOS18 [get_ports chip_fifo_*]

# For buses (like chip_pkt_o), map each bit to a physical pin:
# set_property PACKAGE_PIN PLACEHOLDER_PIN [get_ports {chip_pkt_o[0]}]
# ...