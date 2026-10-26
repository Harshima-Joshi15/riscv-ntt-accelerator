
module testbench;

    reg  [11:0] a, b;
    wire [11:0] result;

    modular_subtractor uut (
        .a(a),
        .b(b),
        .result(result)
    );

    initial begin
        $display("Testing modular subtraction");

        a = 100;  b = 200;
        #10;
        $display("100 - 200 mod 3329 = %0d", result);

        a = 3000; b = 1000;
        #10;
        $display("3000 - 1000 mod 3329 = %0d", result);

        a = 500; b = 500;
        #10;
        $display("500 - 500 mod 3329 = %0d", result);

        $finish;
    end

endmodule
