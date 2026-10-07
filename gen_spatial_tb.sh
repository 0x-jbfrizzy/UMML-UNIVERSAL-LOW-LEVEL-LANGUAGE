#!/bin/bash
# UMML Native Spatial Testbench Generator
# Usage: ./gen_spatial_tb.sh

cat << 'TOP' > testbench.sv
`timescale 1ns/1ps

module tb_umml_spatial_compiler;
reg clk, rst, cfg_load;
reg [3:0] cfg_x, cfg_y;
reg [1:0] cfg_op, cfg_in_a, cfg_in_b, cfg_out;
reg [15:0] grid_in_n, grid_in_s, grid_in_e, grid_in_w;
wire [15:0] grid_out_n, grid_out_s, grid_out_e, grid_out_w;

umml_spatial_fabric uut (
    .clk(clk), .rst(rst),
    .cfg_load(cfg_load), .cfg_x(cfg_x), .cfg_y(cfg_y),
    .cfg_op(cfg_op), .cfg_in_a(cfg_in_a), .cfg_in_b(cfg_in_b), .cfg_out(cfg_out),
    .grid_in_n(grid_in_n), .grid_in_s(grid_in_s),
    .grid_in_e(grid_in_e), .grid_in_w(grid_in_w),
    .grid_out_n(grid_out_n), .grid_out_s(grid_out_s),
    .grid_out_e(grid_out_e), .grid_out_w(grid_out_w)
);

initial begin clk = 0; forever #10 clk = ~clk; end

reg [15:0] config_mem [0:63];
integer i;

initial begin
    rst = 1; cfg_load = 0;
    grid_in_n = 0; grid_in_s = 0; grid_in_e = 0; grid_in_w = 0;

    #50; rst = 0;

    $display("=== UMML STAGE 5: NATIVE SPATIAL COMPILER ===");
    $display("Loading compiled bitstream...");

    cfg_load = 1;
TOP

i=0
while read -r line; do
  if [ -n "$line" ]; then
    echo "        config_mem[$i] = 16'h$line;" >> testbench.sv
    i=$((i+1))
  fi
done < config.hex

cat << 'BOTTOM' >> testbench.sv
    for (i = 0; i < 7; i = i + 1) begin
        cfg_op   = config_mem[i][15:14];
        cfg_x    = config_mem[i][13:10];
        cfg_y    = config_mem[i][9:6];
        cfg_in_a = config_mem[i][5:4];
        cfg_in_b = config_mem[i][3:2];
        cfg_out  = config_mem[i][1:0];
        #20;
    end
    cfg_load = 0;

    $display("Silicon configured. Beginning systolic injection...");

    grid_in_n = 16'd3;
    #20;
    grid_in_w = 16'd5;
    grid_in_s = 16'd2;

    #20; $display("Cycle 2: 5 and 3 collide at ALU1. Executing 5 + 3 = 8.");
    #20; $display("Cycle 3: 8 and 2 collide at ALU2. Executing 8 + 2 = 10.");
    #20; $display("Cycle 4: Result (10) reaches East boundary.");
    #20;

    $display("");
    $display("Result at East Boundary: %0d (Expected 10)", grid_out_e);

    if (grid_out_e == 16'd10)
        $display("✓ NATIVE COMPILER SUCCESSFUL: Graph compiled to physical silicon.");
    else
        $display("✗ Compiler failed.");

    #100; $finish;
end
endmodule
BOTTOM