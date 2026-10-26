
module testbench;

    reg  [11:0] a, b;
    wire [11:0] result;

    modular_adder uut (
        .a(a),
        .b(b),
        .result(result)
    );

    initial begin
        $display("Testing modular addition");

        a = 3300; b = 100;
        #10;
        $display("3300 + 100 mod 3329 = %0d", result);

        a = 1000; b = 2000;
        #10;
        $display("1000 + 2000 mod 3329 = %0d", result);

        a = 0; b = 0;
        #10;
        $display("0 + 0 mod 3329 = %0d", result);

        $finish;
    end

endmodule
