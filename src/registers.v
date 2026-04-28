/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Holds 4 general registers (r0-r3), program counter, and instruction register.
// r0 is always readable as 0 (hardwired zero).
// Dual read ports for rs (source) and rd (destination) register reads.
module registers (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       ena,
    input  wire       reg_we,       // register write enable
    input  wire [1:0] reg_wd_idx,   // write destination register index (0-3)
    input  wire [1:0] reg_rs_idx,   // read source register index (0-3)
    input  wire [1:0] reg_rd_idx,   // read destination register index (0-3)
    input  wire [7:0] reg_wd,       // write data
    input  wire       pc_we,
    input  wire       ir_we,
    input  wire [3:0] pc_d,
    input  wire [7:0] ir_d,
    output wire [7:0] reg_rs,       // read rs output (r0 hardwired to 0)
    output wire [7:0] reg_rd,       // read rd output (r0 hardwired to 0)
    output wire       zero_o,        // latched zero flag from last register write
    output reg  [3:0] pc_q,
    output reg  [7:0] ir_q
);

  reg [7:0] regs [0:3];  // r0, r1, r2, r3
  reg zero_q;
  integer idx;

  // Dual combinational reads: r0 always reads as 0
  assign reg_rs = (reg_rs_idx == 2'b00) ? 8'h00 : regs[reg_rs_idx];
  assign reg_rd = (reg_rd_idx == 2'b00) ? 8'h00 : regs[reg_rd_idx];
  assign zero_o = zero_q;

  always @(posedge clk) begin
    if (!rst_n) begin
      for (idx = 0; idx < 4; idx = idx + 1) begin
        regs[idx] <= 8'h00;
      end
      zero_q <= 1'b0;
      pc_q  <= 4'h0;
      ir_q  <= 8'h00;
    end else if (ena) begin
      if (reg_we && reg_wd_idx != 2'b00) begin  // Don't write to r0 (hardwired 0)
        regs[reg_wd_idx] <= reg_wd;
        zero_q <= (reg_wd == 8'h00);
      end
      if (pc_we) begin
        pc_q <= pc_d;
      end
      if (ir_we) begin
        ir_q <= ir_d;
      end
    end
  end

endmodule