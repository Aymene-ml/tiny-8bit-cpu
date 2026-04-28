# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer


def _cpu(dut):
    try:
        return dut.user_project.u_cpu_top
    except AttributeError:
        try:
            return dut.user_project
        except AttributeError:
            return dut


async def settle():
    await Timer(5, unit="ns")


async def reset_dut(dut):
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 4)
    dut.rst_n.value = 1
    await settle()


async def wait_for_fetch_phase(dut):
    while fetch_from_debug(dut) != 1:
        await RisingEdge(dut.clk)
        await settle()


async def wait_for_exec_phase(dut):
    while fetch_from_debug(dut) != 0:
        await RisingEdge(dut.clk)
        await settle()


async def run_instr(dut, instr):
    # Align to fetch so instr_i is latched into IR before its execute phase.
    await wait_for_fetch_phase(dut)
    dut.ui_in.value = instr
    await settle()
    await RisingEdge(dut.clk)  # fetch edge: IR <= ui_in
    await settle()
    await RisingEdge(dut.clk)  # exec edge: instruction executes
    await settle()


async def enter_exec_with_instr(dut, instr):
    # Load instr on a fetch edge, then wait until the FSM is in execute.
    await wait_for_fetch_phase(dut)
    dut.ui_in.value = instr
    await settle()
    await RisingEdge(dut.clk)
    await wait_for_exec_phase(dut)
    await settle()


async def enter_exec_with_opcode(dut, instr, expected_opcode):
    # Robustly align to EXEC for the intended instruction decode.
    await wait_for_fetch_phase(dut)
    dut.ui_in.value = instr
    await settle()
    for _ in range(6):
        await RisingEdge(dut.clk)
        await settle()
        cpu = _cpu(dut)
        if fetch_from_debug(dut) == 0 and hasattr(cpu, "opcode") and int(cpu.opcode.value) == expected_opcode:
            return
    raise AssertionError("Failed to reach EXEC with expected opcode")


def pc_from_debug(dut):
    return int(dut.uio_out.value) & 0x0F


def fetch_from_debug(dut):
    return (int(dut.uio_out.value) >> 7) & 0x1


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start top-level ISA test")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    await reset_dut(dut)

    dut._log.info("Test simple external-instruction CPU")

    # LDI r1, #1 -> r1 = 1
    await run_instr(dut, 0x05)
    await settle()
    assert int(dut.uo_out.value) == 1

    # LDI r2, #2 -> r2 = 2
    await run_instr(dut, 0x0A)
    await settle()
    assert int(dut.uo_out.value) == 2

    # ADD r1, r2 -> r1 = 3
    await run_instr(dut, 0x16)
    await settle()
    assert int(dut.uo_out.value) == 3

    # SUB r1, r2 -> r1 = 1
    await run_instr(dut, 0x26)
    await settle()
    assert int(dut.uo_out.value) == 1

    # XOR r1, r2 -> r1 = 3 ^ 2 = 1? Actually after SUB r1 is 1 and r2 is 2, so XOR = 3.
    await run_instr(dut, 0x86)
    await settle()
    assert int(dut.uo_out.value) == 3

    # STO r1 -> RAM[r2] = 3 (rd value is unchanged by store)
    await run_instr(dut, 0x36)
    await settle()
    assert int(dut.uo_out.value) == 3

    # LDM r1 -> RAM[r2] = 3
    await run_instr(dut, 0x46)
    await settle()
    assert int(dut.uo_out.value) == 3

    # Create zero then verify conditional jump modifies PC nibble on debug bus.
    await run_instr(dut, 0x25)  # SUB r1, r1 -> 0
    await settle()
    assert int(dut.uo_out.value) == 0

    await run_instr(dut, 0x5A)  # JMPZ A
    await settle()
    assert (int(dut.uio_out.value) & 0x0F) == 0x0A

    # Make the zero flag false again and test JMPNZ.
    await run_instr(dut, 0x05)  # LDI r1, #1
    await run_instr(dut, 0xBA)  # JMPNZ A
    await settle()
    assert (int(dut.uio_out.value) & 0x0F) == 0x0A

    # MOV r3, r1 -> r3 becomes 1.
    await run_instr(dut, 0xCD)
    await settle()
    assert int(dut.uo_out.value) == 1

    # INC r3 -> 2.
    await run_instr(dut, 0xDC)
    await settle()
    assert int(dut.uo_out.value) == 2

    # DEC r3 -> 1.
    await run_instr(dut, 0xEC)
    await settle()
    assert int(dut.uo_out.value) == 1

    # NOP does not write; with operand 0 it exposes r0 on uo_out.
    await run_instr(dut, 0xF0)
    await settle()
    assert int(dut.uo_out.value) == 0


@cocotb.test()
async def test_reset_and_phase_toggling(dut):
    """Critical block test: control_fsm phase behavior and reset defaults."""
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    # Reset defaults through top-level observability.
    await settle()
    assert int(dut.uo_out.value) == 0
    assert pc_from_debug(dut) == 0

    # Fetch flag should toggle each cycle in steady state.
    first = fetch_from_debug(dut)
    await RisingEdge(dut.clk)
    await settle()
    second = fetch_from_debug(dut)
    await RisingEdge(dut.clk)
    await settle()
    third = fetch_from_debug(dut)

    assert second != first
    assert third == first


@cocotb.test()
async def test_control_decode_signals(dut):
    """Critical block test: verify control_unit decode outputs in EXEC phase."""
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)
    cpu = _cpu(dut)

    if not hasattr(cpu, "acc_we"):
        dut._log.warning("Skipping internal decode assertions in GLS: internal control signals are not exposed")
        return

    # LDI: latch IR in fetch, then verify EXEC decode signals.
    await enter_exec_with_opcode(dut, 0x07, 0x0)
    assert int(cpu.acc_we.value) == 1
    assert int(cpu.acc_src_sel.value) == 0b00

    # STO: expect data memory write enable.
    await enter_exec_with_opcode(dut, 0x31, 0x3)
    assert int(cpu.data_we.value) == 1

    # SUB: expect ALU subtract mode (alu_op=1) with register write.
    await enter_exec_with_opcode(dut, 0x21, 0x2)
    assert int(cpu.acc_we.value) == 1
    assert int(cpu.alu_op.value) == 1  # ALU_OP_SUB = 0x1


@cocotb.test()
async def test_leaf_modules_simple(dut):
    """Simple leaf checks via integration: ALU, memory, and register write-gating."""
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    # ALU add path check: r1 should become 3.
    await run_instr(dut, 0x05)  # LDI r1, #1
    await run_instr(dut, 0x0A)  # LDI r2, #2
    await run_instr(dut, 0x16)  # ADD r1, r2 -> 3
    await settle()
    assert int(dut.uo_out.value) == 3

    # ALU sub path check: r1 should return to 1.
    await run_instr(dut, 0x26)  # SUB r1, r2 -> 1
    await settle()
    assert int(dut.uo_out.value) == 1

    # Memory read path check.
    await run_instr(dut, 0x36)  # STO r1 -> RAM[r2]
    await run_instr(dut, 0x46)  # LDM r1 -> RAM[r2]
    await settle()
    assert int(dut.uo_out.value) == 1

    # Register write gating via ena=0: state/output should hold.
    dut.ena.value = 0
    hold_acc = int(dut.uo_out.value)
    hold_pc = pc_from_debug(dut)
    await ClockCycles(dut.clk, 4)
    await settle()
    assert int(dut.uo_out.value) == hold_acc
    assert pc_from_debug(dut) == hold_pc
