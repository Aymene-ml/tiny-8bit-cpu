import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer, RisingEdge


@cocotb.test()
async def test_datapath_pc_and_register_paths(dut):
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # Allow clock to stabilize
    await Timer(1, unit="ns")

    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.instr_i.value = 0
    dut.reg_we_i.value = 0
    dut.pc_we_i.value = 0
    dut.ir_we_i.value = 0
    dut.data_we_i.value = 0
    dut.alu_op_i.value = 0  # ALU_OP_ADD
    dut.acc_src_sel_i.value = 0b11
    dut.pc_load_operand_i.value = 0
    await Timer(1, unit="ns")
    await ClockCycles(dut.clk, 3)  # Extra cycle for reset

    await Timer(1, unit="ns")
    assert int(dut.pc_o.value) == 0

    dut.rst_n.value = 1

    # LDI r1, #1.
    dut.instr_i.value = 0x05
    dut.ir_we_i.value = 1
    dut.pc_we_i.value = 1
    dut.pc_load_operand_i.value = 0
    await Timer(1, unit="ns")
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert int(dut.pc_o.value) == 1
    assert int(dut.operand_o.value) == 0x5

    # Immediate path should decode the destination register and opcode fields.
    dut.ir_we_i.value = 0
    dut.pc_we_i.value = 0
    dut.reg_we_i.value = 1
    await Timer(1, unit="ns")
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert int(dut.rd_idx_o.value) == 0x1
    assert int(dut.rs_idx_o.value) == 0x1

    # LDI r2, #2.
    dut.instr_i.value = 0x0A
    dut.reg_we_i.value = 0
    dut.ir_we_i.value = 1
    dut.pc_we_i.value = 1
    await Timer(1, unit="ns")
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")

    dut.ir_we_i.value = 0
    dut.pc_we_i.value = 0
    dut.reg_we_i.value = 1
    await Timer(1, unit="ns")
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert int(dut.rd_idx_o.value) == 0x2
    assert int(dut.rs_idx_o.value) == 0x2

    # ADD r1, r2 -> 1 + 2 = 3.
    dut.instr_i.value = 0x16
    dut.reg_we_i.value = 0
    dut.ir_we_i.value = 1
    dut.pc_we_i.value = 1
    await Timer(1, unit="ns")
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")

    dut.ir_we_i.value = 0
    dut.pc_we_i.value = 0
    dut.reg_we_i.value = 1
    await Timer(1, unit="ns")
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert int(dut.opcode_o.value) == 0x1

    # SUB r1, r2 -> 1 - 2 wraps and reports carry/no-borrow semantics.
    dut.instr_i.value = 0x26
    dut.reg_we_i.value = 0
    dut.ir_we_i.value = 1
    dut.pc_we_i.value = 1
    await Timer(1, unit="ns")
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")

    dut.ir_we_i.value = 0
    dut.pc_we_i.value = 0
    dut.reg_we_i.value = 1
    await Timer(1, unit="ns")
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert int(dut.opcode_o.value) == 0x2

    # Relative PC load from operand (base is next PC). Load IR first, then apply
    # the branch on the following cycle so operand is already latched in ir_q.
    dut.instr_i.value = 0x52
    dut.reg_we_i.value = 0
    dut.ir_we_i.value = 1
    dut.pc_we_i.value = 1
    dut.pc_load_operand_i.value = 0
    await Timer(1, unit="ns")
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    dut.ir_we_i.value = 0
    dut.pc_load_operand_i.value = 1
    await Timer(1, unit="ns")
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert int(dut.pc_o.value) == 0x7

    # Ena hold check.
    dut.ena.value = 0
    hold_pc = int(dut.pc_o.value)
    await ClockCycles(dut.clk, 2)
    await Timer(1, unit="ns")
    assert int(dut.pc_o.value) == hold_pc
