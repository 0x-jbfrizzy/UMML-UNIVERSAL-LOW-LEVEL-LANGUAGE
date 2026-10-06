// UMML Hardware Core: Multi-Domain Chained Architecture
// Models NoC backpressure, Cache Coherence (MOESI), and Speculative Execution.

module copper_chained_core (
    input wire clk,
    input wire rst,
    output reg [31:0] cycle_counter
);

// Memory Arrays
reg [15:0] instr_memory [0:255];
reg [15:0] data_memory [0:255];

// Architectural State
reg [15:0] regs [0:15];
reg [15:0] pc;
reg [15:0] shadow_regs [0:15]; // For speculative rollback

// Microarchitectural State
reg [15:0] cache_addr [0:3];
reg cache_valid [0:3];

// NoC Router State
reg [3:0] vc_block_state;
reg [7:0] noc_stall_counter;

// Physical Timing Parameters
parameter BASE_RFO_PENALTY = 15;
parameter NOC_AMPLIFICATION = 25;

always @(posedge clk or posedge rst) begin
    reg [3:0] opcode;
    reg [3:0] rd, rs;
    reg [15:0] instr;
    integer i;
    
    if (rst) begin
        cycle_counter <= 32'd0;
        pc <= 16'd0;
        
        // Initialize architectural state
        for (i = 0; i < 16; i = i + 1) regs[i] <= 16'd0;
        regs[1] <= 16'd1; // Hardwire R1 to 1 for setup
        
        // Initialize microarchitectural state
        vc_block_state <= 4'd0;
        noc_stall_counter <= 8'd0;
        for (i = 0; i < 4; i = i + 1) cache_valid[i] <= 1'b0;
    end else begin
        
        // Handle NoC Pipeline Stall (Halts PC, but clock keeps ticking)
        if (noc_stall_counter > 0) begin
            noc_stall_counter <= noc_stall_counter - 1;
            cycle_counter <= cycle_counter + 1;
        end else begin
            cycle_counter <= cycle_counter + 1;
            instr = instr_memory[pc];
            
            // Decode 16-bit instruction: OOOO DDDD SSSS IIII
            opcode = instr[15:12];
            rd = instr[11:8];
            rs = instr[7:4];
            
            case (opcode)
                4'h0: pc <= pc + 1; // NOP
                
                4'h1: begin regs[rd] <= regs[rs]; pc <= pc + 1; end // MOV
                
                4'h2: begin regs[rd] <= regs[rd] + regs[rs]; pc <= pc + 1; end // ADD
                
                4'h3: begin // LOAD (Triggers Coherence + NoC Amplification)
                    regs[rd] <= data_memory[regs[rs]];
                    cache_valid[0] <= 1'b1;
                    cache_addr[0] <= regs[rs];
                    
                    // THE CHAIN: If NoC VC 2 is blocked, amplify the RFO penalty
                    if (vc_block_state[2]) begin
                        cycle_counter <= cycle_counter + BASE_RFO_PENALTY + NOC_AMPLIFICATION;
                    end else begin
                        cycle_counter <= cycle_counter + BASE_RFO_PENALTY;
                    end
                    pc <= pc + 1;
                end
                
                4'h5: begin regs[rd] <= cycle_counter[15:0]; pc <= pc + 1; end // READ_CYCLES
                
                4'h6: begin regs[rd] <= regs[rd] - regs[rs]; pc <= pc + 1; end // SUB
                
                4'h7: begin // VC_BLOCK (NoC Contention)
                    vc_block_state <= vc_block_state | (1 << rd);
                    pc <= pc + 1;
                end
                
                4'h9: begin // PROBE (Cache side-channel)
                    regs[rd] <= 16'd0;
                    if (cache_valid[0] && cache_addr[0] == regs[rs]) 
                        regs[rd] <= 16'd1;
                    pc <= pc + 1;
                end
                
                4'hB: begin // SAVE_REG (Snapshot for Spectre)
                    for (i = 0; i < 16; i = i + 1) shadow_regs[i] <= regs[i];
                    pc <= pc + 1;
                end
                
                4'hC: begin // ROLLBACK (Revert architectural state only)
                    for (i = 0; i < 16; i = i + 1) regs[i] <= shadow_regs[i];
                    // Note: cache_valid is intentionally NOT rolled back.
                    pc <= pc + 1;
                end
                
                4'hE: begin // FORCE_MISPRED (Spectre trigger)
                    pc <= pc + 1;
                end
                
                4'hF: begin end // HALT (Infinite loop)
                
                default: pc <= pc + 1;
            endcase
        end
    end
end
endmodule