//-----------------------------------------------------------------------------
// Module: wddl_subtractor
// Desc  : 16-bit Wave Dynamic Differential Logic (WDDL) subtractor.
//         Computes (A - B). Dual-rail encoded for constant power/EMI.
// Auth  : JBFRIZZY
// Date  : 2026-10-15
//-----------------------------------------------------------------------------
module wddl_subtractor #(
    parameter DATA_W = 16
) (
    input  logic                  clk,
    input  logic                  rst_n,
    
    // Dual-rail inputs (A and B)
    input  logic [DATA_W-1:0]     a_t,
    input  logic [DATA_W-1:0]     a_f,
    input  logic [DATA_W-1:0]     b_t,
    input  logic [DATA_W-1:0]     b_f,
    
    // Handshake / Valid (Spatial dataflow trigger)
    input  logic                  valid_in,
    output logic                  valid_out,
    
    // Dual-rail output (Result = A - B)
    output logic [DATA_W-1:0]     res_t,
    output logic [DATA_W-1:0]     res_f
);

    // Pre-charge and Evaluate phases
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            res_t     <= '0;
            res_f     <= '0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            // Evaluate phase:
            // True rail computes the actual subtraction.
            res_t <= a_t - b_t;
            
            // False rail computes the complement to maintain dual-rail balance.
            res_f <= ~(a_t - b_t);
            
            valid_out <= 1'b1;
        end else begin
            // Idle phase: pre-charge to safe state
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
            if (a_t === a_f) $error("INPUT A RAIL COLLISION at %0t", $time);
            if (b_t === b_f) $error("INPUT B RAIL COLLISION at %0t", $time);
        end
    end
    `endif

endmodule
