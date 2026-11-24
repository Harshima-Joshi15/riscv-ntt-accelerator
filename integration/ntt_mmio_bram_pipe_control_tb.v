
`timescale 1ns/1ps

module ntt_mmio_bram_control_tb;

    reg clk = 0;
    reg rst = 1;
    reg wr_en = 0;
    reg rd_en = 0;
    reg [11:0] addr = 0;
    reg [31:0] wdata = 0;
    wire [31:0] rdata;

    integer errors = 0;
    integer timeout_count;
    integer k;
    reg [31:0] status;

    always #5 clk = ~clk;

    ntt_accelerator_mmio_bram_barrett_pipe dut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata)
    );

    task write_reg;
        input [11:0] write_addr;
        input [31:0] write_data;
        begin
            @(negedge clk);
            addr = write_addr;
            wdata = write_data;
            wr_en = 1;

            @(negedge clk);
            wr_en = 0;
            addr = 0;
            wdata = 0;
        end
    endtask

    task read_status;
        output [31:0] read_data;
        begin
            @(negedge clk);
            addr = 12'h004;
            rd_en = 1;
            #1;
            read_data = rdata;
            rd_en = 0;
            addr = 0;
        end
    endtask

    task read_coefficient;
        input [11:0] read_addr;
        output [31:0] read_data;
        begin
            @(negedge clk);
            addr = read_addr;
            rd_en = 1;

            @(posedge clk);
            #1;
            read_data = rdata;

            @(negedge clk);
            rd_en = 0;
            addr = 0;
        end
    endtask

    task wait_for_ready;
        begin
            timeout_count = 0;
            status = 0;

            while (status[2] !== 1'b1 && timeout_count < 300) begin
                read_status(status);
                timeout_count = timeout_count + 1;
            end

            if (status[2] !== 1'b1) begin
                $display("FAIL: BRAM initialization did not complete.");
                errors = errors + 1;
            end
            else
                $display("PASS: BRAM initialization completed.");
        end
    endtask

    task wait_for_busy;
        begin
            timeout_count = 0;
            status = 0;

            while (status[0] !== 1'b1 && timeout_count < 20) begin
                read_status(status);
                timeout_count = timeout_count + 1;
            end

            if (status[0] !== 1'b1) begin
                $display("FAIL: BUSY was not asserted.");
                errors = errors + 1;
            end
            else
                $display("PASS: BUSY asserted after START.");
        end
    endtask

    task wait_for_done;
        begin
            timeout_count = 0;
            status = 0;

            while (status[1] !== 1'b1 && timeout_count < 50000) begin
                read_status(status);
                timeout_count = timeout_count + 1;
            end

            if (status[1] !== 1'b1) begin
                $display("FAIL: DONE was not asserted within timeout.");
                errors = errors + 1;
            end
            else
                $display("PASS: DONE sticky flag asserted.");

            if (status[0] !== 1'b0) begin
                $display("FAIL: BUSY did not clear after completion.");
                errors = errors + 1;
            end
            else
                $display("PASS: BUSY cleared after completion.");
        end
    endtask

    initial begin
        $display("======================================");
        $display(" BRAM-BASED MMIO CONTROL VERIFICATION");
        $display("======================================");

        repeat (3) @(negedge clk);
        rst = 0;

        // TEST 1: Initialization and reset status.
        wait_for_ready();
        read_status(status);

        if (status[1:0] !== 2'b00) begin
            $display("FAIL: Reset status is not clear.");
            errors = errors + 1;
        end
        else
            $display("PASS: Reset clears BUSY and DONE.");

        // TEST 2: Initialization cleared coefficient memory.
        read_coefficient(12'h500, status);

        if (status[11:0] !== 12'd0) begin
            $display("FAIL: BRAM location 0 was not initialized.");
            errors = errors + 1;
        end
        else
            $display("PASS: BRAM initialization clears coefficient memory.");

        // TEST 3: START with bit 0 cleared.
        write_reg(12'h000, 32'd0);

        if (dut.start !== 1'b0) begin
            $display("FAIL: START pulse generated with bit 0 cleared.");
            errors = errors + 1;
        end
        else
            $display("PASS: START bit 0 gating works.");

        // TEST 4: Valid and misaligned input writes.
        write_reg(12'h100, 32'd123);
        write_reg(12'h101, 32'd999);

        read_coefficient(12'h500, status);

        if (status[11:0] !== 12'd123) begin
            $display("FAIL: Valid write or misaligned-write rejection failed.");
            errors = errors + 1;
        end
        else
            $display("PASS: Valid input write accepted; misaligned write rejected.");

        // TEST 5: Invalid writes.
        write_reg(12'h0FC, 32'd111);
        write_reg(12'h500, 32'd222);
        write_reg(12'hFFF, 32'd333);

        read_coefficient(12'h500, status);

        if (status[11:0] !== 12'd123) begin
            $display("FAIL: Invalid writes modified coefficient memory.");
            errors = errors + 1;
        end
        else
            $display("PASS: Invalid-address writes rejected.");

        // TEST 6: Invalid reads.
        read_status(status);

        if (status[1:0] !== 2'b00 || status[2] !== 1'b1) begin
            $display("FAIL: Status read failed.");
            errors = errors + 1;
        end
        else
            $display("PASS: Status register read correctly.");

        @(negedge clk);
        addr = 12'h0FC;
        rd_en = 1;
        #1;
        status = rdata;
        rd_en = 0;
        addr = 0;

        if (status !== 32'd0) begin
            $display("FAIL: Invalid read at 0x0FC.");
            errors = errors + 1;
        end
        else
            $display("PASS: Invalid read at 0x0FC returns zero.");

        @(negedge clk);
        addr = 12'h501;
        rd_en = 1;
        #1;
        status = rdata;
        rd_en = 0;
        addr = 0;

        if (status !== 32'd0) begin
            $display("FAIL: Misaligned output read.");
            errors = errors + 1;
        end
        else
            $display("PASS: Misaligned output read returns zero.");

        // TEST 7: Start accelerator.
        write_reg(12'h000, 32'd1);
        wait_for_busy();

        // TEST 8: Input write protection while BUSY.
        write_reg(12'h100, 32'd456);

        if (dut.engine.coeff_bram.mem[0] === 12'd456) begin
            $display("FAIL: CPU write modified BRAM while BUSY.");
            errors = errors + 1;
        end
        else
            $display("PASS: CPU write rejected while BUSY.");

        // TEST 9: START while BUSY must be ignored.
        write_reg(12'h000, 32'd1);
        read_status(status);

        if (status[0] !== 1'b1 || status[1] !== 1'b0) begin
            $display("FAIL: START while BUSY affected status.");
            errors = errors + 1;
        end
        else
            $display("PASS: START while BUSY ignored.");

        wait_for_done();

        // TEST 10: Output read through synchronous BRAM.
        read_coefficient(12'h500, status);

        if (status[11:0] !== 12'd123) begin
            $display("FAIL: First output mismatch. Actual=%0d Expected=123.",
                     status[11:0]);
            errors = errors + 1;
        end
        else
            $display("PASS: Synchronous output read returns correct result.");

        // TEST 11: New START clears DONE.
        for (k = 0; k < 256; k = k + 1) begin
            write_reg(12'h100 + (k * 4),
                      (k == 0) ? 32'd789 : 32'd0);
        end

        write_reg(12'h000, 32'd1);
        read_status(status);

        if (status[1] !== 1'b0) begin
            $display("FAIL: DONE did not clear on new START.");
            errors = errors + 1;
        end
        else
            $display("PASS: New START clears DONE sticky flag.");

        wait_for_busy();
        wait_for_done();

        read_coefficient(12'h500, status);

        if (status[11:0] !== 12'd789) begin
            $display("FAIL: Second operation mismatch. Actual=%0d Expected=789.",
                     status[11:0]);
            errors = errors + 1;
        end
        else
            $display("PASS: Repeated operation produces correct result.");

        // TEST 12: Reset and reinitialization.
        rst = 1;
        repeat (3) @(negedge clk);
        rst = 0;

        wait_for_ready();
        read_status(status);

        if (status[1:0] !== 2'b00) begin
            $display("FAIL: Reset did not clear completion status.");
            errors = errors + 1;
        end
        else
            $display("PASS: Reset clears completion status.");

        read_coefficient(12'h500, status);

        if (status[11:0] !== 12'd0) begin
            $display("FAIL: Reset did not clear BRAM contents.");
            errors = errors + 1;
        end
        else
            $display("PASS: Reset reinitializes shared BRAM.");

        // TEST 13: Reset during active multiplier pipeline.
        write_reg(12'h100, 32'd321);
        write_reg(12'h000, 32'd1);
        wait_for_busy();

        timeout_count = 0;

        while (dut.engine.state !== 3'd7 && timeout_count < 100) begin
            @(negedge clk);
            timeout_count = timeout_count + 1;
        end

        if (dut.engine.state !== 3'd7) begin
            $display("FAIL: Engine did not reach PIPE_WAIT.");
            errors = errors + 1;
        end
        else begin
            $display("PASS: Engine reached active multiplier pipeline.");

            rst = 1;
            repeat (3) @(negedge clk);
            rst = 0;

            wait_for_ready();
            read_status(status);

            if (status[1:0] !== 2'b00) begin
                $display("FAIL: Active reset did not clear BUSY/DONE.");
                errors = errors + 1;
            end
            else
                $display("PASS: Active reset clears BUSY and DONE.");

            // Verify all 256 BRAM coefficients were cleared.
            for (k = 0; k < 256; k = k + 1) begin
                if (dut.engine.coeff_bram.mem[k] !== 12'd0) begin
                    $display("FAIL: BRAM location %0d was not cleared.", k);
                    errors = errors + 1;
                end
            end

            if (errors == 0)
                $display("PASS: Active reset clears all 256 BRAM coefficients.");
        end

        // Final result.
        $display("--------------------------------------");

        if (errors == 0) begin
            $display("RESULT: ALL BRAM MMIO TESTS PASSED.");
            $display("--------------------------------------");
            $finish;
        end
        else begin
            $display("RESULT: %0d BRAM MMIO TESTS FAILED.", errors);
            $display("--------------------------------------");
            $fatal(1, "BRAM MMIO CONTROL TEST FAILED.");
        end
    end

    // Global simulation timeout.
    initial begin
        #10000000;
        $fatal(1, "FAIL: Global simulation timeout.");
    end

endmodule
