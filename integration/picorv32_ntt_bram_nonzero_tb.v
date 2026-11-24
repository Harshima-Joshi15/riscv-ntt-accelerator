
`timescale 1ns/1ps

module picorv32_ntt_bram_nonzero_tb;

    reg clk = 0;
    reg resetn = 0;

    integer cycle;
    integer i;
    integer j;
    integer input_errors;
    integer output_errors;

    reg [31:0] expected_mem [0:255];
    reg [31:0] expected_input_mem [0:255];

    picorv32_ntt_bram_top #(
        .PROGRAM_FILE("firmware/firmware_nonzero_initwait.hex"),
        .PROGRAM_LAST_WORD(198)
    ) dut (
        .clk(clk),
        .resetn(resetn)
    );

    always #5 clk = ~clk;

    // Verify all input coefficients when the accelerator starts.
    always @(posedge clk) begin
        if (resetn && dut.accelerator.start) begin
            input_errors = 0;

            for (j = 0; j < 256; j = j + 1) begin
                if (dut.accelerator.engine.coeff_bram.mem[j]
                    !== expected_input_mem[j][11:0]) begin

                    input_errors = input_errors + 1;

                    if (input_errors <= 5)
                        $display(
                            "INPUT ERROR [%0d]: got %0d expected %0d",
                            j,
                            dut.accelerator.engine.coeff_bram.mem[j],
                            expected_input_mem[j][11:0]
                        );
                end
            end

            if (input_errors != 0)
                $fatal(1,
                    "FAIL: Input BRAM verification failed: %0d errors",
                    input_errors);

            $display("PASS: All 256 non-zero input coefficients verified.");
        end
    end

    initial begin
        $display("========================================");
        $display(" PicoRV32 + BRAM NTT Integration");
        $display(" Non-Zero Golden Reference Test");
        $display("========================================");

        input_errors = 0;
        output_errors = 0;

        // Load expected NTT output.
        $readmemh("firmware/expected_ntt_nonzero.hex", expected_mem);

        // Reproduce the input formula from main_nonzero_test.c:
        // a[i] = (37*i + 123) mod 3329
        for (i = 0; i < 256; i = i + 1)
            expected_input_mem[i] = (i * 37 + 123) % 3329;

        repeat (10) @(posedge clk);
        resetn = 1;

        $display("Reset released. CPU executing non-zero firmware...");

        for (cycle = 0; cycle < 200000; cycle = cycle + 1) begin
            @(posedge clk);

            if (dut.trap)
                $fatal(1, "FAIL: PicoRV32 trap at cycle %0d", cycle);

            if (dut.memory.data_mem[2] == 1) begin
                $display("Firmware completed at cycle %0d", cycle);

                if (dut.memory.data_mem[0] !== 1)
                    $fatal(1,
                        "FAIL: Firmware comparison failed. Mismatch index: %0d",
                        dut.memory.data_mem[1]);

                $display("PASS: Firmware comparison succeeded.");

                // Independently verify all 256 hardware output coefficients.
                for (i = 0; i < 256; i = i + 1) begin
                    if (dut.accelerator.engine.coeff_bram.mem[i]
                        !== expected_mem[i][11:0]) begin

                        output_errors = output_errors + 1;

                        if (output_errors <= 5)
                            $display(
                                "OUTPUT ERROR [%0d]: hardware=%0d expected=%0d",
                                i,
                                dut.accelerator.engine.coeff_bram.mem[i],
                                expected_mem[i][11:0]
                            );
                    end
                end

                if (output_errors != 0)
                    $fatal(1,
                        "FAIL: %0d hardware output mismatches.",
                        output_errors);

                $display("PASS: All 256 hardware coefficients match.");
                $display("========================================");
                $display(" NON-ZERO CPU-BRAM-NTT INTEGRATION PASSED");
                $display("========================================");
                $finish;
            end
        end

        $fatal(1,
            "FAIL: Timeout. Result=%h Done=%h Trap=%b",
            dut.memory.data_mem[0],
            dut.memory.data_mem[2],
            dut.trap);
    end

endmodule
