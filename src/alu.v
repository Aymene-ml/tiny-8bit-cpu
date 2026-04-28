/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Expanded ALU for the teaching CPU.
// Supports: ADD, SUB, AND, OR, XOR, SHL, SHR.
module alu (
    input  wire [3:0] op_i,       // operation select
    input  wire [7:0] acc_i,      // operand A
    input  wire [7:0] mem_i,      // operand B
  output reg  [7:0] result_o,
  output reg        carry_o
);

  // Operation codes
  localparam OP_ADD = 4'h0;
  localparam OP_SUB = 4'h1;
  localparam OP_AND = 4'h2;
  localparam OP_OR  = 4'h3;
  localparam OP_XOR = 4'h4;
  localparam OP_SHL = 4'h5;
  localparam OP_SHR = 4'h6;

  reg [8:0] wide_result;
  reg [2:0] shift_amt;

  always @* begin
    wide_result = 9'h000;
    shift_amt = mem_i[2:0];
    carry_o = 1'b0;
    case (op_i)
      OP_ADD: begin
        wide_result = {1'b0, acc_i} + {1'b0, mem_i};
        result_o = wide_result[7:0];
        carry_o = wide_result[8];
      end
      OP_SUB: begin
        wide_result = {1'b0, acc_i} - {1'b0, mem_i};
        result_o = wide_result[7:0];
        carry_o = ~wide_result[8];  // 1 means no borrow
      end
      OP_AND: begin
        result_o = acc_i & mem_i;
      end
      OP_OR: begin
        result_o = acc_i | mem_i;
      end
      OP_XOR: begin
        result_o = acc_i ^ mem_i;
      end
      OP_SHL: begin
        wide_result = {acc_i, 1'b0} << shift_amt;
        result_o = acc_i << shift_amt;
        carry_o = (shift_amt == 3'd0) ? 1'b0 : acc_i[8 - shift_amt];
      end
      OP_SHR: begin
        result_o = acc_i >> shift_amt;
        carry_o = (shift_amt == 3'd0) ? 1'b0 : acc_i[shift_amt - 3'd1];
      end
      default: begin
        result_o = 8'h00;
      end
    endcase
  end

endmodule
