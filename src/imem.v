/*
 * Simple instruction ROM (IMEM) for the teaching CPU.
 * Default size matches the existing 4-bit PC (16 x 8).
 */

`default_nettype none

module imem (
    input  wire [3:0] addr,
    output reg  [7:0] rdata
);

  reg [7:0] mem [0:15];

  initial begin
    // Optional initializer file. Tests can create `imem.hex` to preload instructions.
    // If the file is absent, memory contents default to x or 0 depending on simulator.
    $readmemh("imem.hex", mem);
  end

  always @* begin
    rdata = mem[addr];
  end

endmodule

`default_nettype wire
