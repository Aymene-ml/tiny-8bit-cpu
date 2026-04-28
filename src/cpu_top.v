/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Top-level teaching CPU.
// Integrates the control path and datapath.
module cpu_top #(
    parameter USE_IMEM = 0
) (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

  wire fetch_phase;
  wire exec_phase;

  wire [7:0] rd_q;
  wire [3:0] pc_q;
  wire [3:0] opcode;
  wire [1:0] rd_idx;
  wire [1:0] rs_idx;
  wire rd_zero;
  wire [7:0] instr_wire;

  wire reg_we;
  wire pc_we;
  wire ir_we;
  wire data_we;
  wire [3:0] alu_op;  // ALU operation code (4 bits)
  wire [1:0] acc_src_sel;
  wire pc_load_operand;

  control_unit u_control_unit (
      .clk(clk),
      .rst_n(rst_n),
      .ena(ena),
      .opcode_i(opcode),
      .acc_zero_i(rd_zero),
      .fetch_phase_o(fetch_phase),
      .exec_phase_o(exec_phase),
      .acc_we_o(reg_we),
      .pc_we_o(pc_we),
      .ir_we_o(ir_we),
      .data_we_o(data_we),
      .alu_op_o(alu_op),
      .acc_src_sel_o(acc_src_sel),
      .pc_load_operand_o(pc_load_operand)
  );

  datapath u_datapath (
      .clk(clk),
      .rst_n(rst_n),
      .ena(ena),
      .instr_i(instr_wire),
      .reg_we_i(reg_we),
      .pc_we_i(pc_we),
      .ir_we_i(ir_we),
      .data_we_i(data_we),
      .alu_op_i(alu_op),
      .acc_src_sel_i(acc_src_sel),
      .pc_load_operand_i(pc_load_operand),
      .rd_o(rd_q),
      .pc_o(pc_q),
      .opcode_o(opcode),
      .rd_idx_o(rd_idx),
      .rs_idx_o(rs_idx),
      .rd_zero_o(rd_zero)
  );

  // Instruction source: external `ui_in` (default) or internal IMEM when enabled.
  generate
    if (USE_IMEM) begin : GEN_IMEM
      imem u_imem (
          .addr(pc_q),
          .rdata(instr_wire)
      );
    end else begin : GEN_UI_IN
      assign instr_wire = ui_in;
    end
  endgenerate

  // Output mapping:
  // - uo_out: current destination register value
  // - uio_out: debug bus [phase | opcode[2:0] | PC[3:0]]
  assign uo_out  = rd_q;
  assign uio_out = {fetch_phase, opcode[2:0], pc_q[3:0]};
  // Keep uio as outputs for visibility; uio_in remains free for future labs.
  assign uio_oe  = 8'hff;

  wire _unused = &{uio_in, 1'b0};

endmodule