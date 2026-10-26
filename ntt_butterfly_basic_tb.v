
module testbench;

    reg  [11:0] a, b;
    wire [11:0] u, v;

    ntt_butterfly_basic uut (
        .a(a),
        .b(b),
        .u(u),
        .v(v)
    );

    initial begin
        $display("Testing basic NTT butterfly");

        a = 100; b = 200;
        #10;
        $display("a=100, b=200: u=%0d, v=%0d", u, v);

        a = 3300; b = 100;
        #10;
        $display("a=3300, b=100: u=%0d, v=%0d", u, v);

        a = 500; b = 500;
        #10;
        $display("a=500, b=500: u=%0d, v=%0d", u, v);

        $finish;
    end

endmodule
