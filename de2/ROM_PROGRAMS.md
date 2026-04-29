# DE2 CPU Test Programs

This document provides complete test programs (ROM contents) that can be loaded into the DE2 wrapper for different testing scenarios. Each program maps directly to a test in **TEST_CHECKLIST.md**.

## ⚠️ Critical: PC Addressing for Branches

**The CPU uses PC-relative addressing where the offset is calculated from the NEXT instruction address (after increment during fetch phase), NOT the branch instruction's address.**

**Key Formula:** 
```
Target Address = (Branch Instruction Address + 1) + Offset
```

**Example:**
- JMPZ instruction at address 3
- During fetch: PC increments to 4  
- During execute: Branch target = 4 + offset (not 3 + offset)
- If offset = +1, target = 5 (not 4)
- If offset = -3, target = 1 (not 0)

This is why the test programs use specific offset values—they account for the PC increment that happens during the fetch phase.

## Quick Reference

| Test | Program Name | Checklist | Purpose |
|------|--------------|-----------|---------|
| 1 | `test_program_basic` | Test 1 | Basic instruction execution (LDI, ADD, SUB) |
| 2 | `test_program_carry` | Test 2 | Carry flag detection (overflow) |
| 3 | `test_program_zero` | Test 3 | Zero flag detection |
| 4 | `test_program_jmpz` | Test 4 | Conditional branching with forward skip |
| 5 | `test_program_negative_branch` | Test 5 | Negative branch (loops) |
| 6 | `test_program_registers` | Test 6 | Full register file test |
| 7 | `test_program_alu` | (Optional) | All ALU operations |
| 8 | `test_program_reset` | Test 8 | Reset behavior |

Each program is ready to copy into the `program_rom()` function in `de2_cpu_test_top.v`.

---

## test_program_basic

**Title:** Basic Arithmetic Test  
**Description:** Tests LDI, ADD, and SUB instructions. Verifies basic execution and register operations.
**Checklist:** Test 1 in TEST_CHECKLIST.md

**Duration:** 5 clock cycles  
**Complexity:** Beginner  
**Tests:** Instruction fetch, register write, basic ALU operations

**ROM Code:**
```verilog
function automatic [7:0] program_rom(input [4:0] addr);
  begin
    case (addr)
      5'd0:  program_rom = 8'h05;   // LDI r1, #1
      5'd1:  program_rom = 8'h0A;   // LDI r2, #2
      5'd2:  program_rom = 8'h16;   // ADD r1, r2 → result: 3 (0x03)
      5'd3:  program_rom = 8'h26;   // SUB r1, r2 → result: 1 (0x01)
      5'd4:  program_rom = 8'h25;   // SUB r1, r1 → result: 0 (0x00), sets ZERO
      default: program_rom = 8'hF0; // NOP
    endcase
  end
endfunction
```

**Expected Output:**
```
Clock | PC | Fetch | HEX0/HEX1 | LEDR[7:0] | LEDR[15] (ZERO) | LEDR[14] (CARRY)
  1   | 0  | Y     | 0x01      | 0x01      | 0               | 0
  2   | 1  | Y     | 0x02      | 0x02      | 0               | 0
  3   | 2  | Y     | 0x03      | 0x03      | 0               | 0
  4   | 3  | Y     | 0x01      | 0x01      | 0               | 0
  5   | 4  | Y     | 0x00      | 0x00      | 1               | 0
```

**Checklist for Tester:**
- [ ] HEX0/HEX1 displays show `01` → `02` → `03` → `01` → `00` in sequence
- [ ] Register values update after each instruction
- [ ] Zero flag (LED15) becomes HIGH after the last SUB
- [ ] PC increments by 1 each cycle

---

## test_program_carry

**Title:** Carry Flag Test  
**Description:** Tests arithmetic overflow. LDI loads max value, then ADD causes overflow.
**Checklist:** Test 2 in TEST_CHECKLIST.md

**Duration:** 4 clock cycles  
**Complexity:** Beginner  
**Tests:** Overflow detection, carry flag latching

**ROM Code:**
```verilog
function automatic [7:0] program_rom(input [4:0] addr);
  begin
    case (addr)
      5'd0:  program_rom = 8'hFE;   // LDI r7, #0xFF (255 decimal)
      5'd1:  program_rom = 8'h02;   // LDI r0, #2
      5'd2:  program_rom = 8'hEE;   // ADD r7, r0 → 255 + 2 = 257, wraps to 1 (0x01), sets CARRY
      5'd3:  program_rom = 8'hF0;   // NOP
      default: program_rom = 8'hF0; // NOP
    endcase
  end
endfunction
```

**Expected Output:**
```
Clock | PC | HEX0/HEX1 | LEDR[7:0] | LEDR[14] (CARRY)
  1   | 0  | 0xFF      | 0xFF      | 0
  2   | 1  | 0x02      | 0x02      | 0
  3   | 2  | 0x01      | 0x01      | 1
  4   | 3  | (NOP)     | 0x01      | 1
```

**Checklist for Tester:**
- [ ] After LDI r7, #0xFF, HEX shows `0xFF`
- [ ] After LDI r0, #2, HEX shows `0x02`
- [ ] After ADD, result wraps to `0x01`
- [ ] Carry flag (LED14) becomes HIGH and stays HIGH

---

## test_program_zero

**Title:** Zero Flag Test  
**Description:** Tests zero flag generation. Compares register to itself (result is always 0).
**Checklist:** Test 3 in TEST_CHECKLIST.md

**Duration:** 3 clock cycles  
**Complexity:** Beginner  
**Tests:** Zero flag detection, flag latching

**ROM Code:**
```verilog
function automatic [7:0] program_rom(input [4:0] addr);
  begin
    case (addr)
      5'd0:  program_rom = 8'h09;   // LDI r2, #1
      5'd1:  program_rom = 8'h22;   // SUB r2, r2 → 1 - 1 = 0, sets ZERO
      5'd2:  program_rom = 8'hF0;   // NOP
      default: program_rom = 8'hF0; // NOP
    endcase
  end
endfunction
```

**Expected Output:**
```
Clock | PC | HEX0/HEX1 | LEDR[15] (ZERO) | LEDR[7:0]
  1   | 0  | 0x01      | 0               | 0x01
  2   | 1  | 0x00      | 1               | 0x00
  3   | 2  | (NOP)     | 1               | 0x00
```

**Checklist for Tester:**
- [ ] After LDI, result shows `0x01` and ZERO is LOW
- [ ] After SUB r2, r2, result is `0x00` and ZERO flag is HIGH
- [ ] ZERO flag remains latched on subsequent cycles

---

## test_program_jmpz

**Title:** Conditional Branch Test (JMPZ with Skip)  
**Description:** Tests conditional branching. JMPZ skips an instruction when zero flag is set.
**Checklist:** Test 4 in TEST_CHECKLIST.md

**Duration:** 7 clock cycles  
**Complexity:** Intermediate  
**Tests:** Branch logic, PC computation, flag-based control flow

**⚠️ Important Note on PC Addressing:**
Branch offsets in this CPU are relative to the **next instruction's address** (after PC increment during fetch phase), NOT the branch instruction address itself.

**Formula:** `branch_target_address = (branch_instruction_address + 1) + offset`

**ROM Code:**
```verilog
function automatic [7:0] program_rom(input [4:0] addr);
  begin
    case (addr)
      5'd0:  program_rom = 8'h05;   // LDI r1, #1
      5'd1:  program_rom = 8'h0A;   // LDI r2, #2
      5'd2:  program_rom = 8'h25;   // SUB r1, r1 → result: 0, sets ZERO
      5'd3:  program_rom = 8'h51;   // JMPZ +1 (offset +1) → target = (3+1) + 1 = 5
      5'd4:  program_rom = 8'h0F;   // LDI r3, #7 (SKIPPED when branch works)
      5'd5:  program_rom = 8'h0E;   // LDI r3, #6 (executed after branch)
      5'd6:  program_rom = 8'hF0;   // NOP
      default: program_rom = 8'hF0; // NOP
    endcase
  end
endfunction
```

**Timing Explanation:**
```
Cycle 1 (Fetch phase):  PC=0, fetch instruction 0
Cycle 2 (Fetch phase):  PC=1, fetch instruction 1
Cycle 3 (Fetch phase):  PC=2, fetch instruction 2
Cycle 4 (Fetch phase):  PC=3, fetch instruction 3 (JMPZ +1)
                        During fetch: PC increments to 4
Cycle 5 (Execute):      pc_q = 4 (next instruction address)
                        ZERO flag is set, so branch taken
                        Branch target = 4 + (+1) = 5
                        Next fetch from address 5 (skips 4)
```

**Expected Output:**
```
Addr | HEX0/HEX1 | Opcode       | Note
  0  | 0x01      | LDI r1, #1   |
  1  | 0x02      | LDI r2, #2   |
  2  | 0x00      | SUB r1, r1   | Sets ZERO flag
  3  | (branch)  | JMPZ +1      | Jumps to 5
  5  | 0x06      | LDI r3, #6   | Instruction 4 skipped ✓
  6  | (NOP)     | NOP          |
```

**Checklist for Tester:**
- [ ] PC sequence is: 0 → 1 → 2 → 3 → 5 (skips 4)
- [ ] Instruction at address 4 (`0x0F`) does NOT execute
- [ ] Instruction at address 5 (`0x0E`) shows on HEX as `0x06`
- [ ] Branch is taken only when ZERO flag is latched

---

## test_program_negative_branch

**Title:** Negative Branch (Loop Test)  
**Description:** Tests negative branch offsets. Creates a small loop that counts down.
**Checklist:** Test 5 in TEST_CHECKLIST.md

**Duration:** 10+ clock cycles  
**Complexity:** Intermediate  
**Tests:** Negative branch offsets, 5-bit PC wrapping, loop control

**⚠️ Important Note on PC Addressing:**
Branch offsets are relative to the **next instruction address**, NOT the branch instruction address.

**Formula:** `branch_target = (branch_instruction_address + 1) + offset` (offset can be negative)

**ROM Code:**
```verilog
function automatic [7:0] program_rom(input [4:0] addr);
  begin
    case (addr)
      5'd0:  program_rom = 8'h06;   // LDI r1, #3
      5'd1:  program_rom = 8'h28;   // SUB r1, r0 → decrement (assuming r0=1)
      5'd2:  program_rom = 8'h29;   // SUB r2, r1 → check if still > 0
      5'd3:  program_rom = 8'h5D;   // JMPZ -3 (offset -3) → target = (3+1) + (-3) = 1
      5'd4:  program_rom = 8'hF0;   // NOP (exit loop point)
      default: program_rom = 8'hF0; // NOP
    endcase
  end
endfunction
```

**Timing Explanation:**
```
At address 3 (JMPZ -3 instruction):
  Fetch phase:   PC increments from 3 to 4
  Execute phase: pc_q = 4, offset = -3
  Branch target: 4 + (-3) = 1 (loops back to address 1)
```

**Expected Output:**
```
PC Sequence: 0 → 1 → 2 → 3 → 1 → 2 → 3 → 1 → 2 → 3 → ...

Each loop iteration:
  - Addr 1: SUB (decrement)
  - Addr 2: SUB (check if zero)
  - Addr 3: JMPZ (if ZERO not set, branch back to 1; if set, exit to 4)
```

**Checklist for Tester:**
- [ ] PC sequence shows loop: 0 → 1 → 2 → 3 → 1 (repeats)
- [ ] PC jumps backward from address 3 to address 1
- [ ] Negative branch offset (-3) correctly calculated as 4 + (-3) = 1
- [ ] Loop repeats until condition causes exit
- [ ] 5-bit PC math works correctly (no unexpected wrapping)

---test_program_alu

**Title:** All ALU Operations  
**Description:** Comprehensive test of all ALU operations: LDI, ADD, SUB, XOR, SHL (shift left), SHR (shift right).
**Note:** Optional advanced test (not in main checklist)

**Description:** Comprehensive test of all ALU operations: LDI, ADD, SUB, XOR, SHL (shift left), SHR (shift right).

**Duration:** 8+ clock cycles  
**Complexity:** Intermediate  
**Tests:** All instruction types, register interactions, flag generation

**ROM Code:**
```verilog
function automatic [7:0] program_rom(input [4:0] addr);
  begin
    case (addr)
      5'd0:  program_rom = 8'h0B;   // LDI r2, #3
      5'd1:  program_rom = 8'h0C;   // LDI r3, #4
      5'd2:  program_rom = 8'h23;   // ADD r2, r3 → 3 + 4 = 7
      5'd3:  program_rom = 8'h37;   // XOR r3, r7 → bitwise XOR
      5'd4:  program_rom = 8'h5B;   // SHL r2, r3 → shift left (7 << 4)
      5'd5:  program_rom = 8'h6B;   // SHR r2, r3 → shift right result
      5'd6:  program_rom = 8'hF0;   // NOP
      5'd7:  program_rom = 8'hF0;   // NOP
      default: program_rom = 8'hF0; // NOP
    endcase
  end
endfunction
```

**Expected Output:**
```
Clock | PC | Operation         | Expected Result | Flags
  1   | 0  | LDI r2, #3        | 0x03            | -
  2   | 1  | LDI r3, #4        | 0x04            | -
  3   | 2  | ADD r2, r3        | 0x07            | ZERO=0, CARRY=0
  4   | 3  | XOR r3, r7        | (XOR result)    | -
  5   | 4  | SHL r2, r3        | (7 << 4)        | Flags depend on result
  6   | 5  | SHR result        | (result >> 4)   | -
```

**Checklist for Tester:**
- [ ] All operations execute in sequence
- [ ] Results visible on HEX displays
- [ ] Shift operations work correctly
- [test_program_registers

**Title:** Register File Full Test  
**Description:** Loads all 8 registers with unique patterns and reads them back.
**Checklist:** Test 6 in TEST_CHECKLIST.md

## Program 7: Register File Full Test

**Description:** Loads all 8 registers with unique patterns and reads them back.

**Duration:** 16 clock cycles  
**Complexity:** Beginner  
**Tests:** All register access paths, register initialization

**ROM Code:**
```verilog
function automatic [7:0] program_rom(input [4:0] addr);
  begin
    case (addr)
      5'd0:  program_rom = 8'h01;   // LDI r0, #1
      5'd1:  program_rom = 8'h05;   // LDI r1, #1 (duplicate for test)
      5'd2:  program_rom = 8'h09;   // LDI r2, #1
      5'd3:  program_rom = 8'h0D;   // LDI r3, #1
      5'd4:  program_rom = 8'h11;   // LDI r4, #1
      5'd5:  program_rom = 8'h15;   // LDI r5, #1
      5'd6:  program_rom = 8'h19;   // LDI r6, #1
      5'd7:  program_rom = 8'h1D;   // LDI r7, #1
      5'd8:  program_rom = 8'hF0;   // NOP (end)
      default: program_rom = 8'hF0; // NOP
    endcase
  end
endfunction
```

**Expected Output:**
```
After LDI r0, #1: HEX shows 0x01
After LDI r1, #1: HEX shows 0x01
...
After LDI r7, #1: HEX shows 0x01
```

**Checklist for Tester:**
- [ ] All 8 registers can be addressed (r0–r7)
- [ ] Each register holds its value independently
- [ ] HEX displays update for each LDI operation
- [test_program_reset

**Title:** Reset and Re-execution  
**Description:** Simple program to test reset functionality. Run, reset, and verify it restarts.
**Checklist:** Test 8 in TEST_CHECKLIST.md

## Program 8: Reset and Re-execution

**Description:** Simple program to test reset functionality. Run, reset, and verify it restarts.

**Duration:** Continuous  
**Complexity:** Beginner  
**Tests:** Reset behavior, program restart

**ROM Code:**
```verilog
function automatic [7:0] program_rom(input [4:0] addr);
  begin
    case (addr)
      5'd0:  program_rom = 8'h0F;   // LDI r3, #7
      5'd1:  program_rom = 8'h1F;   // LDI r7, #15
      5'd2:  program_rom = 8'h3F;   // ADD r7, r7 → 15 + 15 = 30
      5'd3:  program_rom = 8'hF0;   // NOP (loop back to 0)
      default: program_rom = 8'hF0; // NOP
    endcase
  end
endfunction
```

**Procedure:**
1. Run the program until you see stable output (HEX shows 30, PC at 3)
2. Press `KEY[0]` to reset
3. Verify: PC returns to 0, HEX resets, flags clear
4. Program restarts automatically

**Checklist for Tester:**
- [ ] Before reset: PC = 3, HEX ≠ 0, flags may be set
- [ ] After reset: PC = 0, HEX = 0, flags = 0
- [ ] Program restarts and sequence repeats

---

## How to Use These Programs

1. **Choose a test program** based on the feature you want to validate
2. **Copy the ROM code** into `de2_cpu_test_top.v`
3. **Replace the `program_rom()` function** at the bottom of the file
4. **Recompile** with Quartus: `File → Compile Design`
5. **Program the DE2** and observe the outputs
6. **Compare results** to the expected output table
7. **Check off items** in the test checklist as you verify each feature

---

## Custom Program Template

To create your own test program, modify the `program_rom()` function:

```verilog
function automatic [7:0] program_rom(input [4:0] addr);
  begin
    case (addr)
      5'd0:  program_rom = 8'h??;   // Your instruction 0
      5'd1:  program_rom = 8'h??;   // Your instruction 1
      5'd2:  program_rom = 8'h??;   // Your instruction 2
      // ...
      5'd31: program_rom = 8'h??;   // Your instruction 31 (max)
      default: program_rom = 8'hF0; // NOP for unused addresses
    endcase
  end
endfunction
```

**Instruction Encoding Reference:**
- See `src/control_unit.v` for opcode definitions
- LDI (load immediate): `opcode[6:5] = 00`, `reg[4:3]`, `immed[2:0]`
- ADD/SUB/XOR: `opcode[6:5] = 01/10/11`, `rd[4:3]`, `rs[2:0]`
- Shift/Branch: Refer to instruction set documentation

---

## Troubleshooting

- **Program doesn't execute:** Check `SW[17] = 1` and `KEY[0]` is released
- **Output freezes:** CPU might be waiting for fetch phase; try toggling `SW[17]`
- **Unexpected results:** Verify instruction encoding matches the CPU's opcode table
- **Branch not taken:** Confirm the appropriate flag (ZERO or CARRY) is set before the branch instruction
