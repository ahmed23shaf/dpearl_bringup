//      Creates a pulse that is exactly one clock cycle wide, regardless of how long a button ("d") is held.
//

module posedge_detector (
    input logic clk,

    input logic d,
    output logic q
);
    logic d_reg;

    always_ff @(posedge clk) begin
        d_reg <= d;
    end

    assign q = ~d_reg & d;
    
endmodule