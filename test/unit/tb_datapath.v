`default_nettype none
`timescale 1ns / 1ps

module tb_datapath;
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] instr_i;
  reg reg_we_i;
  reg pc_we_i;
  reg ir_we_i;
  reg data_we_i;
  reg [3:0] alu_op_i;
  reg [1:0] acc_src_sel_i;
  reg pc_load_operand_i;
  wire [7:0] rd_o;
  wire [4:0] pc_o;
  wire [3:0] opcode_o;
  wire [3:0] operand_o;
  wire [1:0] rd_idx_o;
  wire [1:0] rs_idx_o;
  wire rd_carry_o;
  wire rd_zero_o;

  datapath u_dut (
      .clk(clk),
      .rst_n(rst_n),
      .ena(ena),
      .instr_i(instr_i),
      .reg_we_i(reg_we_i),
      .pc_we_i(pc_we_i),
      .ir_we_i(ir_we_i),
      .data_we_i(data_we_i),
      .alu_op_i(alu_op_i),
      .acc_src_sel_i(acc_src_sel_i),
      .pc_load_operand_i(pc_load_operand_i),
      .rd_o(rd_o),
      .pc_o(pc_o),
      .opcode_o(opcode_o),
      .operand_o(operand_o),
      .rd_idx_o(rd_idx_o),
      .rs_idx_o(rs_idx_o),
      .rd_carry_o(rd_carry_o),
      .rd_zero_o(rd_zero_o)
  );
endmodule
