
from pathlib import Path

root = Path(__file__).resolve().parent.parent
golden_path = Path(__file__).resolve().parent / "expected_ntt_sequential.txt"
output_path = root / "software" / "expected_ntt_verilog.txt"

values = [int(x) for x in golden_path.read_text(encoding="utf-8").split()]

if len(values) != 256:
    raise SystemExit(f"Expected 256 coefficients, got {len(values)}")

if any(x < 0 or x >= 3329 for x in values):
    raise SystemExit("Invalid coefficient found")

lines = [
    f"        expected[{i}] = 12'd{value};"
    for i, value in enumerate(values)
]

output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

print("PASS: Generated Verilog expected-value assignments.")
print("Assignments:", len(values))
print("Saved to:", output_path)
print()
print("Preview:")
print("\n".join(lines[:8]))
