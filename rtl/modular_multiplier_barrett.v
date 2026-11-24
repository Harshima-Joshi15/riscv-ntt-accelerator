`timescale 1ns/1ps

module modular_multiplier_barrett #(
    parameter Q = 3329
) (
    input  wire [11:0] a,
    input  wire [11:0] b,
    output wire [11:0] result
);

    localparam [11:0] MODULUS = Q;
    localparam [12:0] MU = (1 << 24) / Q;

    wire [23:0] product;
    wire [36:0] scaled_product;
    wire [12:0] q_hat;
    wire [24:0] q_product;
    wire [24:0] remainder;

    assign product        = a * b;
    assign scaled_product = product * MU;
    assign q_hat          = scaled_product >> 24;
    assign q_product      = q_hat * MODULUS;
    assign remainder      = {1'b0, product} - q_product;

    assign result = (remainder >= MODULUS)
                  ? remainder - MODULUS
                  : remainder;

endmodule
