`timescale 1ns/1ps

module modular_multiplier_barrett_tb;

    reg  [11:0] a, b;
    wire [11:0] result;
    integer i, j;
    integer expected;
    integer count;

    modular_multiplier_barrett dut (
        .a(a), .b(b), .result(result)
    );

    initial begin
        count = 0;

        for (i = 0; i < 3329; i = i + 1) begin
            for (j = 0; j < 3329; j = j + 1) begin
                a = i;
                b = j;
                #1;
                expected = (i * j) % 3329;

                if (result !== expected[11:0]) begin
                    $display("FAIL: a=%0d b=%0d expected=%0d got=%0d",
                             i, j, expected, result);
                    $fatal(1);
                end

                count = count + 1;
            end
        end

        $display("PASS: All %0d valid input pairs verified.", count);
        $finish;
    end

endmodule
