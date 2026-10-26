# RISC-V Integrated Hardware Accelerator for NTT-Based Post-Quantum Cryptography

## Overview

This project integrates a Number Theoretic Transform (NTT) hardware accelerator with a PicoRV32 RISC-V processor through a memory-mapped register interface. A Python reference implementation generates golden output vectors for functional verification.

The design uses modular arithmetic over the modulus q = 3329 and processes 256 coefficients.

## Architecture

1. **RISC-V processor:** PicoRV32 executes instructions to configure and control the accelerator.
2. **MMIO interface:** Provides control, status, input-coefficient, and output-coefficient registers.
3. **NTT engine:** Performs the 256-coefficient transform using a staged butterfly datapath.
4. **Python reference:** Generates expected outputs for comparison with RTL simulation.
5. **Testbenches:** Verify arithmetic modules, NTT operation, and processor/accelerator integration.

## Register Map

| Register | Offset | Description |
|---|---:|---|
| CONTROL | `0x000` | Write bit 0 to start when idle |
| STATUS | `0x004` | Bit 0: busy; bit 1: sticky done |
| Input coefficients | `0x100`–`0x4FC` | 256 32-bit-spaced coefficient registers |
| Output coefficients | `0x500`–`0x8FC` | 256 32-bit-spaced output registers |

The CPU-side MMIO region used in the integration test begins at `0x1000`.

## Repository Structure

- `rtl/` — Verilog hardware modules and accelerator logic
- `software/` — Python NTT reference, golden-vector generation, and verification utilities
- `testbench/` — RTL testbenches
- `results/` — Reserved for saved verification outputs
- `.gitignore` — Excludes common temporary and generated files

## Verification

The following simulations have passed in EDA Playground using Icarus Verilog:

- All-zero input vector: all 256 outputs matched.
- Single-nonzero input vector: all 256 outputs matched.
- Near-modulus input vector: all 256 outputs matched.
- Deterministic-random input vector: all 256 outputs matched.
- MMIO-to-NTT regression: all 256 output coefficients matched the Python golden vector.
- PicoRV32 integration tests: previously passed input writes, status polling, output readback, and RAM verification.

The MMIO-to-NTT regression reported zero output mismatches. The PicoRV32 simulation emitted non-fatal sensitivity warnings concerning its internal register array.

## Running Simulations

The RTL was tested using EDA Playground with Icarus Verilog. A typical compile/run command is:

```bash
iverilog -Wall -g2012 design.sv picorv32.v testbench.sv
vvp a.out
```

For the EDA Playground setup, `design.sv` contains the project RTL, `picorv32.v` contains the PicoRV32 source, and `testbench.sv` contains the selected testbench.

Python reference and vector-generation scripts are located in `software/`. Run them from the project root using Python, following any dependencies documented by the scripts.

## Scope and Limitations

This repository documents an RTL and simulation project. Passing functional tests does not by itself establish synthesis timing, area, power, physical FPGA implementation, or full compliance with the ML-KEM specification. Those require separate verification and implementation steps.

## License

License to be selected by the project author.
