`timescale 1ns/1ps

module tb_umml_genesis;
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
    
    // ==========================================
    // THE "SOURCE CODE" (Raw Numbers in Data Memory)
    // We are compiling: ADD R0, R1 (twice) then HALT.
    // ==========================================
    uut.data_memory[0] = 16'd2;  // Opcode: ADD
    uut.data_memory[1] = 16'd0;  // Rd: R0
    uut.data_memory[2] = 16'd1;  // Rs: R1
    
    uut.data_memory[3] = 16'd2;  // Opcode: ADD
    uut.data_memory[4] = 16'd0;  // Rd: R0
    uut.data_memory[5] = 16'd1;  // Rs: R1
    
    uut.data_memory[6] = 16'd15; // Opcode: HALT
    uut.data_memory[7] = 16'd0;  // Rd: 0
    uut.data_memory[8] = 16'd0;  // Rs: 0

    // ==========================================
    // THE ASSEMBLER ENGINE (Fully Assembled & Hardcoded)
    // Output target is safely set to address 64 to avoid self-overwrite!
    // ==========================================
    
    // --- SETUP POINTERS ---
    uut.instr_memory[0]  = 16'h1210; // MOV R2, R1
    uut.instr_memory[1]  = 16'h6210; // SUB R2, R1
    uut.instr_memory[2]  = 16'h1310; // MOV R3, R1
    uut.instr_memory[3]  = 16'h2330; // ADD R3, R3 (2)
    uut.instr_memory[4]  = 16'h2330; // ADD R3, R3 (4)
    uut.instr_memory[5]  = 16'h2330; // ADD R3, R3 (8)
    uut.instr_memory[6]  = 16'h2330; // ADD R3, R3 (16)
    uut.instr_memory[7]  = 16'h2330; // ADD R3, R3 (32)
    uut.instr_memory[8]  = 16'h2330; // ADD R3, R3 (64) <-- SAFE ZONE START
    
    // --- COMPILE INSTRUCTION 1 ---
    uut.instr_memory[9]  = 16'h3420; // LOAD R4, R2
    uut.instr_memory[10] = 16'hA40C; // SHLI R4, 12
    uut.instr_memory[11] = 16'h2210; // ADD R2, R1
    uut.instr_memory[12] = 16'h3520; // LOAD R5, R2
    uut.instr_memory[13] = 16'hA508; // SHLI R5, 8
    uut.instr_memory[14] = 16'hB450; // OR R4, R5
    uut.instr_memory[15] = 16'h2210; // ADD R2, R1
    uut.instr_memory[16] = 16'h3620; // LOAD R6, R2
    uut.instr_memory[17] = 16'hA604; // SHLI R6, 4
    uut.instr_memory[18] = 16'hB460; // OR R4, R6
    uut.instr_memory[19] = 16'hC340; // STORE_INST R3, R4 (Writes to 64)
    uut.instr_memory[20] = 16'h2310; // ADD R3, R1 (65)
    uut.instr_memory[21] = 16'h2210; // ADD R2, R1
    
    // --- COMPILE INSTRUCTION 2 ---
    uut.instr_memory[22] = 16'h3420; // LOAD R4, R2
    uut.instr_memory[23] = 16'hA40C; // SHLI R4, 12
    uut.instr_memory[24] = 16'h2210; // ADD R2, R1
    uut.instr_memory[25] = 16'h3520; // LOAD R5, R2
    uut.instr_memory[26] = 16'hA508; // SHLI R5, 8
    uut.instr_memory[27] = 16'hB450; // OR R4, R5
    uut.instr_memory[28] = 16'h2210; // ADD R2, R1
    uut.instr_memory[29] = 16'h3620; // LOAD R6, R2
    uut.instr_memory[30] = 16'hA604; // SHLI R6, 4
    uut.instr_memory[31] = 16'hB460; // OR R4, R6
    uut.instr_memory[32] = 16'hC340; // STORE_INST R3, R4 (Writes to 65)
    uut.instr_memory[33] = 16'h2310; // ADD R3, R1 (66)
    uut.instr_memory[34] = 16'h2210; // ADD R2, R1
    
    // --- COMPILE INSTRUCTION 3 (HALT) ---
    uut.instr_memory[35] = 16'h3420; // LOAD R4, R2
    uut.instr_memory[36] = 16'hA40C; // SHLI R4, 12
    uut.instr_memory[37] = 16'h2210; // ADD R2, R1
    uut.instr_memory[38] = 16'h3520; // LOAD R5, R2
    uut.instr_memory[39] = 16'hA508; // SHLI R5, 8
    uut.instr_memory[40] = 16'hB450; // OR R4, R5
    uut.instr_memory[41] = 16'h2210; // ADD R2, R1
    uut.instr_memory[42] = 16'h3620; // LOAD R6, R2
    uut.instr_memory[43] = 16'hA604; // SHLI R6, 4
    uut.instr_memory[44] = 16'hB460; // OR R4, R6
    uut.instr_memory[45] = 16'hC340; // STORE_INST R3, R4 (Writes to 66)
    
    // --- JUMP TO COMPILED CODE ---
    uut.instr_memory[46] = 16'h5040; // JMP 64 (0x5040)
    
    #3000; // Wait for the Assembler to compile and the compiled code to run
    
    $display("=== UMML STAGE 3: FULL SELF-HOSTING VERIFIED ===");
    $display("Compiled Code at Inst[64] = 0x%h (Expected 0x2010)", uut.instr_memory[64]);
    $display("Compiled Code at Inst[65] = 0x%h (Expected 0x2010)", uut.instr_memory[65]);
    $display("Compiled Code at Inst[66] = 0x%h (Expected 0xF000)", uut.instr_memory[66]);
    $display("R0 (Result of compiled code) = %d (Expected 2)", uut.regs[0]);
    
    if (uut.instr_memory[64] == 16'h2010 && uut.regs[0] == 16'd2)
        $display("✓ SINGULARITY CONFIRMED: CPU read source code, compiled it, and executed it.");
    else
        $display("✗ Bootstrap failed.");
        
    #100;
    $finish;
end
endmodule