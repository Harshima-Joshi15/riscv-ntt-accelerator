
module ntt_butterfly_basic (
    input  wire [11:0] a,
    input  wire [11:0] b,
    output wire [11:0] u,
    output wire [11:0] v
);

    parameter Q = 3329;

    wire [12:0] sum;
    wire [12:0] diff;

    assign sum  = a + b;
    assign diff = (a >= b) ? (a - b) : (a + Q - b);

    assign u = (sum >= Q) ? (sum - Q) : sum;
    assign v = diff[11:0];

endmodule
