//-----------------------------------------------------------------------------
// Module: async_wddl_spike_generator
// Desc  : Asynchronous threshold detector (The "Fire" in Integrate-and-Fire).
//         Emits a self-timed Spike Token ONLY when input exceeds threshold.
//         Zero idle power. No clocked activation functions.
//-----------------------------------------------------------------------------
module async_wddl_spike_generator #(
    parameter DATA_W = 16,
    parameter THRESHOLD = 10  // The firing threshold
) (
    input  logic rst_n,
    
    // Input: Membrane potential (from Integrator)
    input  logic req_in,
    output logic ack_out,
    input  logic [DATA_W-1:0] data_in_t, data_in_f,
    
    // Output: The "Spike" Token
    output logic spike_req,
    input  logic spike_ack
);

    // Combinational magnitude comparison (Pure monotone logic)
    logic is_above_threshold;
    assign is_above_threshold = (data_in_t > THRESHOLD);

    // Event-triggered Spike Emission
    // spike_req is ONLY asserted if data arrives AND it crosses the threshold.
    // If below threshold, the token is absorbed (dropped), saving downstream power.
    assign spike_req = req_in & is_above_threshold;
    
    // Early acknowledge to upstream (Integrator)
    assign ack_out = req_in;

endmodule
