
`timescale 1ns/1ps

module ntt_stage3 (
    input  wire [3071:0] coeff_in,
    output wire [3071:0] coeff_out
);

    wire [11:0] zeta0, zeta1, zeta2, zeta3;

    ntt_twiddle_rom rom0 (.addr(7'd4), .zeta(zeta0));
    ntt_twiddle_rom rom1 (.addr(7'd5), .zeta(zeta1));
    ntt_twiddle_rom rom2 (.addr(7'd6), .zeta(zeta2));
    ntt_twiddle_rom rom3 (.addr(7'd7), .zeta(zeta3));

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : GEN_GROUP0
            ntt_butterfly #(.Q(3329)) butterfly (
                .a(coeff_in[(i * 12) +: 12]),
                .b(coeff_in[((i + 32) * 12) +: 12]),
                .zeta(zeta0),
                .u(coeff_out[(i * 12) +: 12]),
                .v(coeff_out[((i + 32) * 12) +: 12])
            );
        end

        for (i = 0; i < 32; i = i + 1) begin : GEN_GROUP1
            ntt_butterfly #(.Q(3329)) butterfly (
                .a(coeff_in[((i + 64) * 12) +: 12]),
                .b(coeff_in[((i + 96) * 12) +: 12]),
                .zeta(zeta1),
                .u(coeff_out[((i + 64) * 12) +: 12]),
                .v(coeff_out[((i + 96) * 12) +: 12])
            );
        end

        for (i = 0; i < 32; i = i + 1) begin : GEN_GROUP2
            ntt_butterfly #(.Q(3329)) butterfly (
                .a(coeff_in[((i + 128) * 12) +: 12]),
                .b(coeff_in[((i + 160) * 12) +: 12]),
                .zeta(zeta2),
                .u(coeff_out[((i + 128) * 12) +: 12]),
                .v(coeff_out[((i + 160) * 12) +: 12])
            );
        end

        for (i = 0; i < 32; i = i + 1) begin : GEN_GROUP3
            ntt_butterfly #(.Q(3329)) butterfly (
                .a(coeff_in[((i + 192) * 12) +: 12]),
                .b(coeff_in[((i + 224) * 12) +: 12]),
                .zeta(zeta3),
                .u(coeff_out[((i + 192) * 12) +: 12]),
                .v(coeff_out[((i + 224) * 12) +: 12])
            );
        end
    endgenerate

endmodule
