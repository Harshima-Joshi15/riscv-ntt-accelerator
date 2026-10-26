`timescale 1ns/1ps

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


// Wrapper for Stage 128 (GROUP_LEN = 128), directly exercised by testbench/ntt_stage_tb.v
module ntt_stage128 (
    input  wire [3071:0] coeff_in,
    input  wire [11:0]   zeta,
    output wire [3071:0] coeff_out
);
    ntt_stage #(
        .Q(3329),
        .N(256),
        .GROUP_LEN(128)
    ) stage_inst (
        .coeff_in(coeff_in),
        .zeta(zeta),
        .coeff_out(coeff_out)
    );
endmodule
