#!/bin/bash
# UMML Testbench Generator
# Usage: ./gen_tb.sh <input.hex> <output_testbench.sv>

if [ "$#" -ne 2 ]; then
    echo "Usage: ./gen_tb.sh <input.hex> <output_testbench.sv>"
    exit 1
fi

# Generate the top of the testbench
cat << 'TOP' > "$2"
`timescale 1ns/1ps

module tb_riscv_generator;
reg clk; reg rst; wire [31:0] cycle_counter;
copper_chained_core uut (.clk(clk), .rst(rst), .cycle_counter(cycle_counter));
initial begin clk = 0; forever #10 clk = ~clk; end
initial begin
  rst = 1; #50; rst = 0;
TOP

# Append the memory initialization from the hex file
i=0
while read -r line; do
  if [ -n "$line" ]; then
    echo "  uut.instr_memory[$i] = 16'h$line;" >> "$2"
    i=$((i+1))
  fi
done < "$1"

# Append the bottom of the testbench with verification logic
cat << 'BOTTOM' >> "$2"
  #5000;
  $display("=== UMML CROSS-ASSEMBLER VERIFICATION ===");
  $display("Inst 1 Low  (Addr 16): 0x%h (Expected 0x8533)", uut.data_memory[16]);
  $display("Inst 1 High (Addr 17): 0x%h (Expected 0x00C5)", uut.data_memory[17]);
  $display("Inst 2 Low  (Addr 18): 0x%h (Expected 0x8513)", uut.data_memory[18]);
  $display("Inst 2 High (Addr 19): 0x%h (Expected 0x0055)", uut.data_memory[19]);
  
  if (uut.data_memory[16] == 16'h8533 && uut.data_memory[17] == 16'h00C5 &&
      uut.data_memory[18] == 16'h8513 && uut.data_memory[19] == 16'h0055) begin
      $display("✓ CROSS-COMPILATION SUCCESSFUL: Copper CPU natively generated valid RISC-V machine code.");
  end else begin
      $display("✗ Cross-compilation failed.");
  end
  
  #100; $finish;
end
endmodule
BOTTOM

echo "Generated $2 from $1 natively."