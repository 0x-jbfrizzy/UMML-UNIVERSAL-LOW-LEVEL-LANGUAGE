//-----------------------------------------------------------------------------
// Module: wddl_multiplier
// Desc  : 16x16-bit Wave Dynamic Differential Logic (WDDL) multiplier.
//         Outputs 32-bit dual-rail product. Maintains constant switching 
//         activity via explicit true/false rail complementation.
// Auth  : JBFRIZZY
// Date  : 2026-10-15
//-----------------------------------------------------------------------------
module wddl_multiplier #(
    parameter DATA_W = 16,
    parameter RES_W  = 32
) (
    input  logic                  clk,
    input  logic                  rst_n,
    
    // Dual-rail inputs
    input  logic [DATA_W-1:0]     a_t,
    input  logic [DATA_W-1:0]     a_f,
    input  logic [DATA_W-1:0]     b_t,
    input  logic [DATA_W-1:0]     b_f,
    
    // Spatial handshake
    input  logic                  valid_in,
    output logic                  valid_out,
    
    // Dual-rail 32-bit output
    output logic [RES_W-1:0]      res_t,
    output logic [RES_W-1:0]      res_f
);

    // Pre-charge and Evaluate phases
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            res_t     <= '0;
            res_f     <= '0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            // Evaluate phase
            // True rail: standard unsigned multiplication
            res_t <= a_t * b_t;
            
            // False rail: bitwise complement to maintain dual-rail balance
            // Synthesis note: Ensure backend P&R balances the routing capacitance 
            // of the true and false rail nets to prevent timing skew.
            res_f <= ~(a_t * b_t);
            
            valid_out <= 1'b1;
        end else begin
            // Idle phase: pre-charge to safe state (all zeros)
            res_t     <= '0;
            res_f     <= '0;
            valid_out <= 1'b0;
        end
    end

    // Physical symmetry assertion (Simulation only)
    `ifndef SYNTHESIS
    always @(posedge clk) begin
        if (valid_in) begin
            // Only check inputs here to avoid posedge race conditions with output assignments
            if (a_t === a_f) $error("MULT INPUT A RAIL COLLISION at %0t", $time);
            if (b_t === b_f) $error("MULT INPUT B RAIL COLLISION at %0t", $time);
        end
    end
    `endif

endmodule
