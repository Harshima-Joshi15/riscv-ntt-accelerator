
from pathlib import Path
import json
import random

from ntt_reference import ntt_forward, Q, N
from kyber_py.polynomials.polynomials import PolynomialRing


OUTPUT_DIR = Path(__file__).resolve().parent / "stress_vectors"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

ring = PolynomialRing()
rng = random.Random(20261026)


def reference_ntt(coefficients):
    """Compute the NTT and independently check it against kyber-py."""
    ours = ntt_forward(coefficients)
    expected = list(ring(coefficients.copy()).to_ntt().coeffs)

    if list(ours) != expected:
        raise RuntimeError("NTT reference disagrees with kyber-py")

    return [int(value) for value in expected]


vectors = {
    "all_zero": [0] * N,
    "single_nonzero": [0] * N,
    "near_modulus": [Q - 1 if i % 2 == 0 else Q - 2 for i in range(N)],
    "deterministic_random": [rng.randrange(Q) for _ in range(N)],
}

vectors["single_nonzero"][0] = 1

for name, coefficients in vectors.items():
    if len(coefficients) != N:
        raise RuntimeError(f"{name}: incorrect vector length")

    if any(value < 0 or value >= Q for value in coefficients):
        raise RuntimeError(f"{name}: coefficient outside [0, {Q - 1}]")

    expected = reference_ntt(coefficients)

    result = {
        "name": name,
        "q": Q,
        "n": N,
        "input": coefficients,
        "expected": expected,
    }

    output_file = OUTPUT_DIR / f"{name}.json"
    output_file.write_text(
        json.dumps(result, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"PASS: {name}")
    print(f"  Input coefficients:  {len(coefficients)}")
    print(f"  Expected coefficients: {len(expected)}")
    print(f"  First 8 outputs: {expected[:8]}")
    print(f"  Saved: {output_file}")

print("\nAll stress vectors generated and reference-checked.")
