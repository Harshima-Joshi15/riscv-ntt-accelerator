
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ntt_reference import ntt_forward, Q, N
from kyber_py.polynomials.polynomials import PolynomialRing

input_coeffs = list(range(N))
ours = ntt_forward(input_coeffs)
expected = list(PolynomialRing()(input_coeffs).to_ntt().coeffs)

if ours != expected:
    raise SystemExit("FAIL: NTT output differs from kyber-py!")

output_path = Path(__file__).resolve().parent / "expected_ntt_sequential.txt"
output_path.write_text(
    " ".join(map(str, expected)) + "\n",
    encoding="utf-8"
)

print("PASS: Python output matches kyber-py.")
print("Coefficient count:", len(expected))
print("First 16 coefficients:", expected[:16])
print("All coefficients in range:", all(0 <= x < Q for x in expected))
print("Golden vector saved:", output_path)
