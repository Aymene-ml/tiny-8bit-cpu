/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Datapath for the teaching CPU with a 4-register file.
// Instruction format:
//   [7:4] opcode
//   [3:0] operand nibble
// Register-format instructions use operand[3:2] as rd and operand[1:0] as rs.
// Immediate/jump-format instructions use the whole operand nibble.
module datapath (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       ena,
    input  wire [7:0] instr_i,
    input  wire       reg_we_i,
    input  wire       pc_we_i,
    input  wire       ir_we_i,
    input  wire       data_we_i,
    input  wire [3:0] alu_op_i,
    input  wire [1:0] acc_src_sel_i,
    input  wire       pc_load_operand_i,
    output wire [7:0] rd_o,
    output wire [3:0] pc_o,
    output wire [3:0] opcode_o,
    output wire [3:0] operand_o,
    output wire [1:0] rd_idx_o,
    output wire [1:0] rs_idx_o,
    output wire       rd_zero_o
);

  wire [7:0] rs_val;
  wire [7:0] rd_val;
  wire       zero_q;
  wire [3:0] pc_q;
  wire [7:0] ir_q;
  wire [7:0] data_rdata;
  wire [7:0] alu_result;

  wire [3:0] opcode = ir_q[7:4];
  wire [3:0] operand = ir_q[3:0];
  wire [1:0] rd_idx = operand[3:2];
  wire [1:0] rs_idx = operand[1:0];
  wire [1:0] imm2   = operand[1:0];

  localparam [3:0] OP_LDI  = 4'h0;
  localparam [3:0] OP_ADD  = 4'h1;
  localparam [3:0] OP_SUB  = 4'h2;
  localparam [3:0] OP_STO  = 4'h3;
  localparam [3:0] OP_LDM  = 4'h4;
  localparam [3:0] OP_JMPZ = 4'h5;
  localparam [3:0] OP_AND  = 4'h6;
  localparam [3:0] OP_OR   = 4'h7;
  localparam [3:0] OP_XOR  = 4'h8;
  localparam [3:0] OP_SHL  = 4'h9;
  localparam [3:0] OP_SHR  = 4'hA;
  localparam [3:0] OP_JMPNZ = 4'hB;
  localparam [3:0] OP_MOV  = 4'hC;
  localparam [3:0] OP_INC  = 4'hD;
  localparam [3:0] OP_DEC  = 4'hE;

  reg [7:0] rd_d;
  wire [3:0] pc_d = pc_load_operand_i ? operand : (pc_q + 4'd1);

  always @* begin
    case (opcode)
      OP_LDI:  rd_d = {6'b000000, imm2};
      OP_ADD:  rd_d = alu_result;
      OP_SUB:  rd_d = alu_result;
      OP_AND:  rd_d = alu_result;
      OP_OR:   rd_d = alu_result;
      OP_XOR:  rd_d = alu_result;
      OP_SHL:  rd_d = alu_result;
      OP_SHR:  rd_d = alu_result;
      OP_LDM:  rd_d = data_rdata;
      OP_MOV:  rd_d = rs_val;
      OP_INC:  rd_d = rd_val + 8'h01;
      OP_DEC:  rd_d = rd_val - 8'h01;
      default: rd_d = rd_val;
    endcase
  end

  registers u_registers (
      .clk(clk),
      .rst_n(rst_n),
      .ena(ena),
      .reg_we(reg_we_i),
      .reg_wd_idx(rd_idx),
      .reg_rs_idx(rs_idx),
      .reg_rd_idx(rd_idx),
      .reg_wd(rd_d),
      .pc_we(pc_we_i),
      .ir_we(ir_we_i),
      .pc_d(pc_d),
      .ir_d(instr_i),
      .reg_rs(rs_val),
      .reg_rd(rd_val),
      .zero_o(zero_q),
      .pc_q(pc_q),
      .ir_q(ir_q)
  );

  memory u_memory (
      .clk(clk),
      .rst_n(rst_n),
      .ena(ena),
      .data_addr(rs_val[3:0]),
      .data_wdata(rd_val),
      .data_we(data_we_i),
      .data_rdata(data_rdata)
  );

  alu u_alu (
      .op_i(alu_op_i),
      .acc_i(rd_val),
      .mem_i(rs_val),
      .result_o(alu_result)
  );

  assign rd_o      = rd_val;
  assign pc_o      = pc_q;
  assign opcode_o  = opcode;
  assign operand_o  = operand;
  assign rd_idx_o  = rd_idx;
  assign rs_idx_o  = rs_idx;
  assign rd_zero_o = zero_q;

endmodule

`default_nettype wire