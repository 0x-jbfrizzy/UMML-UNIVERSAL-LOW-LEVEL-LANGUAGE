//-----------------------------------------------------------------------------
// Module: async_clock_spine
// Desc  : FEATURE 4: Deterministic Hardware Clock Flank Isolation.
//         Allows a single, crisp clock edge for initialization, then physically 
//         gates the clock off for zero-power asynchronous operation.
//-----------------------------------------------------------------------------
module async_clock_spine (
    input  logic global_clk,
    input  logic rst_n,
    input  logic spine_enable,      // High during init, low during async operation
    output logic isolated_clk       // The gated clock delivered to control registers
);

    // Simple, glitch-free clock gating using a latch
    // When spine_enable is low, isolated_clk is forced to 0, stopping all clock activity.
    logic enable_latch;
    
    always_latch begin
        if (!rst_n)
            enable_latch <= 1'b0;
        else if (!global_clk) // Update latch only when clock is low to prevent glitches
            enable_latch <= spine_enable;
    end

    assign isolated_clk = global_clk & enable_latch;

endmodule
