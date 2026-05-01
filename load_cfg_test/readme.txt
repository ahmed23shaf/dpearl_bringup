Unit test for validating loading of the control status (config) register on chip.
Traverses the IDLE --> LOAD_CONFIG --> IDLE states.

*Does NOT validate if the config data is correct, only if loaded.*

List of steps to follow on FPGA:
    0. Set desired 'tb_en' and 'stream_mode' bitfields within the "fpga_top.sv" module BEFORE generating bitstream
       Currently set to tb_en = 1'b1 and stream_mode = 1'b0
    1. Press reset (cpu_reset)
    2. Press the north push button.

Expected Behavior:
Note: gpio_led[0] = tb_en
      gpio_led[1] = stream_mode
      gpio_led[2] = power_test_o
      gpio_led[3] = northward facing push button

    After reset, gpio_led='0.
    After pressing the north push button, gpio_led[2:1]={stream_mode, tb_en}.
    (Indicating the cfg values has been successfully loaded.)
