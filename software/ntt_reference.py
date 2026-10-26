
# ML-KEM forward NTT reference
# Based on NIST FIPS 203, Algorithm 9

Q = 3329
N = 256
ZETA = 17


def bit_reverse7(value):
    """Reverse the seven bits of a number."""
    result = 0

    for _ in range(7):
        result = (result << 1) | (value & 1)
        value >>= 1

    return result


def generate_twiddle_factors():
    """Generate the 127 twiddle factors in ML-KEM order."""
    return [
        pow(ZETA, bit_reverse7(i), Q)
        for i in range(1, 128)
    ]


def ntt_forward(coefficients):
    """Compute the ML-KEM forward NTT of 256 coefficients."""
    if len(coefficients) != N:
        raise ValueError("NTT requires exactly 256 coefficients")

    f = [x % Q for x in coefficients]
    twiddles = generate_twiddle_factors()
    k = 0
    length = 128

    while length >= 2:
        for start in range(0, N, 2 * length):
            zeta = twiddles[k]
            k += 1

            for j in range(start, start + length):
                t = (zeta * f[j + length]) % Q

                f[j + length] = (f[j] - t) % Q
                f[j] = (f[j] + t) % Q

        length //= 2

    return f


if __name__ == "__main__":
    print("Testing ML-KEM forward NTT")

    zero_input = [0] * N
    zero_output = ntt_forward(zero_input)

    assert zero_output == [0] * N
    print("Test 1 passed: zero polynomial")

    impulse_input = [1] + [0] * (N - 1)
    impulse_output = ntt_forward(impulse_input)

    assert impulse_output == [1, 0] * (N // 2)
    print("Test 2 passed: impulse polynomial")

    sample_input = list(range(N))
    sample_output = ntt_forward(sample_input)

    assert len(sample_output) == N
    assert all(0 <= x < Q for x in sample_output)

    print("Test 3 passed: 256-coefficient input")
    print("First 8 output coefficients:", sample_output[:8])
    print("Number of output coefficients:", len(sample_output))
    print("All outputs are in the range 0 to", Q - 1)
    print("All tests passed!")
