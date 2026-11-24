`timescale 1ns/1ps

module modular_multiplier_barrett_opt #(
    parameter Q = 3329
) (
    input  wire [11:0] a,
    input  wire [11:0] b,
    output wire [11:0] result
);

    wire [23:0] product;
    wire [36:0] scaled_product;
    wire [12:0] q_hat;
    wire [24:0] q_product;
    wire [24:0] remainder;

    assign product = a * b;

    // 5039 = 4096 + 512 + 256 + 128 + 32 + 8 + 4 + 2 + 1
    assign scaled_product =
          ({13'd0, product} << 12)
        + ({13'd0, product} << 9)
        + ({13'd0, product} << 8)
        + ({13'd0, product} << 7)
        + ({13'd0, product} << 5)
        + ({13'd0, product} << 3)
        + ({13'd0, product} << 2)
        + ({13'd0, product} << 1)
        + product;

    assign q_hat = scaled_product >> 24;

    // 3329 = 4096 - 512 - 256 + 1
    assign q_product =
          ({12'd0, q_hat} << 12)
        - ({12'd0, q_hat} << 9)
        - ({12'd0, q_hat} << 8)
        + q_hat;

    assign remainder = {1'b0, product} - q_product;

    assign result = (remainder >= Q)
                  ? remainder - Q
                  : remainder;

endmodule
