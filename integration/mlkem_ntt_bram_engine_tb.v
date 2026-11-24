`timescale 1ns/1ps

module mlkem_ntt_bram_engine_tb;

    reg clk = 0;
    reg rst = 1;
    reg old_start = 0;

    reg [3071:0] coeff_in = 0;
    wire [3071:0] old_coeff_out;
    wire old_busy, old_done;

    reg cpu_wr_en = 0;
    reg [7:0] cpu_wr_addr = 0;
    reg [11:0] cpu_wr_data = 0;

    reg cpu_rd_en = 0;
    reg [7:0] cpu_rd_addr = 0;
    wire [11:0] cpu_rd_data;

    reg new_start = 0;
    wire init_done, new_busy, new_done;

    integer i;
    integer failures = 0;

    always #5 clk = ~clk;

    // Original reference engine.
    mlkem_ntt_engine old_engine (
        .clk(clk),
        .rst(rst),
        .start(old_start),
        .coeff_in(coeff_in),
        .coeff_out(old_coeff_out),
        .busy(old_busy),
        .done(old_done)
    );

    // New BRAM-based engine.
    mlkem_ntt_bram_engine new_engine (
        .clk(clk),
        .rst(rst),
        .start(new_start),

        .cpu_wr_en(cpu_wr_en),
        .cpu_wr_addr(cpu_wr_addr),
        .cpu_wr_data(cpu_wr_data),

        .cpu_rd_en(cpu_rd_en),
        .cpu_rd_addr(cpu_rd_addr),
        .cpu_rd_data(cpu_rd_data),

        .init_done(init_done),
        .busy(new_busy),
        .done(new_done)
    );



    task write_coefficient;
        input [7:0] address;
        input [11:0] value;
        begin
            @(negedge clk);
            cpu_wr_en = 1;
            cpu_wr_addr = address;
            cpu_wr_data = value;

            @(negedge clk);
            cpu_wr_en = 0;
        end
    endtask

    initial begin
        $display("======================================");
        $display(" BRAM ENGINE VS ORIGINAL ENGINE TEST");
        $display("======================================");

        // Reset both engines.
        repeat (3) @(negedge clk);
        rst = 0;

        // Wait for the new BRAM memory initialization.
        wait (init_done == 1'b1);
        $display("PASS: BRAM initialization completed.");

        // Test vector: coefficient 0 = 123, all others = 0.
        coeff_in = 0;
        coeff_in[0 +: 12] = 12'd123;

        // Load identical input into the new engine's BRAM.
        for (i = 0; i < 256; i = i + 1) begin
            if (i == 0)
                write_coefficient(i, 12'd123);
            else
                write_coefficient(i, 12'd0);
        end

        $display("PASS: 256 input coefficients written.");

        // Start both engines.
        @(negedge clk);
        old_start = 1;
        new_start = 1;

        @(negedge clk);
        old_start = 0;
        new_start = 0;

        // Wait for both computations.
        wait (old_done == 1'b1);
        $display("PASS: Original engine completed.");

        wait (new_done == 1'b1);
        $display("PASS: BRAM engine completed.");

        if (old_busy !== 1'b0 || new_busy !== 1'b0) begin
            $display("FAIL: BUSY did not clear.");
            failures = failures + 1;
        end

        // Compare all 256 coefficients using synchronous BRAM reads.
        for (i = 0; i < 256; i = i + 1) begin
            @(negedge clk);
            cpu_rd_en = 1;
            cpu_rd_addr = i;

            @(posedge clk);
            #1;

            if (cpu_rd_data !== old_coeff_out[i*12 +: 12]) begin
                $display(
                    "FAIL: Coefficient %0d: BRAM=%0d Original=%0d",
                    i,
                    cpu_rd_data,
                    old_coeff_out[i*12 +: 12]
                );
                failures = failures + 1;
            end

            @(negedge clk);
            cpu_rd_en = 0;
        end

        $display("--------------------------------------");

        if (failures == 0) begin
            $display("RESULT: ALL 256 COEFFICIENTS MATCH.");
        end else begin
            $display("RESULT: %0d FAILURES.", failures);
        end

        $display("======================================");
        $finish;
    end

    // Global timeout.
    initial begin
        repeat (6000) @(posedge clk);
        $display("FAIL: Simulation timeout.");
        $finish;
    end

endmodule

