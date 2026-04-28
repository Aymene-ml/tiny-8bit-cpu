`default_nettype none
`timescale 1ns / 1ps

module tb_alu;
  reg [3:0] op_i;
  reg [7:0] acc_i;
  reg [7:0] mem_i;
  wire [7:0] result_o;

  alu u_dut (
      .op_i(op_i),
      .acc_i(acc_i),
      .mem_i(mem_i),
      .result_o(result_o)
  );
endmodule
