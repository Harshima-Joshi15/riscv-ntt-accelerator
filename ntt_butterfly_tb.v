
module testbench;

    reg [11:0] a, b, zeta;
    wire [11:0] u, v;

    ntt_butterfly uut (
        .a(a),
        .b(b),
        .zeta(zeta),
        .u(u),
        .v(v)
    );

    initial begin
        $display("Testing NTT butterfly with twiddle factor");

        a = 100; b = 200; zeta = 2;
        #10;
        $display("a=%0d b=%0d zeta=%0d: u=%0d v=%0d",
                 a, b, zeta, u, v);

        a = 3300; b = 100; zeta = 3;
        #10;
        $display("a=%0d b=%0d zeta=%0d: u=%0d v=%0d",
                 a, b, zeta, u, v);

        a = 500; b = 500; zeta = 1;
        #10;
        $display("a=%0d b=%0d zeta=%0d: u=%0d v=%0d",
                 a, b, zeta, u, v);

        $finish;
    end

endmodule
