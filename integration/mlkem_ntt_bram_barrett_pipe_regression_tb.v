
`timescale 1ns/1ps

module mlkem_ntt_bram_regression_tb;

    reg clk = 0;
    reg rst = 1;
    reg old_start = 0;
    reg new_start = 0;

    reg [3071:0] coeff_in = 0;
    wire [3071:0] old_coeff_out;
    wire old_busy, old_done;

    reg cpu_wr_en = 0;
    reg [7:0] cpu_wr_addr = 0;
    reg [11:0] cpu_wr_data = 0;
    reg cpu_rd_en = 0;
    reg [7:0] cpu_rd_addr = 0;
    wire [11:0] cpu_rd_data;

    wire init_done, new_busy, new_done;

    reg [31:0] expected_mem [0:255];

    integer failures = 0;
    integer total_tests = 0;
    integer golden_errors = 0;
    integer i;

    always #5 clk = ~clk;

    mlkem_ntt_engine old_engine (
        .clk(clk), .rst(rst), .start(old_start),
        .coeff_in(coeff_in), .coeff_out(old_coeff_out),
        .busy(old_busy), .done(old_done)
    );

    mlkem_ntt_bram_engine_barrett_pipe new_engine (
        .clk(clk), .rst(rst), .start(new_start),
        .cpu_wr_en(cpu_wr_en),
        .cpu_wr_addr(cpu_wr_addr),
        .cpu_wr_data(cpu_wr_data),
        .cpu_rd_en(cpu_rd_en),
        .cpu_rd_addr(cpu_rd_addr),
        .cpu_rd_data(cpu_rd_data),
        .init_done(init_done),
        .busy(new_busy), .done(new_done)
    );

    function [11:0] test_value;
        input integer pattern;
        input integer index;
        begin
            case (pattern)
                0: test_value = (index * 37 + 123) % 3329;
                1: test_value = 3320 + (index % 9);
                2: test_value = (index * 1103 + index * index * 17 + 2027) % 4096;
                default: test_value = 0;
            endcase
        end
    endfunction

    task run_case;
        input integer pattern;
        input [160*8-1:0] case_name;
        reg [11:0] value;
        begin
            $display("--------------------------------------");
            $display("Testing: %0s", case_name);

            // Load identical input vectors into both engines.
            for (i = 0; i < 256; i = i + 1) begin
                value = test_value(pattern, i);
                coeff_in[i*12 +: 12] = value;

                @(negedge clk);
                cpu_wr_en = 1;
                cpu_wr_addr = i;
                cpu_wr_data = value;

                @(negedge clk);
                cpu_wr_en = 0;
            end

            // Start both engines.
            @(negedge clk);
            old_start = 1;
            new_start = 1;

            @(negedge clk);
            old_start = 0;
            new_start = 0;

            wait (old_done);
            wait (new_done);

            if (old_busy !== 0 || new_busy !== 0) begin
                $display("FAIL: BUSY did not clear.");
                failures = failures + 1;
            end

            // Compare original engine against the golden reference.
            if (pattern == 0) begin
                golden_errors = 0;
                $display("GOLDEN REFERENCE CHECK - ORIGINAL ENGINE");

                for (i = 0; i < 256; i = i + 1) begin
                    if (old_coeff_out[i*12 +: 12]
                        !== expected_mem[i][11:0]) begin
                        golden_errors = golden_errors + 1;

                        if (golden_errors <= 8)
                            $display(
                                "Index %0d: Original=%0d Expected=%0d",
                                i,
                                old_coeff_out[i*12 +: 12],
                                expected_mem[i][11:0]
                            );
                    end
                end

                $display("Original engine golden mismatches: %0d",
                         golden_errors);
                failures = failures + golden_errors;
            end

            // Compare all 256 BRAM coefficients against original engine.
            for (i = 0; i < 256; i = i + 1) begin
                @(negedge clk);
                cpu_rd_en = 1;
                cpu_rd_addr = i;

                @(posedge clk);
                #1;

                total_tests = total_tests + 1;

                if (cpu_rd_data !== old_coeff_out[i*12 +: 12]) begin
                    $display("FAIL: Index %0d, BRAM=%0d, Original=%0d",
                        i, cpu_rd_data, old_coeff_out[i*12 +: 12]);
                    failures = failures + 1;
                end

                @(negedge clk);
                cpu_rd_en = 0;
            end

            if (failures == 0)
                $display("PASS: All 256 coefficients match.");
            else
                $display("Mismatch count so far: %0d", failures);
        end
    endtask

    initial begin
        $display("======================================");
        $display(" BRAM ENGINE REGRESSION TEST");
        $display(" WITH GOLDEN REFERENCE CHECK");
        $display("======================================");

        $readmemh("firmware/expected_ntt_nonzero.hex", expected_mem);

        repeat (3) @(negedge clk);
        rst = 0;

        wait (init_done);

        run_case(0, "Nonzero coefficients");
        run_case(1, "Near-modulus coefficients");
        run_case(2, "Pseudo-random coefficients");
        run_case(3, "Zero coefficients");

        $display("======================================");
        $display("Total coefficient comparisons: %0d", total_tests);
        $display("Golden reference mismatches: %0d", golden_errors);

        if (failures == 0)
            $display("RESULT: ALL REGRESSION TESTS PASSED.");
        else
            $display("RESULT: %0d FAILURES.", failures);

        $display("======================================");
        $finish;
    end

    initial begin
        repeat (100000) @(posedge clk);
        $display("FAIL: Global simulation timeout.");
        $finish;
    end

endmodule
