
import json
from pathlib import Path

root = Path(__file__).resolve().parent
data = json.loads(
    (root / "stress_vectors" / "deterministic_random.json").read_text(
        encoding="utf-8"
    )
)

inputs = data["input"]
expected = data["expected"]

assert len(inputs) == 256
assert len(expected) == 256
assert inputs != expected

def verilog_array(name, values):
    lines = [f"reg [11:0] {name} [0:255];"]
    lines.append("initial begin")
    for i, value in enumerate(values):
        lines.append(f"    {name}[{i}] = 12'd{value};")
    lines.append("end")
    return "\n".join(lines)

testbench = r"""
`timescale 1ns/1ps

module testbench;

    reg clk = 0;
    reg rst = 1;
    reg start = 0;
    reg [3071:0] coeff_in = 0;
    wire busy;
    wire done;
    wire [3071:0] coeff_out;

    integer i;
    integer cycles;
    integer errors;
    reg completion_seen = 0;

    always #5 clk = ~clk;

    mlkem_ntt_engine dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .coeff_in(coeff_in),
        .busy(busy),
        .done(done),
        .coeff_out(coeff_out)
    );

    always @(posedge clk) begin
        if (done)
            completion_seen <= 1;
    end

    INPUT_ARRAY

    EXPECTED_ARRAY

    initial begin
        $display("------------------------------------------");
        $display("NTT deterministic-random vector test");
        $display("q = 3329; 256 reproducible random inputs");
        $display("------------------------------------------");

        for (i = 0; i < 256; i = i + 1)
            coeff_in[i*12 +: 12] = input_values[i];

        repeat (3) @(negedge clk);
        rst = 0;
        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;

        cycles = 0;
        while (!completion_seen && cycles < 2000) begin
            @(negedge clk);
            cycles = cycles + 1;
        end

        if (!completion_seen) begin
            $display("FAIL: NTT completion timeout.");
            $fatal(1);
        end

        $display("PASS: NTT completion detected.");

        errors = 0;
        for (i = 0; i < 256; i = i + 1) begin
            if (coeff_out[i*12 +: 12] !== expected[i]) begin
                if (errors < 10)
                    $display(
                        "Mismatch at [%0d]: got %0d, expected %0d",
                        i, coeff_out[i*12 +: 12], expected[i]
                    );
                errors = errors + 1;
            end
        end

        if (errors == 0) begin
            $display("PASS: All 256 outputs match the Python golden vector.");
            $display("PASS: Deterministic-random NTT test.");
            $display("Cycles waited: %0d", cycles);
            $finish;
        end else begin
            $display("FAIL: %0d output mismatches.", errors);
            $fatal(1);
        end
    end

endmodule
"""

testbench = testbench.replace(
    "INPUT_ARRAY",
    verilog_array("input_values", inputs)
).replace(
    "EXPECTED_ARRAY",
    verilog_array("expected", expected)
)

output = root / "stress_vectors" / "deterministic_random_testbench.sv"
output.write_text(testbench, encoding="utf-8")
print(f"Generated: {output}")
print(f"Input coefficients: {len(inputs)}")
print(f"Expected coefficients: {len(expected)}")
print(f"First 8 expected outputs: {expected[:8]}")
