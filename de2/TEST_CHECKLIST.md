# DE2 CPU Test Checklist

This document provides a comprehensive testing procedure for the 8-bit accumulator CPU on the DE2 board.

## Pre-Test Setup

- [ ] Program the DE2 board with `de2_cpu_test_top.v` using Quartus and a USB Blaster
- [ ] Connect power and USB Blaster to the DE2
- [ ] Press `KEY[0]` to reset the design
- [ ] Set `SW[17]` to 1 to enable the CPU
- [ ] Observe the 7-segment displays and LEDs

## Test 1: Basic Instruction Execution

**Program:** `test_program_basic` (see ROM_PROGRAMS.md)

**Procedure:**
1. Load the basic instruction test program into the ROM
2. Set `SW[17] = 1` and press `KEY[0]` to reset
3. Clock the device and observe the 7-segment HEX displays

**Expected Output Sequence:**
- HEX0–HEX1 should show: `01` → `02` → `03` → `01` → `00`
  - 0x01 = LDI r1, #1
  - 0x02 = LDI r2, #2
  - 0x03 = ADD r1, r2 (result: 3)
  - 0x01 = SUB r1, r2 (result: 1)
  - 0x00 = SUB r1, r1 (result: 0, sets zero flag)

**Checklist:**
- [ ] HEX displays update on each clock cycle (at fetch phase)
- [ ] Results match the expected sequence
- [ ] LED outputs are consistent with register values

---

## Test 2: Carry Flag Detection

**Program:** `test_program_carry` (see ROM_PROGRAMS.md)

**Procedure:**
1. Load the carry flag test program
2. Observe `LEDR[14]` (carry flag indicator)

**Expected Output Sequence:**
- Instruction 0: LDI r1, #0xFF (255)
- Instruction 1: LDI r2, #0x02 (2)
- Instruction 2: ADD r1, r2 (result: 0x01 with carry set)
- Instruction 3: NOP
- Check that `LEDR[14]` is HIGH after instruction 2

**Checklist:**
- [ ] Carry flag is 0 after LDI instructions
- [ ] Carry flag becomes 1 after ADD that overflows
- [ ] Carry flag is latched and visible on LED
- [ ] HEX displays show the wrapped result (0x01)

---

## Test 3: Zero Flag Detection

**Program:** `test_program_zero` (see ROM_PROGRAMS.md)

**Procedure:**
1. Load the zero flag test program
2. Observe `LEDR[15]` (zero flag indicator)

**Expected Output Sequence:**
- Instruction 0: LDI r1, #0x05 (5)
- Instruction 1: SUB r1, r1 (result: 0, sets zero flag)
- Instruction 2: NOP
- Check that `LEDR[15]` is HIGH after instruction 1

**Checklist:**
- [ ] Zero flag is 0 after LDI instructions
- [ ] Zero flag becomes 1 after SUB r1, r1 (0 - 0 = 0)
- [ ] Zero flag remains visible on LED for next cycle
- [ ] HEX displays show 0x00

---

## Test 4: Conditional Branching (JMPZ)

**Program:** `test_program_jmpz` (see ROM_PROGRAMS.md)

**Procedure:**
1. Load the conditional branch test program
2. Observe `LEDR[12:8]` (PC debug value)
3. Set `SW[17] = 1` to enable the CPU

**Expected Behavior:**
- PC sequences: 0 → 1 → 2 → 3 → 4 → 5 (JMPZ detects zero flag from SUB)
- Instead of incrementing to 6, PC jumps to 6+2=8 (branch offset +2)
- Continue from address 8 onward

**Checklist:**
- [ ] PC increments normally during non-branch instructions
- [ ] JMPZ correctly skips instructions when zero flag is set
- [ ] JMPZ respects positive branch offsets
- [ ] PC counter wraps correctly at address 31 (5-bit counter)

---

## Test 5: Negative Branching

**Program:** `test_program_negative_branch` (see ROM_PROGRAMS.md)

**Procedure:**
1. Load the negative branch test program
2. Observe PC progression and branch behavior
3. Watch for loops returning to earlier addresses

**Expected Behavior:**
- After setting zero flag at an early instruction, branch back with negative offset
- PC should jump to an earlier instruction (e.g., from address 8, branch with offset -8 lands at address 1)

**Checklist:**
- [ ] Negative branch offsets work correctly
- [ ] PC wraps around when jumping backward (uses modulo 32 arithmetic)
- [ ] Loop exits when appropriate condition is met

---

## Test 6: Register File Operations

**Program:** `test_program_registers` (see ROM_PROGRAMS.md)

**Procedure:**
1. Load the register test program
2. Execute LDI and arithmetic operations
3. Verify register contents via LED display

**Expected Behavior:**
- Each LDI instruction writes a unique pattern to r0–r7
- Arithmetic operations combine register values
- Results are visible on `LEDR[7:0]`

**Checklist:**
- [ ] All 8 registers can be written
- [ ] LDI correctly loads immediate values (1, 2, 4, 8, etc.)
- [ ] Arithmetic reads from r1 and r2 correctly
- [ ] Results show in HEX displays and LEDs

---

## Test 7: Fetch Phase Timing

**Program:** Any program

**Procedure:**
1. Observe `LEDR[13]` (fetch phase indicator)
2. Watch the timing relationship between fetch phase and PC changes

**Expected Behavior:**
- Fetch phase pulses HIGH once per cycle when enabled
- New instruction is fetched during fetch phase
- PC updates on the clock edge after fetch phase

**Checklist:**
- [ ] Fetch phase is visible as LED pulses
- [ ] HEX displays update when fetch phase is active
- [ ] CPU stalls when `SW[17] = 0` (fetch phase stays low, PC doesn't change)

---

## Test 8: Reset Behavior

**Procedure:**
1. Start with any running program
2. Press `KEY[0]` (active-low reset)
3. Observe system state

**Expected Behavior:**
- PC resets to 0
- All registers reset to 0
- Carry and zero flags reset to 0
- Program restarts from address 0

**Checklist:**
- [ ] `LEDR[12:8]` returns to 0x00 (PC at 0)
- [ ] `LEDR[7:0]` returns to 0x00 (rd at 0)
- [ ] `LEDR[14:15]` return to 0 (flags cleared)
- [ ] CPU restarts execution from address 0

---

## Test 9: Enable/Disable (SW[17])

**Procedure:**
1. Start a running program
2. Toggle `SW[17]` between 0 and 1
3. Observe fetch phase and PC behavior

**Expected Behavior:**
- When `SW[17] = 1`: Fetch phase pulses, PC advances, instructions execute
- When `SW[17] = 0`: Fetch phase stays low, PC frozen, no new instruction fetches

**Checklist:**
- [ ] Setting `SW[17] = 0` stops the CPU (LED[13] goes low)
- [ ] PC freezes when CPU is disabled
- [ ] Setting `SW[17] = 1` resumes execution from the stopped address
- [ ] HEX displays freeze when CPU is disabled

---

## Test 10: Clock Behavior

**Procedure:**
1. Run a program with `SW[17] = 1`
2. Vary the clock speed (if available via frequency selection)
3. Observe execution rate changes

**Expected Behavior:**
- Higher clock frequency = faster instruction execution
- All logic operates correctly at different clock speeds

**Checklist:**
- [ ] CPU executes at 50 MHz with stable results
- [ ] No metastability or timing violations observed
- [ ] Results are consistent across multiple runs

---

## Debugging Tips

- **HEX displays frozen?** Check that `SW[17] = 1` and `KEY[0]` is released (not held low).
- **LEDs all off?** Verify the USB Blaster is connected and the FPGA is properly programmed.
- **Unexpected PC values?** Confirm the program counter is 5-bit (wraps at 32).
- **Wrong arithmetic results?** Check the ALU operation encoding in the instruction ROM.
- **Branch not working?** Verify the zero/carry flag is set before the branch instruction.

---

## Notes

- This checklist assumes the ROM program is correctly loaded and the DE2 board is properly powered.
- All timing is relative to `CLOCK_50` (50 MHz).
- The 5-bit PC wraps from 31 → 0 on increment.
- Conditional branches use the latched carry or zero flag from the previous instruction's writeback.
