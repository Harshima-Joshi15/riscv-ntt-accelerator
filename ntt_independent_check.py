
import random

from ntt_reference import ntt_forward, Q, N

# Independent reference implementation
# Based on the ML-KEM NTT algorithm in FIPS 203.

def bitrev7(i):
    return int(f"{i:07b}"[::-1], 2)


ZETAS = [pow(17, bitrev7(i), Q) for i in range(128)]


def reference_ntt(coefficients):
    if len(coefficients) != N:
        raise ValueError("Expected exactly 256 coefficients")

    f = [x % Q for x in coefficients]
    k = 1
    length = 128

    while length >= 2:
        for start in range(0, N, 2 * length):
            zeta = ZETAS[k]
            k += 1

            for j in range(start, start + length):
                t = (zeta * f[j + length]) % Q
                f[j + length] = (f[j] - t) % Q
                f[j] = (f[j] + t) % Q

        length //= 2

    return f


def check_case(name, coefficients):
    expected = reference_ntt(coefficients)
    actual = ntt_forward(coefficients)

    if actual != expected:
        for i, (a, b) in enumerate(zip(actual, expected)):
            if a != b:
                print(f"FAILED: {name}")
                print(f"First mismatch at index {i}")
                print(f"Your output: {a}")
                print(f"Reference:   {b}")
                return False

        print(f"FAILED: {name} (output lengths differ)")
        return False

    print(f"PASSED: {name}")
    return True


if __name__ == "__main__":
    rng = random.Random(2026)

    cases = [
        ("All zeros", [0] * N),
        ("Impulse", [1] + [0] * (N - 1)),
        ("Sequential coefficients", list(range(N))),
        ("All coefficients Q-1", [Q - 1] * N),
        (
            "Deterministic random coefficients",
            [rng.randrange(Q) for _ in range(N)],
        ),
    ]

    results = [check_case(name, data) for name, data in cases]

    print(f"\nPassed {sum(results)} of {len(results)} comparisons.")

    if not all(results):
        raise SystemExit(1)

    print("Independent reference comparison successful.")
