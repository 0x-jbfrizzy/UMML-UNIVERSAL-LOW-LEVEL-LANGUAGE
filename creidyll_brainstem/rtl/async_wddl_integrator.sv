//-----------------------------------------------------------------------------
// Module: async_wddl_integrator
// Desc  : Event-triggered accumulator with transparent pass-through handshake.
//-----------------------------------------------------------------------------
module async_wddl_integrator #(
    parameter DATA_W = 16
) (
    input  logic rst_n,
    
    input  logic req_in,
    output logic ack_out,
    input  logic [DATA_W-1:0] data_in_t, data_in_f,
    
    output logic req_out,
    input  logic ack_in,
    output logic [DATA_W-1:0] data_out_t, data_out_f
);

    logic [DATA_W-1:0] state_t, state_f;
    logic [DATA_W-1:0] sum_t, sum_f;

    // Combinational adder
    assign sum_t = state_t + data_in_t;
    assign sum_f = ~(state_t + data_in_t);

    // Event-triggered state update (req_in replaces the clock)
    always @(posedge req_in or negedge rst_n) begin
        if (!rst_n) begin
            state_t <= '0; 
            state_f <= '1;
        end else begin
            state_t <= sum_t; 
            state_f <= sum_f;
        end
    end

    // Transparent handshake: req_out follows req_in
    assign req_out = req_in;
    assign ack_out = req_in; // Early acknowledge to upstream
    
    // Output the accumulated state
    assign data_out_t = state_t;
    assign data_out_f = state_f;

endmodule
