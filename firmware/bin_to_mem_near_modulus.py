import struct
from pathlib import Path

binary = Path("firmware/firmware_near_modulus.bin").read_bytes()

if len(binary) % 4 != 0:
    binary += b"\x00" * (4 - len(binary) % 4)

words = [
    struct.unpack("<I", binary[i:i+4])[0]
    for i in range(0, len(binary), 4)
]

output = Path("firmware/firmware_near_modulus.hex")
output.write_text("".join(f"{word:08x}\n" for word in words))

print(f"PASS: Generated {len(words)} instruction words")
print(f"First 8 words: {words[:8]}")