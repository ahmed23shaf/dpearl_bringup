Unit test for validating loading of the SRAM on chip
Traverses the IDLE --> LOAD_SRAM --> IDLE states.

*Does NOT validate if the SRAM data is correct, only if loaded.*

List of steps to follow on FPGA:
    0. Set desired scoring matrix in the top of fpga_top.sv module.
    1. Press reset (cpu_reset)
    2. Press the EAST push button.

Expected Behavior:
Note: gpio_led[0] = sram_loaded
      gpio_led[1] = eastwards facing push button
      gpio_led[2] = power_test_o

    On reset, gpio_led='0.
    After pressing the north east button, gpio_led[0] should light up.
    (Indicating the sram has been successfully loaded.)
