# DE2 Test Wrapper

This directory contains a temporary DE2-only wrapper for bring-up and pre-fabrication testing. It allows full validation of the 8-bit CPU on actual DE2 hardware before submitting the design to Tiny Tapeout fabrication.

## Quick Start

1. **Program the FPGA:** Load `de2_cpu_test_top.v` into the DE2 using Quartus and a USB Blaster
2. **Reset:** Press `KEY[0]` (active-low)
3. **Enable:** Set `SW[17] = 1`
4. **Observe:** Watch the 7-segment displays (HEX0–HEX1 show the current register value)
5. **Test:** Follow the checklist in `TEST_CHECKLIST.md`

## Board Inputs

- `CLOCK_50` – System clock (50 MHz)
- `KEY[0]` – Active-low reset
- `SW[17]` – CPU enable (set high to run, low to stall)
- `SW[16:0]` – Unused (can be used for future expansion)

## Board Outputs

- `LEDR[7:0]` – Current destination register value (rd output from CPU)
- `LEDR[12:8]` – Program counter (PC) debug value (5 bits, wraps at 32)
- `LEDR[13]` – Fetch phase indicator (HIGH when fetching a new instruction)
- `LEDR[14]` – Carry flag (HIGH if last ALU operation set carry)
- `LEDR[15]` – Zero flag (HIGH if last ALU operation result was zero)
- `LEDR[17:16]` – Unused
- `HEX0` & `HEX1` – Current register value in hexadecimal (low and high nibble)
- `HEX2` & `HEX3` – Program counter in hexadecimal
- `HEX4–HEX7` – Unused (all segments off)

## Testing Documentation

### For Testers

- **[TEST_CHECKLIST.md](TEST_CHECKLIST.md)** – Comprehensive testing procedure with 10 test scenarios
  - Basic instruction execution
  - Carry flag detection
  - Zero flag detection
  - Conditional branching (JMPZ)
  - Negative branching (loops)
  - Register file operations
  - Fetch phase timing
  - Reset behavior
  - Enable/disable control
  - Clock behavior

- **[ROM_PROGRAMS.md](ROM_PROGRAMS.md)** – 8 complete test programs ready to use
  - Program 1: Basic Arithmetic Test
  - Program 2: Carry Flag Test
  - Program 3: Zero Flag Test
  - Program 4: Conditional Branch Test (JMPZ with Skip)
  - Program 5: Negative Branch (Loop Test)
  - Program 6: All ALU Operations
  - Program 7: Register File Full Test
  - Program 8: Reset and Re-execution

Each program includes:
- Expected output sequences
- Instructions for setup
- Checklist items to verify
- Troubleshooting tips

## How to Load a Test Program

1. Open `de2_cpu_test_top.v` in Quartus or your Verilog editor
2. Navigate to the `program_rom()` function at the end of the file
3. Replace the current case statement with one from `ROM_PROGRAMS.md`
4. Recompile and reprogram the DE2
5. Follow the expected output sequence in the test program documentation

## Wrapper Architecture

```
┌─────────────────────────────┐
│   de2_cpu_test_top          │
├─────────────────────────────┤
│  program_rom(pc_dbg)        │  ← Instruction ROM
│         ↓                   │
│    [cpu_top]                │  ← 8-bit CPU core
│  ├─ control_fsm             │
│  ├─ control_unit            │
│  ├─ datapath                │
│  │  ├─ registers.v          │
│  │  ├─ alu.v                │
│  │  └─ memory.v             │
│  └─ ...                     │
│         ↓↓↓↓↓↓↓↓            │
│  LED/HEX display mapping    │
└─────────────────────────────┘
```

The wrapper:
- Supplies instructions from an on-wrapper ROM (indexed by PC[4:0])
- Fetches during the CPU's fetch_phase signal
- Routes CPU outputs to LEDR and HEX displays for observation
- Allows manual control via KEY and SW switches

## Important Notes

- **This wrapper is temporary** and not part of the Tiny Tapeout submission
- The ROM is limited to 32 instructions (5-bit PC)
- Remove this directory after successful DE2 testing
- The core CPU design in `src/` and the Tiny Tapeout wrapper `tt_um_aymen_accu8.v` remain unchanged
- Do not submit this file to Tiny Tapeout

## Debugging Tips

If something doesn't work as expected:

1. **HEX displays frozen?**
   - Check `SW[17] = 1` (CPU enable)
   - Verify `KEY[0]` is released (not held low)

2. **LEDs all off?**
   - Verify the FPGA is programmed (check Quartus status)
   - Confirm USB Blaster is connected

3. **Wrong instruction sequence?**
   - Double-check the ROM encoding in `ROM_PROGRAMS.md`
   - Verify the instruction set matches your opcode definitions

4. **Branch not working?**
   - Confirm the ZERO or CARRY flag is set before the branch instruction
   - Check the branch offset encoding (positive/negative)

5. **Reset not working?**
   - Verify `KEY[0]` is active-low (pressing should trigger reset)
   - Check pin assignment in Quartus

## Next Steps After Testing

Once all tests pass on DE2:
1. Document any issues or design changes
2. Update the Tiny Tapeout submission files if needed
3. Remove the `de2/` directory before final submission
4. Keep a copy in a separate `de2-tests/` branch for future reference
