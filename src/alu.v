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
    output reg  [7:0] result_o
);

  // Operation codes
  localparam OP_ADD = 4'h0;
  localparam OP_SUB = 4'h1;
  localparam OP_AND = 4'h2;
  localparam OP_OR  = 4'h3;
  localparam OP_XOR = 4'h4;
  localparam OP_SHL = 4'h5;
  localparam OP_SHR = 4'h6;

  always @* begin
    case (op_i)
      OP_ADD: result_o = acc_i + mem_i;
      OP_SUB: result_o = acc_i - mem_i;
      OP_AND: result_o = acc_i & mem_i;
      OP_OR:  result_o = acc_i | mem_i;
      OP_XOR: result_o = acc_i ^ mem_i;
      OP_SHL: result_o = acc_i << mem_i[2:0];  // Shift left by mem_i[2:0]
      OP_SHR: result_o = acc_i >> mem_i[2:0];  // Shift right by mem_i[2:0]
      default: result_o = 8'h00;
    endcase
  end

endmodule