//-----------------------------------------------------------------------------
// Module: async_leak_token_generator
// Desc  : Asynchronous leak token generator for LIF neurons.
//         Uses a gated local oscillator that sleeps when disabled (Zero idle power).
//-----------------------------------------------------------------------------
module async_leak_token_generator #(
    parameter DATA_W = 16,
    parameter LEAK_RATE = 2
) (
    input  logic                  rst_n,
    input  logic                  enable,
    
    output logic                  req_out,
    input  logic                  ack_in,
    output logic [DATA_W-1:0]     leak_t, leak_f
);

    logic local_clk;
    initial local_clk = 0;

    // Gated event-driven oscillator (Sleeps when disabled)
    always begin
        if (enable) begin
            #5 local_clk = ~local_clk; // Oscillate
        end else begin
            wait (enable); // Sleep until enabled (Zero idle power)
            local_clk = 0;
        end
    end

    // Local counter to space out the leak tokens
    logic [LEAK_RATE-1:0] counter;
    always @(posedge local_clk or negedge rst_n) begin
        if (!rst_n) counter <= '0;
        else        counter <= counter + 1;
    end

    // Emit a -1 token (0xFFFF in 16-bit 2's complement) when counter wraps
    assign req_out = enable & (counter == '0);
    assign leak_t  = 16'hFFFF; // -1
    assign leak_f  = ~16'hFFFF;

endmodule
