//-----------------------------------------------------------------------------
// Module: async_wddl_integrator
// Desc  : Event-triggered asynchronous accumulator. 
//         Uses req_in as the event trigger to update state. 
//         Deadlock-free token pass-through.
//-----------------------------------------------------------------------------
module async_wddl_integrator #(
    parameter DATA_W = 16
) (
    input  logic rst_n,
    
    // Upstream Input Token
    input  logic req_in,
    output logic ack_out,
    input  logic [DATA_W-1:0] data_in_t, data_in_f,
    
    // Downstream Output Token
    output logic req_out,
    input  logic ack_in,
    output logic [DATA_W-1:0] data_out_t, data_out_f
);

    logic [DATA_W-1:0] state_t, state_f;
    logic [DATA_W-1:0] sum_t, sum_f;

    // Combinational Adder
    assign sum_t = state_t + data_in_t;
    assign sum_f = ~(state_t + data_in_t);

    // Event-Triggered State Update (req_in replaces the global clock)
    always @(posedge req_in or negedge rst_n) begin
        if (!rst_n) begin
            state_t <= '0; 
            state_f <= '1;
        end else begin
            state_t <= sum_t; 
            state_f <= sum_f;
        end
    end

    // Deadlock-free Token Pass-Through
    assign req_out = req_in;
    assign ack_out = ack_in;
    assign data_out_t = sum_t;
    assign data_out_f = sum_f;

endmodule
