`timescale 1ns/1ps

module ntt_coeff_bram_tb;

    reg clk = 0;

    reg en_a = 0, we_a = 0;
    reg [7:0] addr_a = 0;
    reg [11:0] din_a = 0;
    wire [11:0] dout_a;

    reg en_b = 0, we_b = 0;
    reg [7:0] addr_b = 0;
    reg [11:0] din_b = 0;
    wire [11:0] dout_b;

    integer errors = 0;

    ntt_coeff_bram dut (
        .clk(clk),
        .en_a(en_a), .we_a(we_a),
        .addr_a(addr_a), .din_a(din_a), .dout_a(dout_a),
        .en_b(en_b), .we_b(we_b),
        .addr_b(addr_b), .din_b(din_b), .dout_b(dout_b)
    );

    always #5 clk = ~clk;

    initial begin
        $display("================================");
        $display("   COEFFICIENT BRAM TEST");
        $display("================================");

        // Simultaneous writes to different addresses.
        @(negedge clk);
        en_a = 1; we_a = 1; addr_a = 8'd10; din_a = 12'd1234;
        en_b = 1; we_b = 1; addr_b = 8'd20; din_b = 12'd2345;

        @(posedge clk);
        #1;
        if (dout_a !== 12'dx && dout_b !== 12'dx)
            $display("INFO: Initial write outputs observed.");

        // Read both independently written locations.
        @(negedge clk);
        we_a = 0; addr_a = 8'd10;
        we_b = 0; addr_b = 8'd20;

        @(posedge clk);
        #1;
        if (dout_a === 12'd1234 && dout_b === 12'd2345)
            $display("PASS: Both ports read their written values.");
        else begin
            $display("FAIL: Read A=%0d B=%0d", dout_a, dout_b);
            errors = errors + 1;
        end

        // Write different locations simultaneously again.
        @(negedge clk);
        we_a = 1; addr_a = 8'd11; din_a = 12'd321;
        we_b = 1; addr_b = 8'd21; din_b = 12'd654;

        @(posedge clk);
        #1;

        // Read the second pair.
        @(negedge clk);
        we_a = 0; addr_a = 8'd11;
        we_b = 0; addr_b = 8'd21;

        @(posedge clk);
        #1;
        if (dout_a === 12'd321 && dout_b === 12'd654)
            $display("PASS: Simultaneous independent writes work.");
        else begin
            $display("FAIL: Second read A=%0d B=%0d", dout_a, dout_b);
            errors = errors + 1;
        end

        // Verify outputs hold when a port is disabled.
        @(negedge clk);
        en_a = 0; en_b = 0;
        addr_a = 8'd99; addr_b = 8'd99;

        @(posedge clk);
        #1;
        if (dout_a === 12'd321 && dout_b === 12'd654)
            $display("PASS: Outputs hold while ports are disabled.");
        else begin
            $display("FAIL: Output hold behavior incorrect.");
            errors = errors + 1;
        end

        $display("--------------------------------");
        if (errors == 0)
            $display("RESULT: ALL BRAM TESTS PASSED.");
        else
            $display("RESULT: %0d TEST(S) FAILED.", errors);
        $display("--------------------------------");

        $finish;
    end

endmodule
