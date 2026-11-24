
`timescale 1ns/1ps

module ntt_mmio_control_tb;

    reg clk = 0;
    reg rst = 1;
    reg wr_en = 0;
    reg rd_en = 0;
    reg [11:0] addr = 0;
    reg [31:0] wdata = 0;
    wire [31:0] rdata;

    integer errors = 0;
    integer timeout_count;
    reg [31:0] status;
    reg [11:0] saved_input;

    always #5 clk = ~clk;

    ntt_accelerator_mmio dut (
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

    task read_reg;
        input [11:0] read_addr;
        output [31:0] read_data;
        begin
            addr = read_addr;
            rd_en = 1;
            #1;
            read_data = rdata;
            rd_en = 0;
            addr = 0;
        end
    endtask

    task wait_for_busy;
        begin
            timeout_count = 0;
            status = 0;

            while (status[0] !== 1'b1 && timeout_count < 20) begin
                @(negedge clk);
                read_reg(12'h004, status);
                timeout_count = timeout_count + 1;
            end

            if (status[0] !== 1'b1) begin
                $display("FAIL: BUSY was not asserted.");
                errors = errors + 1;
            end else
                $display("PASS: BUSY asserted after START.");
        end
    endtask

    task wait_for_done;
        begin
            timeout_count = 0;
            status = 0;

            while (status[1] !== 1'b1 && timeout_count < 2000) begin
                @(negedge clk);
                read_reg(12'h004, status);
                timeout_count = timeout_count + 1;
            end

            if (status[1] !== 1'b1) begin
                $display("FAIL: DONE was not asserted within timeout.");
                errors = errors + 1;
            end else
                $display("PASS: DONE sticky flag asserted.");

            if (status[0] !== 1'b0) begin
                $display("FAIL: BUSY did not clear after completion.");
                errors = errors + 1;
            end else
                $display("PASS: BUSY cleared after completion.");
        end
    endtask

    initial begin
        $display("======================================");
        $display("   MMIO CONTROL VERIFICATION");
        $display("======================================");

        repeat (3) @(negedge clk);
        rst = 0;
        @(negedge clk);

        // TEST 1: Reset status.
        read_reg(12'h004, status);

        if (status[1:0] !== 2'b00) begin
            $display("FAIL: Status register not clear after reset.");
            errors = errors + 1;
        end else
            $display("PASS: Reset clears status register.");

        // TEST 2: Reset input memory.
        if (dut.input_mem[0] !== 12'd0) begin
            $display("FAIL: Input memory not cleared by reset.");
            errors = errors + 1;
        end else
            $display("PASS: Reset clears input memory.");

        // TEST 3: START with bit 0 cleared.
        write_reg(12'h000, 32'd0);

        if (dut.start !== 1'b0) begin
            $display("FAIL: Internal START pulse generated when bit 0 was cleared.");
            errors = errors + 1;
        end else
            $display("PASS: No internal START pulse generated.");

        @(posedge clk);
        #1;

        read_reg(12'h004, status);

        if (status[0] !== 1'b0 || status[1] !== 1'b0) begin
            $display("FAIL: START with bit 0 cleared changed accelerator status.");
            errors = errors + 1;
        end else
            $display("PASS: Accelerator remains idle when START bit is cleared.");

        // TEST 4: Valid and misaligned input writes.
        write_reg(12'h100, 32'd123);
        write_reg(12'h101, 32'd999);

        if (dut.input_mem[0] !== 12'd123) begin
            $display("FAIL: Misaligned input write was not rejected.");
            errors = errors + 1;
        end else
            $display("PASS: Misaligned input write rejected.");

        // TEST 5: Invalid-address writes.
        write_reg(12'h0FC, 32'd111);
        write_reg(12'h500, 32'd222);
        write_reg(12'hFFF, 32'd333);

        // TEST 6: Invalid and misaligned reads.
        read_reg(12'h0FC, status);

        if (status !== 32'd0) begin
            $display("FAIL: Invalid read at 0x0FC returned %h.", status);
            errors = errors + 1;
        end else
            $display("PASS: Invalid read at 0x0FC returns zero.");

        read_reg(12'h501, status);

        if (status !== 32'd0) begin
            $display("FAIL: Misaligned output read returned %h.", status);
            errors = errors + 1;
        end else
            $display("PASS: Misaligned output read returns zero.");

        read_reg(12'h900, status);

        if (status !== 32'd0) begin
            $display("FAIL: Invalid read at 0x900 returned %h.", status);
            errors = errors + 1;
        end else
            $display("PASS: Invalid read at 0x900 returns zero.");

        read_reg(12'hFFF, status);

        if (status !== 32'd0) begin
            $display("FAIL: Invalid read at 0xFFF returned %h.", status);
            errors = errors + 1;
        end else
            $display("PASS: Invalid read at 0xFFF returns zero.");

        if (dut.input_mem[0] !== 12'd123) begin
            $display("FAIL: Invalid-address writes modified input memory.");
            errors = errors + 1;
        end else
            $display("PASS: Invalid-address writes rejected.");

        // TEST 7: Verify valid MMIO input write.
        if (dut.input_mem[0] !== 12'd123) begin
            $display("FAIL: Valid MMIO input write stored incorrectly.");
            errors = errors + 1;
        end else
            $display("PASS: Valid MMIO input write stored correctly.");

        // TEST 8: Start accelerator.
        write_reg(12'h000, 32'd1);
        wait_for_busy();

        // TEST 9: Input write protection while BUSY.
        saved_input = dut.input_mem[0];
        write_reg(12'h100, 32'd456);

        if (dut.input_mem[0] !== saved_input) begin
            $display("FAIL: Input memory changed during BUSY.");
            errors = errors + 1;
        end else
            $display("PASS: Input write rejected while BUSY.");

        // TEST 10: START while BUSY must be ignored.
        write_reg(12'h000, 32'd1);
        read_reg(12'h004, status);

        if (status[0] !== 1'b1 || status[1] !== 1'b0) begin
            $display("FAIL: START while BUSY affected accelerator status.");
            errors = errors + 1;
        end else
            $display("PASS: START while BUSY ignored.");

        wait_for_done();

        // TEST 11: Verify output register.
        read_reg(12'h500, status);

        if (status[11:0] !== 12'd123) begin
            $display("FAIL: MMIO output read mismatch. Actual=%0d Expected=123.",
                     status[11:0]);
            errors = errors + 1;
        end else
            $display("PASS: MMIO output register returns correct NTT result.");

        // TEST 12: New START clears DONE.
        write_reg(12'h100, 32'd789);
        write_reg(12'h000, 32'd1);
        read_reg(12'h004, status);

        if (status[1] !== 1'b0) begin
            $display("FAIL: DONE sticky flag did not clear on new START.");
            errors = errors + 1;
        end else
            $display("PASS: New START clears DONE sticky flag.");

        wait_for_busy();
        wait_for_done();
// Verify output of the second operation.
read_reg(12'h500, status);

if (status[11:0] !== 12'd789) begin
    $display("FAIL: Second operation output mismatch. Actual=%0d Expected=789.",
             status[11:0]);
    errors = errors + 1;
end else
    $display("PASS: Repeated operation produces correct NTT result.");
    
        // TEST 13: Reset after completion.
        rst = 1;
        repeat (2) @(negedge clk);
        rst = 0;
        @(negedge clk);

        read_reg(12'h004, status);

        if (status[1:0] !== 2'b00) begin
            $display("FAIL: Reset did not clear completion status.");
            errors = errors + 1;
        end else
            $display("PASS: Reset clears completion status.");

        $display("--------------------------------------");

        if (errors == 0)
            $display("RESULT: ALL MMIO CONTROL TESTS PASSED.");
        else
            $display("RESULT: %0d MMIO CONTROL TESTS FAILED.", errors);

        $display("--------------------------------------");
        $finish;
    end

    initial begin
        #30000;
        $display("FAIL: Global simulation timeout.");
        $finish;
    end

endmodule
