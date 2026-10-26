
`timescale 1ns/1ps

module testbench;

    reg [3071:0] coeff_in;
    reg [11:0] zeta;
    wire [3071:0] coeff_out;

    integer i;
    integer pattern;
    integer errors;
    integer expected_t;
    integer expected_u;
    integer expected_v;
    integer actual_u;
    integer actual_v;
    integer a_value;
    integer b_value;

    ntt_stage128 dut (
        .coeff_in(coeff_in),
        .zeta(zeta),
        .coeff_out(coeff_out)
    );

    // Generate five deterministic input patterns.
    function integer input_value;
        input integer index;
        input integer pattern_id;
        begin
            case (pattern_id)
                0: input_value = 0;
                1: input_value = 3328;
                2: input_value = index % 3329;
                3: input_value = (index * 37 + 123) % 3329;
                4: begin
                    if (index % 2 == 0)
                        input_value = 0;
                    else
                        input_value = 3328;
                end
                default: input_value = 0;
            endcase
        end
    endfunction

    initial begin
        errors = 0;
        zeta = 12'd1729;

        $display("======================================");
        $display("MULTI-PATTERN NTT STAGE VERIFICATION");
        $display("======================================");

        for (pattern = 0; pattern < 5; pattern = pattern + 1) begin

            for (i = 0; i < 256; i = i + 1)
                coeff_in[i*12 +: 12] = input_value(i, pattern);

            #10;

            for (i = 0; i < 128; i = i + 1) begin
                a_value = input_value(i, pattern);
                b_value = input_value(i + 128, pattern);

                expected_t = (b_value * 1729) % 3329;
                expected_u = (a_value + expected_t) % 3329;
                expected_v = (a_value - expected_t + 3329) % 3329;

                actual_u = coeff_out[i*12 +: 12];
                actual_v = coeff_out[(i+128)*12 +: 12];

                if ((actual_u !== expected_u) ||
                    (actual_v !== expected_v)) begin
                    errors = errors + 1;
                    $display(
                        "FAIL pattern=%0d butterfly=%0d expected=(%0d,%0d) actual=(%0d,%0d)",
                        pattern, i, expected_u, expected_v,
                        actual_u, actual_v
                    );
                end
            end

            case (pattern)
                0: $display("Pattern 0: all zeros checked");
                1: $display("Pattern 1: all 3328 checked");
                2: $display("Pattern 2: sequential coefficients checked");
                3: $display("Pattern 3: mixed coefficients checked");
                4: $display("Pattern 4: alternating boundary values checked");
            endcase
        end

        $display("--------------------------------------");
        $display("Patterns tested: 5");
        $display("Butterflies checked: 640");
        $display("Total mismatches: %0d", errors);

        if (errors == 0)
            $display("PASS: All five patterns passed.");
        else
            $display("FAIL: One or more patterns failed.");

        $display("======================================");
        $finish;
    end

endmodule
