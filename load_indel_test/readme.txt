Unit test for validating loading of the indel register on chip.
Traverses the IDLE --> LOAD_INDEL --> IDLE states (within D-PEARL).

*Does NOT validate if the indel data is correct, only if loaded.*

List of steps to follow on FPGA:
    1. Set desired indel value on dip switches (4-bit value)
    1. Press reset (cpu_reset)
    2. Press the north push button.

Expected Behavior:
Note: gpio_led[0] is driven by the "indel_loaded" field in the ctrl status register.
      gpio_led[1] = north push button.
      gpio_led[2] = power_test_o
      gpio_led[7:4] are the value of the dip switches

    After reset, gpio_led='0.
    After pressing the north push button, gpio_led[0]=1.
    (Indicating the indel value has been successfully loaded.)
