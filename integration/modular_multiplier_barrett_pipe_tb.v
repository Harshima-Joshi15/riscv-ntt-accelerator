`timescale 1ns/1ps

module modular_multiplier_barrett_pipe_tb;

    reg clk = 0;
    reg rst = 1;
    reg start = 0;
    reg [11:0] a = 0;
    reg [11:0] b = 0;

    wire [11:0] result;
    wire done;

    integer expected [0:10000];
    integer i;
    integer errors = 0;
    integer total = 10000;

    modular_multiplier_barrett_pipe dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(a),
        .b(b),
        .result(result),
        .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        repeat (3) @(negedge clk);
        rst = 0;

        // Issue 10,000 consecutive transactions.
        for (i = 0; i < total + 7; i = i + 1) begin
            @(negedge clk);

            if (i < total) begin
                start = 1;

                // Boundary vectors first, then random coefficients.
                case (i)
                    0: begin a = 0; b = 0; end
                    1: begin a = 3328; b = 3328; end
                    2: begin a = 3328; b = 1; end
                    3: begin a = 1; b = 3328; end
                    4: begin a = 3327; b = 3328; end
                    5: begin a = 3328; b = 3327; end
                    6: begin a = 100; b = 200; end
                    7: begin a = 3329; b = 3329; end
                    default: begin
                        a = $urandom_range(0, 3328);
                        b = $urandom_range(0, 3328);
                    end
                endcase

                expected[i] = (a * b) % 3329;
            end else begin
                start = 0;
                a = 0;
                b = 0;
            end

            @(posedge clk);
            #1;

            if (i >= 7) begin
                if (!done) begin
                    $display("FAIL: Missing done at transaction %0d", i-7);
                    errors = errors + 1;
                end else if (result !== expected[i-7]) begin
                    $display("FAIL: transaction=%0d expected=%0d got=%0d",
                             i-7, expected[i-7], result);
                    errors = errors + 1;
                end
            end else if (done) begin
                $display("FAIL: Unexpected early done at cycle %0d", i);
                errors = errors + 1;
            end
        end

        if (errors == 0)
            $display("PASS: 10000 transactions, continuous throughput, 8-cycle latency.");
        else
            $display("FAIL: %0d errors.", errors);

        $finish;
    end

endmodule
