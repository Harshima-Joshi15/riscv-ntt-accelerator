
module modular_subtractor (
    input  wire [11:0] a,
    input  wire [11:0] b,
    output wire [11:0] result
);

    parameter Q = 3329;

    assign result = (a >= b) ? (a - b) : (a + Q - b);

endmodule
