`timescale 1ns/1ps

module ntt_load_reduction_tb;

    reg clk = 0;
    reg rst = 1;
    reg start = 0;

    reg [3071:0] coeff_in;
    wire [3071:0] coeff_out;
    wire busy;
    wire done;

    reg [11:0] raw_value;
    reg [11:0] expected_value;

    integer i;
    integer errors;

    always #5 clk = ~clk;

    mlkem_ntt_engine dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .coeff_in(coeff_in),
        .coeff_out(coeff_out),
        .busy(busy),
        .done(done)
    );

    initial begin
        coeff_in = 0;
        errors = 0;

        for (i = 0; i < 256; i = i + 1) begin
            case (i % 8)
                0: raw_value = 12'd0;
                1: raw_value = 12'd1;
                2: raw_value = 12'd3328;
                3: raw_value = 12'd3329;
                4: raw_value = 12'd3330;
                5: raw_value = 12'd4094;
                6: raw_value = 12'd4095;
                default: raw_value = (i * 37 + 123) & 12'hFFF;
            endcase

            coeff_in[i*12 +: 12] = raw_value;
        end

        repeat (2) @(negedge clk);

        rst = 0;
        start = 1;

        @(negedge clk);
        start = 0;

        @(negedge clk);
        #1;

        for (i = 0; i < 256; i = i + 1) begin
            raw_value = coeff_in[i*12 +: 12];

            if (raw_value >= 12'd3329)
                expected_value = raw_value - 12'd3329;
            else
                expected_value = raw_value;

            if (dut.coeff_mem[i] !== expected_value) begin
                $display(
                    "FAIL: index=%0d input=%0d actual=%0d expected=%0d",
                    i, raw_value, dut.coeff_mem[i], expected_value
                );
                errors = errors + 1;
            end
        end

        if (errors == 0)
            $display("PASS: All 256 coefficient reductions verified.");
        else
            $display("FAIL: %0d coefficient mismatches.", errors);

        $finish;
    end

endmodule
