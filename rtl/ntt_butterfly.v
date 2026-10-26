`timescale 1ns/1ps

module ntt_butterfly #(
    parameter Q = 3329
) (
    input  wire [11:0] a,
    input  wire [11:0] b,
    input  wire [11:0] zeta,
    output wire [11:0] u,
    output wire [11:0] v
);

    wire [11:0] t;
    wire [12:0] sum;

    modular_multiplier #(.Q(Q)) mult (
        .a(b),
        .b(zeta),
        .result(t)
    );

    assign sum = a + t;
    assign u = (sum >= Q) ? sum - Q : sum;
    assign v = (a >= t) ? (a - t) : (a + Q - t);

endmodule
