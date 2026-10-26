
`timescale 1ns/1ps

module ntt_twiddle_lookup (
    input  wire [6:0] addr,
    output wire [11:0] zeta
);

    ntt_twiddle_rom rom (
        .addr(addr),
        .zeta(zeta)
    );

endmodule
