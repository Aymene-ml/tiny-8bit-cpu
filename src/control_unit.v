/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Control unit for the teaching CPU.
// Instruction format:
//   [7:4] opcode
//   [3:0] operand nibble
// Register-format instructions use [3:2] as rd and [1:0] as rs.
// Immediate/jump-format instructions use the full operand nibble.
//
// Control outputs:
//   - acc_we_o: register-file write enable
//   - acc_src_sel_o: writeback source select
//   - alu_op_o: ALU function code
module control_unit (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       ena,
    input  wire [3:0] opcode_i,
    input  wire       acc_zero_i,
    output wire       fetch_phase_o,
    output wire       exec_phase_o,
    output reg        acc_we_o,
    output reg        pc_we_o,
    output reg        ir_we_o,
    output reg        data_we_o,
    output reg  [3:0] alu_op_o,       // ALU operation code
    output reg  [1:0] acc_src_sel_o,
    output reg        pc_load_operand_o
);

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
  localparam [3:0] OP_NOP  = 4'hF;

  // ALU operation codes (must match alu.v)
  localparam [3:0] ALU_OP_ADD = 4'h0;
  localparam [3:0] ALU_OP_SUB = 4'h1;
  localparam [3:0] ALU_OP_AND = 4'h2;
  localparam [3:0] ALU_OP_OR  = 4'h3;
  localparam [3:0] ALU_OP_XOR = 4'h4;
  localparam [3:0] ALU_OP_SHL = 4'h5;
  localparam [3:0] ALU_OP_SHR = 4'h6;

  wire fetch_phase;
  wire exec_phase;

  control_fsm u_control_fsm (
      .clk(clk),
      .rst_n(rst_n),
      .ena(ena),
      .fetch_phase(fetch_phase),
      .exec_phase(exec_phase)
  );

  assign fetch_phase_o = fetch_phase;
  assign exec_phase_o  = exec_phase;

  always @* begin
    acc_we_o          = 1'b0;
    pc_we_o           = 1'b0;
    ir_we_o           = 1'b0;
    data_we_o         = 1'b0;
    alu_op_o          = ALU_OP_ADD;  // Default to ADD
    acc_src_sel_o     = 2'b11;       // hold
    pc_load_operand_o = 1'b0;

    if (fetch_phase) begin
      ir_we_o = 1'b1;
      pc_we_o = 1'b1;
    end else if (exec_phase) begin
      case (opcode_i)
        OP_LDI: begin
          acc_we_o      = 1'b1;
          acc_src_sel_o = 2'b00; // zero-extend the low 2 bits into the destination register
        end

        OP_ADD: begin
          acc_we_o      = 1'b1;
          acc_src_sel_o = 2'b01; // ALU result
          alu_op_o      = ALU_OP_ADD;
        end

        OP_SUB: begin
          acc_we_o      = 1'b1;
          acc_src_sel_o = 2'b01; // ALU result
          alu_op_o      = ALU_OP_SUB;
        end

        OP_AND: begin
          acc_we_o      = 1'b1;
          acc_src_sel_o = 2'b01; // ALU result
          alu_op_o      = ALU_OP_AND;
        end

        OP_OR: begin
          acc_we_o      = 1'b1;
          acc_src_sel_o = 2'b01; // ALU result
          alu_op_o      = ALU_OP_OR;
        end

        OP_XOR: begin
          acc_we_o      = 1'b1;
          acc_src_sel_o = 2'b01; // ALU result
          alu_op_o      = ALU_OP_XOR;
        end

        OP_SHL: begin
          acc_we_o      = 1'b1;
          acc_src_sel_o = 2'b01; // ALU result
          alu_op_o      = ALU_OP_SHL;
        end

        OP_SHR: begin
          acc_we_o      = 1'b1;
          acc_src_sel_o = 2'b01; // ALU result
          alu_op_o      = ALU_OP_SHR;
        end

        OP_STO: begin
          data_we_o = 1'b1;
        end

        OP_LDM: begin
          acc_we_o      = 1'b1;
          acc_src_sel_o = 2'b10; // memory read data
        end

        OP_JMPZ: begin
          if (acc_zero_i) begin
            pc_we_o           = 1'b1;
            pc_load_operand_o = 1'b1;
          end
        end

        OP_JMPNZ: begin
          if (!acc_zero_i) begin
            pc_we_o           = 1'b1;
            pc_load_operand_o = 1'b1;
          end
        end

        OP_MOV: begin
          acc_we_o = 1'b1;
        end

        OP_INC: begin
          acc_we_o = 1'b1;
        end

        OP_DEC: begin
          acc_we_o = 1'b1;
        end

        OP_NOP: begin
          // Explicit NOP for teaching clarity.
        end

        default: begin
          // Unsupported opcodes act as NOP.
        end
      endcase
    end
  end

endmodule