#!/usr/bin/env bash
set -euo pipefail

# UMML Testbench Generator
# Generates a SystemVerilog testbench wrapper for Copper ISA programs.

if [ $# -ne 2 ]; then
    echo "Usage: $0 <input.hex> <output_tb.sv>" >&2
    exit 1
fi

INPUT_HEX="$1"
OUTPUT_TB="$2"

# Generate Top Module
cat << 'TOP' > "$OUTPUT_TB"
\`timescale 1ns/1ps

module tb_copper_gen;
    reg clk;
    reg rst;
    wire [31:0] cycle_counter;

    copper_chained_core uut (
        .clk(clk),
        .rst(rst),
        .cycle_counter(cycle_counter)
    );

    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    initial begin
        rst = 1;
        #50;
        rst = 0;
TOP

# Append Memory Initialization from Hex File
echo "    // Load program memory" >> "$OUTPUT_TB"
awk '{printf "    uut.data_memory[%d] = 16\x27h%s;\n", NR-1, $1}' "$INPUT_HEX" >> "$OUTPUT_TB"

# Generate Verification Logic
cat << 'BOTTOM' >> "$OUTPUT_TB"
        
        #5000;

        // Cross-assembler verification targets
        \$display("[TB] Inst 1 Low  (Addr 16): 0x%h (Exp 0x8533)", uut.data_memory[16]);
        \$display("[TB] Inst 1 High (Addr 17): 0x%h (Exp 0x00C5)", uut.data_memory[17]);
        \$display("[TB] Inst 2 Low  (Addr 18): 0x%h (Exp 0x8513)", uut.data_memory[18]);
        \$display("[TB] Inst 2 High (Addr 19): 0x%h (Exp 0x0055)", uut.data_memory[19]);

        if (uut.data_memory[16] == 16'h8533 && 
            uut.data_memory[17] == 16'h00C5 && 
            uut.data_memory[18] == 16'h8513 && 
            uut.data_memory[19] == 16'h0055) begin
            
            \$display("[PASS] Native RISC-V code generation verified.");
            \$finish(0);
        end else begin
            \$display("[FAIL] Code mismatch detected.");
            \$fatal(1, "Verification failed");
        end
    end
endmodule
BOTTOM

echo "[INFO] Generated $OUTPUT_TB" >&2
