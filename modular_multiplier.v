
module modular_multiplier (
    input  wire [11:0] a,
    input  wire [11:0] b,
    output wire [11:0] result
);

    parameter Q = 3329;

    wire [23:0] product;

    assign product = a * b;
    assign result = product % Q;

endmodule
