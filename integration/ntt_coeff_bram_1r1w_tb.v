`timescale 1ns/1ps

module ntt_coeff_bram_1r1w_tb;

    reg clk = 0;

    reg rd_en = 0;
    reg [7:0] rd_addr = 0;
    wire [11:0] rd_data;

    reg wr_en = 0;
    reg [7:0] wr_addr = 0;
    reg [11:0] wr_data = 0;

    integer errors = 0;

    ntt_coeff_bram_1r1w dut (
        .clk(clk),
        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data)
    );

    always #5 clk = ~clk;

    initial begin
        $display("======================================");
        $display("   BRAM 1R1W FUNCTIONAL VERIFICATION");
        $display("======================================");

        // Test 1: Write address 0.
        @(negedge clk);
        wr_en = 1;
        wr_addr = 0;
        wr_data = 123;

        @(posedge clk);
        #1;
        $display("PASS: Write to address 0 completed.");

        // Test 2: Synchronous read address 0.
        @(negedge clk);
        wr_en = 0;
        rd_en = 1;
        rd_addr = 0;

        @(posedge clk);
        #1;
        if (rd_data === 12'd123)
            $display("PASS: Synchronous read returned 123.");
        else begin
            $display("FAIL: Expected 123, got %0d.", rd_data);
            errors = errors + 1;
        end

        // Test 3: Output holds when read is disabled.
        @(negedge clk);
        rd_en = 0;
        rd_addr = 8'd1;

        @(posedge clk);
        #1;
        if (rd_data === 12'd123)
            $display("PASS: Read output holds when disabled.");
        else begin
            $display("FAIL: Read output did not hold.");
            errors = errors + 1;
        end

        // Test 4: Simultaneous independent read and write.
        @(negedge clk);
        rd_en = 1;
        rd_addr = 0;
        wr_en = 1;
        wr_addr = 255;
        wr_data = 3328;

        @(posedge clk);
        #1;
        if (rd_data === 12'd123)
            $display("PASS: Independent simultaneous read/write.");
        else begin
            $display("FAIL: Simultaneous read returned %0d.", rd_data);
            errors = errors + 1;
        end

        // Test 5: Read boundary address 255.
        @(negedge clk);
        wr_en = 0;
        rd_addr = 255;

        @(posedge clk);
        #1;
        if (rd_data === 12'd3328)
            $display("PASS: Boundary address 255 returned 3328.");
        else begin
            $display("FAIL: Expected 3328, got %0d.", rd_data);
            errors = errors + 1;
        end

        // Test 6: Write and read middle address 128.
        @(negedge clk);
        rd_en = 0;
        wr_en = 1;
        wr_addr = 128;
        wr_data = 2048;

        @(posedge clk);

        @(negedge clk);
        wr_en = 0;
        rd_en = 1;
        rd_addr = 128;

        @(posedge clk);
        #1;
        if (rd_data === 12'd2048)
            $display("PASS: Middle address 128 returned 2048.");
        else begin
            $display("FAIL: Expected 2048, got %0d.", rd_data);
            errors = errors + 1;
        end

        $display("--------------------------------------");
        if (errors == 0)
            $display("RESULT: ALL TESTS PASSED.");
        else
            $display("RESULT: %0d TEST(S) FAILED.", errors);

        $display("--------------------------------------");
        $finish;
    end

endmodule
