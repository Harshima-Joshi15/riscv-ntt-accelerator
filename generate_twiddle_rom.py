
from pathlib import Path

Q = 3329
ZETA = 17


def bit_reverse7(value):
    result = 0
    for _ in range(7):
        result = (result << 1) | (value & 1)
        value >>= 1
    return result


output_path = Path("rtl/ntt_twiddle_rom.v")

lines = [
    "`timescale 1ns/1ps",
    "",
    "module ntt_twiddle_rom (",
    "    input wire [6:0] addr,",
    "    output reg [11:0] zeta",
    ");",
    "",
    "    always @(*) begin",
    "        case (addr)",
    "            7'd0: zeta = 12'd0;"
]

for address in range(1, 128):
    value = pow(ZETA, bit_reverse7(address), Q)
    lines.append(
        f"            7'd{address}: zeta = 12'd{value};"
    )

lines.extend([
    "            default: zeta = 12'd0;",
    "        endcase",
    "    end",
    "",
    "endmodule",
    ""
])

output_path.parent.mkdir(parents=True, exist_ok=True)
output_path.write_text("\n".join(lines), encoding="utf-8")

print(f"Generated: {output_path.resolve()}")
print("Twiddle entries generated: 127")
