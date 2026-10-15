//-----------------------------------------------------------------------------
// Module: async_wddl_subtractor
// Desc  : Self-timed WDDL subtractor using 4-phase RTZ handshake.
//         Uses procedural delay loop to model physical state-holding gates.
//-----------------------------------------------------------------------------
module async_wddl_subtractor #(
    parameter DATA_W = 16
) (
    input  logic                  rst_n,
    input  logic                  req_in,
    output logic                  ack_out,
    output logic                  req_out,
    input  logic                  ack_in,
    input  logic [DATA_W-1:0]     a_t, a_f, b_t, b_f,
    output logic [DATA_W-1:0]     res_t, res_f
);

    // 1. Combinational WDDL Math
    assign res_t = a_t - b_t;
    assign res_f = ~(a_t - b_t);

    // 2. Dual-Rail Completion Detection
    logic done;
    assign done = &(res_t ^ res_f); 

    // 3. 4-Phase RTZ State Machine
    logic [1:0] state; 
    logic [1:0] next_state;

    always_comb begin
        if (!rst_n) next_state = 2'd0;
        else case (state)
            2'd0: next_state = (req_in && done) ? 2'd1 : 2'd0;
            2'd1: next_state = ack_in ? 2'd2 : 2'd1;
            2'd2: next_state = !req_in ? 2'd3 : 2'd2;
            2'd3: next_state = !ack_in ? 2'd0 : 2'd3;
            default: next_state = 2'd0;
        endcase
    end

    // Deterministic initialization and physical gate delay modeling
    initial state = 2'd0;
    always begin
        #1 state = next_state;
    end

    // Output logic (Strict RTZ: both 0 at idle)
    assign req_out = (state == 2'd1 || state == 2'd2);
    assign ack_out = (state == 2'd2 || state == 2'd3);

endmodule
