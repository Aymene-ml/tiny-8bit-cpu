/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// DE2-only test wrapper.
//
// This wrapper feeds instructions from a small ROM into cpu_top during fetch
// phase. It is intended for bring-up and validation on the DE2 board and can
// be removed after hardware testing.
module de2_cpu_test_top (
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [17:0] SW,
    output wire [17:0] LEDR,
    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3,
    output wire [6:0]  HEX4,
    output wire [6:0]  HEX5,
    output wire [6:0]  HEX6,
    output wire [6:0]  HEX7
);

  wire clk = CLOCK_50;
  wire rst_n = KEY[0];
  wire ena = SW[17];

  wire [7:0] cpu_ui_in;
  wire [7:0] cpu_uo_out;
  wire [7:0] cpu_uio_in = 8'h00;
  wire [7:0] cpu_uio_out;
  wire [7:0] cpu_uio_oe;

  wire fetch_phase = cpu_uio_out[7];
  wire carry_flag = cpu_uio_out[6];
  wire zero_flag = cpu_uio_out[5];
  wire [4:0] pc_dbg = cpu_uio_out[4:0];

  assign cpu_ui_in = fetch_phase ? program_rom(pc_dbg) : 8'h00;

  cpu_top u_cpu_top (
      .ui_in(cpu_ui_in),
      .uo_out(cpu_uo_out),
      .uio_in(cpu_uio_in),
      .uio_out(cpu_uio_out),
      .uio_oe(cpu_uio_oe),
      .ena(ena),
      .clk(clk),
      .rst_n(rst_n)
  );

  // LED layout:
  //   LEDR[7:0]   = current destination register value
  //   LEDR[12:8]  = PC debug
  //   LEDR[13]    = fetch phase
  //   LEDR[14]    = carry flag
  //   LEDR[15]    = zero flag
  //   LEDR[17:16] = unused
  assign LEDR = {2'b00, zero_flag, carry_flag, fetch_phase, pc_dbg, cpu_uo_out};

  // Show the live rd value and PC on HEX displays.
  assign HEX0 = hex7seg(cpu_uo_out[3:0]);
  assign HEX1 = hex7seg(cpu_uo_out[7:4]);
  assign HEX2 = hex7seg(pc_dbg[3:0]);
  assign HEX3 = hex7seg({3'b000, pc_dbg[4]});
  assign HEX4 = 7'h7f;
  assign HEX5 = 7'h7f;
  assign HEX6 = 7'h7f;
  assign HEX7 = 7'h7f;

  function automatic [7:0] program_rom(input [4:0] addr);
    begin
      case (addr)
        5'd0:  program_rom = 8'h05; // LDI r1, #1
        5'd1:  program_rom = 8'h0A; // LDI r2, #2
        5'd2:  program_rom = 8'h16; // ADD r1, r2 -> 3
        5'd3:  program_rom = 8'h26; // SUB r1, r2 -> 1
        5'd4:  program_rom = 8'h25; // SUB r1, r1 -> 0, sets zero
        5'd5:  program_rom = 8'h52; // JMPZ +2
        5'd6:  program_rom = 8'h0D; // LDI r3, #1 (skipped when branch works)
        5'd7:  program_rom = 8'h0E; // LDI r3, #2 (skipped when branch works)
        5'd8:  program_rom = 8'h58; // JMPZ -8 (loop back to addr 1 while zero is set)
        default: program_rom = 8'hF0; // NOP
      endcase
    end
  endfunction

  function automatic [6:0] hex7seg(input [3:0] value);
    begin
      case (value)
        4'h0: hex7seg = 7'b1000000;
        4'h1: hex7seg = 7'b1111001;
        4'h2: hex7seg = 7'b0100100;
        4'h3: hex7seg = 7'b0110000;
        4'h4: hex7seg = 7'b0011001;
        4'h5: hex7seg = 7'b0010010;
        4'h6: hex7seg = 7'b0000010;
        4'h7: hex7seg = 7'b1111000;
        4'h8: hex7seg = 7'b0000000;
        4'h9: hex7seg = 7'b0010000;
        4'hA: hex7seg = 7'b0001000;
        4'hB: hex7seg = 7'b0000011;
        4'hC: hex7seg = 7'b1000110;
        4'hD: hex7seg = 7'b0100001;
        4'hE: hex7seg = 7'b0000110;
        4'hF: hex7seg = 7'b0001110;
      endcase
    end
  endfunction

endmodule

`default_nettype wire
