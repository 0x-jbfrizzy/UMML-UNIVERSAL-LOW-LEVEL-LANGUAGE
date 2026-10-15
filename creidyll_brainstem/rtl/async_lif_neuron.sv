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
    logic [DATA_W-1:0] next_state_t;

    initial begin
        state_t = '0;
        state_f = '1;
        spike_req = 1'b0; // FIX: Initialize output
    end

    assign next_state_t = (state_t + data_in_t > LEAK) ? (state_t + data_in_t - LEAK) : '0;
    assign ack_out = req_in;

    // FIX: Drive spike_req inside the always block to sync with state updates
    always @(posedge req_in or negedge rst_n) begin
        if (!rst_n) begin
            state_t <= '0; 
            state_f <= '1;
            spike_req <= 1'b0;
        end else begin
            state_t <= next_state_t; 
            state_f <= ~next_state_t;
            
            // Evaluate threshold on the NEXT state to avoid NBA race conditions
            if (next_state_t >= THRESHOLD) spike_req <= 1'b1;
            else spike_req <= 1'b0;
        end
    end

endmodule
