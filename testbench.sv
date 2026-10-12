`timescale 1ns/1ps

module tb_umml;
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
    
    $readmemh("program.hex", uut.instr_memory);
    
    // Pre-load the secret for the chained attack example
    uut.data_memory[16] = 16'hDEAD; 
    
    // Wait for execution to finish (adjust time if your script is longer)
    #2000; 
    
    $display("=== SIMULATION COMPLETE ===");
    $display("Final Cycle Count: %d", uut.cycle_counter);
    
    #100;
    $finish;
end
endmodule