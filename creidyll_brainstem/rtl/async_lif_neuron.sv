//-----------------------------------------------------------------------------
// Module: async_lif_neuron
// Desc  : The Creidyll Brainstem. A fully asynchronous Leaky Integrate-and-Fire 
//         (LIF) neuron. Zero idle power. No clock. Pure event-driven biology.
//-----------------------------------------------------------------------------
module async_lif_neuron #(
    parameter DATA_W = 16,
    parameter THRESHOLD = 20,
    parameter LEAK = 2
) (
    input  logic                  rst_n,
    
    input  logic                  req_in,
    output logic                  ack_out,
    input  logic [DATA_W-1:0]     data_in_t, data_in_f,
    
    output logic                  spike_req,
    input  logic                  spike_ack
);

    logic [DATA_W-1:0] state_t, state_f;

    // Deterministic initialization via initial block
    initial begin
        state_t = '0;
        state_f = '1;
    end

    // Combinational next-state logic (Integrate + Leak)
    logic [DATA_W-1:0] next_state_t;
    assign next_state_t = (state_t + data_in_t > LEAK) ? (state_t + data_in_t - LEAK) : '0;

    // Event-triggered state update (req_in replaces the clock)
    always @(posedge req_in or negedge rst_n) begin
        if (!rst_n) begin
            state_t <= '0; 
            state_f <= '1;
        end else begin
            state_t <= next_state_t; 
            state_f <= ~next_state_t;
        end
    end

    // Spike Generation (The "Fire")
    // FIX: Must be a token (pulse), not a level flag. Drops when req_in drops.
    assign spike_req = req_in & (state_t >= THRESHOLD);
    
    // Early acknowledge to upstream
    assign ack_out = req_in;

endmodule
