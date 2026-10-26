
`timescale 1ns/1ps

module modular_multiplier #(parameter Q = 3329) (
    input  wire [11:0] a,
    input  wire [11:0] b,
    output wire [11:0] result
);
    wire [23:0] product;

    assign product = a * b;
    assign result = product % Q;
endmodule


module ntt_butterfly #(parameter Q = 3329) (
    input  wire [11:0] a,
    input  wire [11:0] b,
    input  wire [11:0] zeta,
    output wire [11:0] u,
    output wire [11:0] v
);
    wire [11:0] t;
    wire [12:0] sum;
    wire [12:0] a_ext;

    modular_multiplier #(.Q(Q)) mult (
        .a(b),
        .b(zeta),
        .result(t)
    );

    assign a_ext = {1'b0, a};
    assign sum = a_ext + {1'b0, t};

    assign u = (sum >= Q) ? sum - Q : sum;
    assign v = (a >= t) ? (a - t) : (a + Q - t);
endmodule


module ntt_stage #(
    parameter Q = 3329,
    parameter N = 256,
    parameter GROUP_LEN = 128
) (
    input  wire [N*12-1:0] coeff_in,
    input  wire [11:0] zeta,
    output wire [N*12-1:0] coeff_out
);
    genvar i;

    generate
        for (i = 0; i < N/2; i = i + 1) begin : GEN_BUTTERFLY
            localparam integer GROUP = i / GROUP_LEN;
            localparam integer OFFSET = i % GROUP_LEN;
            localparam integer A_INDEX = GROUP * (2*GROUP_LEN) + OFFSET;
            localparam integer B_INDEX = A_INDEX + GROUP_LEN;

            ntt_butterfly #(.Q(Q)) butterfly (
                .a(coeff_in[A_INDEX*12 +: 12]),
                .b(coeff_in[B_INDEX*12 +: 12]),
                .zeta(zeta),
                .u(coeff_out[A_INDEX*12 +: 12]),
                .v(coeff_out[B_INDEX*12 +: 12])
            );
        end
    endgenerate
endmodule
