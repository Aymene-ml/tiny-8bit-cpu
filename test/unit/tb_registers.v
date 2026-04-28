`default_nettype none
`timescale 1ns / 1ps

module tb_registers;
  reg clk;
  reg rst_n;
  reg ena;
  reg reg_we;
  reg [1:0] reg_wd_idx;
  reg [1:0] reg_rs_idx;
  reg [1:0] reg_rd_idx;
  reg [7:0] reg_wd;
  reg pc_we;
  reg ir_we;
  reg [3:0] pc_d;
  reg [7:0] ir_d;
  wire [7:0] reg_rs;
  wire [7:0] reg_rd;
  wire [3:0] pc_q;
  wire [7:0] ir_q;

  registers u_dut (
      .clk(clk),
      .rst_n(rst_n),
      .ena(ena),
      .reg_we(reg_we),
      .reg_wd_idx(reg_wd_idx),
      .reg_rs_idx(reg_rs_idx),
      .reg_rd_idx(reg_rd_idx),
      .reg_wd(reg_wd),
      .pc_we(pc_we),
      .ir_we(ir_we),
      .pc_d(pc_d),
      .ir_d(ir_d),
      .reg_rs(reg_rs),
      .reg_rd(reg_rd),
      .pc_q(pc_q),
      .ir_q(ir_q)
  );
endmodule
