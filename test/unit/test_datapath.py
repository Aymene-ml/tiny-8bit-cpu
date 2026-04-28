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
    assert int(dut.rd_o.value) == 0

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

    # Immediate path should write low 2-bit literal into rd.
    dut.ir_we_i.value = 0
    dut.pc_we_i.value = 0
    dut.reg_we_i.value = 1
    dut.acc_src_sel_i.value = 0b00
    await Timer(1, unit="ns")
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert int(dut.rd_o.value) == 0x01

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
    dut.acc_src_sel_i.value = 0b00
    await Timer(1, unit="ns")
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert int(dut.rd_o.value) == 0x02

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
    dut.acc_src_sel_i.value = 0b01
    await Timer(1, unit="ns")
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert int(dut.rd_o.value) == 0x03

    # Absolute PC load from operand. Load IR first, then apply the PC load on the
    # following cycle so the operand nibble is already latched in ir_q.
    dut.instr_i.value = 0x5A
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
    assert int(dut.pc_o.value) == 0xA

    # Ena hold check.
    dut.ena.value = 0
    hold_pc = int(dut.pc_o.value)
    await ClockCycles(dut.clk, 2)
    await Timer(1, unit="ns")
    assert int(dut.pc_o.value) == hold_pc
