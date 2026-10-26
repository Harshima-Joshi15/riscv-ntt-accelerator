
from pathlib import Path
import json

BASE_DIR = Path(__file__).resolve().parent
VECTOR_DIR = BASE_DIR / "stress_vectors"
OUTPUT_DIR = VECTOR_DIR / "verilog"

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

for json_file in sorted(VECTOR_DIR.glob("*.json")):
    data = json.loads(json_file.read_text(encoding="utf-8"))

    name = data["name"]
    inputs = data["input"]
    expected = data["expected"]
    q = data["q"]
    n = data["n"]

    if len(inputs) != n or len(expected) != n:
        raise ValueError(f"{name}: expected exactly {n} input and output values")

    if any(not isinstance(x, int) or not 0 <= x < q for x in inputs):
        raise ValueError(f"{name}: invalid input coefficient")

    if any(not isinstance(x, int) or not 0 <= x < q for x in expected):
        raise ValueError(f"{name}: invalid expected coefficient")

    input_file = OUTPUT_DIR / f"{name}_input.mem"
    expected_file = OUTPUT_DIR / f"{name}_expected.mem"

    input_file.write_text(
        "".join(f"{x:03x}\n" for x in inputs),
        encoding="ascii",
    )

    expected_file.write_text(
        "".join(f"{x:03x}\n" for x in expected),
        encoding="ascii",
    )

    print(f"PASS: {name}")
    print(f"  Input file:    {input_file.name}")
    print(f"  Expected file: {expected_file.name}")
    print(f"  Coefficients:  {n}")

print("\nVerilog memory files exported successfully.")
