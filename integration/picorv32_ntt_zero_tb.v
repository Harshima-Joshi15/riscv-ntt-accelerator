`timescale 1ns/1ps

module picorv32_ntt_zero_tb;

    reg clk = 0;
    reg resetn = 0;

    integer cycle;
    integer i;
    integer errors;

    reg [31:0] expected_mem [0:255];

    picorv32_ntt_top #(
        .PROGRAM_FILE("firmware/firmware_zero.hex"),
        .PROGRAM_LAST_WORD(36)
    ) dut (
        .clk(clk),
        .resetn(resetn)
    );

    always #5 clk = ~clk;

    initial begin
        $display("========================================");
        $display(" PicoRV32 + NTT Accelerator Integration");
        $display(" Zero Input Golden Reference Test");
        $display("========================================");

        errors = 0;

        /* Load 256 expected NTT coefficients */
       $readmemh("firmware/expected_ntt_zero.hex", expected_mem);

        repeat (10) @(posedge clk);
        resetn = 1;

        $display("Reset released. CPU executing firmware...");

        /* Wait for firmware completion */
        for (cycle = 0; cycle < 200000; cycle = cycle + 1) begin
            @(posedge clk);

            if (dut.trap) begin
                $display("FAIL: PicoRV32 trap at cycle %0d", cycle);
                $finish;
            end

            if (dut.memory.data_mem[2] == 1) begin
                $display("Firmware completed at cycle %0d", cycle);

                if (dut.memory.data_mem[0] !== 1) begin
                    $display("FAIL: Firmware reported NTT mismatch.");
                    $display("Mismatch index: %0d",
                             dut.memory.data_mem[1]);

                    if (dut.memory.data_mem[1] < 256) begin
                        i = dut.memory.data_mem[1];

                        $display("Hardware output: %0d",
                                 dut.accelerator.engine.coeff_mem[i]);

                        $display("Expected output: %0d",
                                 expected_mem[i]);
                    end

                    $finish;
                end

                $display("PASS: Firmware comparison succeeded.");

                /* Independently verify every hardware coefficient */
                for (i = 0; i < 256; i = i + 1) begin
                    if (dut.accelerator.engine.coeff_mem[i]
                        !== expected_mem[i][11:0]) begin

                        $display("FAIL: Output mismatch at index %0d", i);
                        $display("Hardware: %0d",
                                 dut.accelerator.engine.coeff_mem[i]);
                        $display("Expected: %0d",
                                 expected_mem[i][11:0]);

                        errors = errors + 1;
                    end
                end

                if (errors == 0) begin
                    $display("PASS: All 256 hardware coefficients match.");
                    $display("========================================");
                    $display(" CPU-ACCELERATOR INTEGRATION PASSED");
                    $display("========================================");
                end else begin
                    $display("FAIL: %0d coefficient mismatches.", errors);
                end

                $finish;
            end
        end

        $display("FAIL: Timeout. Firmware did not complete.");
        $display("Result memory: %h", dut.memory.data_mem[0]);
        $display("Done flag: %h", dut.memory.data_mem[2]);
        $display("CPU trap: %b", dut.trap);
        $finish;
    end

endmodule
