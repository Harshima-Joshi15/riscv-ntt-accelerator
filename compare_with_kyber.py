
from ntt_reference import ntt_forward, Q, N
from kyber_py.polynomials.polynomials import PolynomialRing

ring = PolynomialRing()


def check_case(name, coefficients):
    # Your implementation
    ours = ntt_forward(coefficients)

    # Independent kyber-py implementation
    reference = ring(coefficients).to_ntt().coeffs

    if ours == reference:
        print(f"PASS: {name}")
        return True

    for i, (a, b) in enumerate(zip(ours, reference)):
        if a != b:
            print(f"FAIL: {name}")
            print(f"First mismatch at index {i}")
            print(f"Your result: {a}")
            print(f"kyber-py:    {b}")
            return False

    print(f"FAIL: {name} (output lengths differ)")
    return False


if __name__ == "__main__":
    cases = [
        ("Zero input", [0] * N),
        ("Impulse input", [1] + [0] * (N - 1)),
        ("Sequential input", list(range(N))),
        ("Maximum residues", [Q - 1] * N),
        ("Negative coefficients", [-i for i in range(N)]),
        ("Mixed coefficients", [(i * 37 + 123) % Q for i in range(N)]),
    ]

    results = [check_case(name, data) for name, data in cases]

    print(f"\nResults: {sum(results)}/{len(results)} cases passed.")

    if not all(results):
        raise SystemExit("Comparison failed.")

    print("All comparisons with kyber-py passed.")
