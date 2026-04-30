//Debouncer circuit inspired by https://forum.digikey.com/t/debounce-logic-circuit-vhdl/12573
//Also serves as a synchronizer for pushbutton and switch (asynchronous) inputs
//Notice that this circuit behaves differently under simulation as it does when synthesized
//so that simulation times are not unnecessarily long waiting for the debouncer circuits

`ifdef SYNTHESIS // Use big counter for synthesis
localparam COUNTER_WIDTH = 15; 
`else
localparam COUNTER_WIDTH = 1;
`endif

//synchronizer w/ debouncer (use for fpga button/switch)
module sync_debounce (
	input  logic clk, 
	input  logic mode_sel, // 0 for switch, 1 for button 
	input  logic d, 

	output logic q
);

	logic ff1, ff2;
	logic [COUNTER_WIDTH : 0] counter;
	logic debounce_out;
	logic pulse_out;

	always_ff @(posedge clk) begin
		ff1 <= d; // flop input once
		ff2 <= ff1; // flop input twice

		// Change button only when 2^(COUNTER_WIDTH) stable input cycles are recorded 
		if (~(ff1 ^ ff2)) begin // detect an input difference per clock cycle
		  if (~counter[COUNTER_WIDTH]) begin
		      counter <= counter + 1'b1; // waiting for input to become stable
		  end else begin
		      debounce_out <= ff2; // input is idle
		  end
	    end else begin
	       counter <= '0; // reset counter when bounce detected
	    end
	end

	button_pulse u_button_pulse (
		.clk(clk),
		.level_in(debounce_out),
		.pulse_out(pulse_out)
	);

	// mode_sel = 0 => switch mode, return debounced level
	// mode_sel = 1 => button mode, return 1-cycle pulse on debounced rising edge
	assign q = mode_sel ? pulse_out : debounce_out;

endmodule

module button_pulse (
    input  logic clk,
    input  logic level_in,   // from debouncer (q)
    output logic pulse_out
);

    logic level_d;

    always_ff @(posedge clk) begin
        level_d  <= level_in;
        pulse_out <= level_in & ~level_d; // rising edge detect
    end

endmodule
