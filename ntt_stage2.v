
`timescale 1ns/1ps

module ntt_stage2 (
    input  wire [3071:0] coeff_in,
    output wire [3071:0] coeff_out
);

    wire [11:0] zeta0;
    wire [11:0] zeta1;

    // The two twiddle factors required by Stage 2.
    ntt_twiddle_rom rom0 (
        .addr(7'd2),
        .zeta(zeta0)
    );

    ntt_twiddle_rom rom1 (
        .addr(7'd3),
        .zeta(zeta1)
    );

    genvar i;
    generate
        for (i = 0; i < 64; i = i + 1) begin : GEN_GROUP0
            ntt_butterfly #(.Q(3329)) butterfly (
                .a(coeff_in[(i * 12) +: 12]),
                .b(coeff_in[((i + 64) * 12) +: 12]),
                .zeta(zeta0),
                .u(coeff_out[(i * 12) +: 12]),
                .v(coeff_out[((i + 64) * 12) +: 12])
            );
        end

        for (i = 0; i < 64; i = i + 1) begin : GEN_GROUP1
            ntt_butterfly #(.Q(3329)) butterfly (
                .a(coeff_in[((i + 128) * 12) +: 12]),
                .b(coeff_in[((i + 192) * 12) +: 12]),
                .zeta(zeta1),
                .u(coeff_out[((i + 128) * 12) +: 12]),
                .v(coeff_out[((i + 192) * 12) +: 12])
            );
        end
    endgenerate

endmodule
