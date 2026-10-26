
module testbench;

    reg  [11:0] a, b;
    wire [11:0] result;

    modular_multiplier uut (
        .a(a),
        .b(b),
        .result(result)
    );

    initial begin
        $display("Testing modular multiplier");

        a = 100;  b = 200;
        #10;
        $display("100 * 200 mod 3329 = %0d", result);

        a = 3300; b = 100;
        #10;
        $display("3300 * 100 mod 3329 = %0d", result);

        a = 1000; b = 2000;
        #10;
        $display("1000 * 2000 mod 3329 = %0d", result);

        a = 3328; b = 3328;
        #10;
        $display("3328 * 3328 mod 3329 = %0d", result);

        $finish;
    end

endmodule
