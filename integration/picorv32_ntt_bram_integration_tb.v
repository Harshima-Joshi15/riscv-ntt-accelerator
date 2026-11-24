
`timescale 1ns/1ps

module picorv32_ntt_bram_integration_tb;

    reg clk = 0;
    reg resetn = 0;

    integer cycle;
    integer i;
    integer j;
    integer errors;
    integer accepted_writes = 0;
    integer input_errors;
    integer output_errors;

    reg [31:0] expected_mem [0:255];
    reg [31:0] expected_input_mem [0:255];

    picorv32_ntt_bram_top dut (
        .clk(clk),
        .resetn(resetn)
    );

    always #5 clk = ~clk;

    // Inspect all input coefficients when the accelerator starts.
    always @(posedge clk) begin
        if (!resetn) begin
            accepted_writes <= 0;
        end else begin
            if (dut.accelerator.cpu_wr_en)
                accepted_writes <= accepted_writes + 1;

            if (dut.accelerator.start) begin
                $display("----------------------------------------");
                $display("INPUT CAPTURE AT ACCELERATOR START");
                $display("Accepted CPU writes: %0d", accepted_writes);

                input_errors = 0;

                for (j = 0; j < 256; j = j + 1) begin
                    if (dut.accelerator.engine.coeff_bram.mem[j]
                        !== expected_input_mem[j][11:0]) begin
                        input_errors = input_errors + 1;

                        if (input_errors <= 5)
                            $display(
                                "INPUT ERROR at %0d: got %0d expected %0d",
                                j,
                                dut.accelerator.engine.coeff_bram.mem[j],
                                expected_input_mem[j][11:0]
                            );
                    end
                end

                $display("Total input coefficient errors: %0d",
                         input_errors);

                for (j = 0; j < 5; j = j + 1)
                    $display("BRAM[%0d] = %0d",
                        j, dut.accelerator.engine.coeff_bram.mem[j]);

                $display("----------------------------------------");
            end
        end
    end

    initial begin
        $display("========================================");
        $display(" PicoRV32 + NTT Accelerator Integration");
        $display(" Zero Input Diagnostic Test");
        $display("========================================");

        errors = 0;
        input_errors = 0;
        output_errors = 0;

        $readmemh("firmware/expected_ntt.hex", expected_mem);
        $readmemh("firmware/zero_input.hex", expected_input_mem);

        repeat (10) @(posedge clk);
        resetn = 1;

        $display("Reset released. CPU executing firmware...");

        for (cycle = 0; cycle < 200000; cycle = cycle + 1) begin
            @(posedge clk);

            if (dut.trap) begin
                $display("FAIL: PicoRV32 trap at cycle %0d", cycle);
                $finish;
            end

            if (dut.memory.data_mem[2] == 1) begin
                $display("----------------------------------------");
                $display("Firmware completed at cycle %0d", cycle);

                $display("FIRST FIVE FINAL BRAM OUTPUTS:");
                for (i = 0; i < 5; i = i + 1)
                    $display("[%0d] Hardware=%0d Expected=%0d",
                        i,
                        dut.accelerator.engine.coeff_bram.mem[i],
                        expected_mem[i]);

                output_errors = 0;

                for (i = 0; i < 256; i = i + 1) begin
                    if (dut.accelerator.engine.coeff_bram.mem[i]
                        !== expected_mem[i][11:0]) begin
                        output_errors = output_errors + 1;

                        if (output_errors <= 5)
                            $display(
                                "OUTPUT ERROR at %0d: Hardware=%0d Expected=%0d",
                                i,
                                dut.accelerator.engine.coeff_bram.mem[i],
                                expected_mem[i][11:0]
                            );
                    end
                end

                $display("Total final BRAM output errors: %0d",
                         output_errors);

                if (dut.memory.data_mem[0] !== 1) begin
                    $display("FAIL: Firmware reported NTT mismatch.");
                    $display("Mismatch index: %0d",
                             dut.memory.data_mem[1]);
                end else begin
                    $display("Firmware reported comparison PASS.");
                end

                if (output_errors == 0) begin
                    $display("PASS: All 256 hardware coefficients match.");
                    $display("CPU-ACCELERATOR INTEGRATION PASSED");
                end else begin
                    $display("FAIL: %0d coefficient mismatches.",
                             output_errors);
                end

                $display("----------------------------------------");
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
