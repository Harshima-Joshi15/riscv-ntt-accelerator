`timescale 1ns/1ps

module modular_multiplier #(
    parameter Q = 3329
) (
    input  wire [11:0] a,
    input  wire [11:0] b,
    output wire [11:0] result
);

    wire [23:0] product;

    assign product = a * b;
    assign result = product % Q;

endmodule
