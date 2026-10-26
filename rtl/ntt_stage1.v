
`timescale 1ns/1ps

module ntt_stage1 (
    input  wire [3071:0] coeff_in,
    output wire [3071:0] coeff_out
);

    wire [11:0] zeta;

    // Address 1 contains the first ML-KEM NTT twiddle factor: 1729.
    ntt_twiddle_rom rom (
        .addr(7'd1),
        .zeta(zeta)
    );

    genvar i;
    generate
        for (i = 0; i < 128; i = i + 1) begin : GEN_BUTTERFLY
            ntt_butterfly #(.Q(3329)) butterfly (
                .a(coeff_in[(i * 12) +: 12]),
                .b(coeff_in[((i + 128) * 12) +: 12]),
                .zeta(zeta),
                .u(coeff_out[(i * 12) +: 12]),
                .v(coeff_out[((i + 128) * 12) +: 12])
            );
        end
    endgenerate

endmodule
