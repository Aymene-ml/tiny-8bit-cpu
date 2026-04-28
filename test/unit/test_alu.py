import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def test_alu_add_sub_xor(dut):
    dut.op_i.value = 0
    dut.acc_i.value = 3
    dut.mem_i.value = 5
    await Timer(1, unit="ns")
    assert int(dut.result_o.value) == 8
    assert int(dut.carry_o.value) == 0

    dut.op_i.value = 1
    dut.acc_i.value = 8
    dut.mem_i.value = 5
    await Timer(1, unit="ns")
    assert int(dut.result_o.value) == 3
    assert int(dut.carry_o.value) == 1

    dut.op_i.value = 4
    dut.acc_i.value = 0b1010
    dut.mem_i.value = 0b1100
    await Timer(1, unit="ns")
    assert int(dut.result_o.value) == 0b0110


@cocotb.test()
async def test_alu_shift_carry(dut):
    dut.op_i.value = 5
    dut.acc_i.value = 0b1001_0001
    dut.mem_i.value = 1
    await Timer(1, unit="ns")
    assert int(dut.result_o.value) == 0b0010_0010
    assert int(dut.carry_o.value) == 1

    dut.op_i.value = 6
    dut.acc_i.value = 0b1001_0001
    dut.mem_i.value = 1
    await Timer(1, unit="ns")
    assert int(dut.result_o.value) == 0b0100_1000
    assert int(dut.carry_o.value) == 1
