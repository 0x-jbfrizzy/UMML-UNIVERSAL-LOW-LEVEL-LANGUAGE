//-----------------------------------------------------------------------------
// Module: async_wddl_join
// Desc  : Asynchronous 2-input Join Node using a Muller C-element.
//         Waits for both upstream request signals to assert before propagating.
//         Paradigm Shift: Clockless synchronization of independent data paths.
//-----------------------------------------------------------------------------
module async_wddl_join (
    input  logic rst_n,
    
    // Upstream A handshake
    input  logic req_a,
    output logic ack_a,
    
    // Upstream B handshake
    input  logic req_b,
    output logic ack_b,
    
    // Downstream handshake
    output logic req_out,
    input  logic ack_in
);

    // 2-Input Muller C-element (Gate-level implementation)
    // Holds state when inputs differ.
    logic c_state;
    assign c_state = (req_a & req_b) | (c_state & (req_a | req_b));

    // 4-Phase RTZ State Machine for the Join Node
    logic [1:0] state;
    logic [1:0] next_state;

    always_comb begin
        if (!rst_n) next_state = 2'd0;
        else case (state)
            // IDLE: Wait for both A and B to assert request
            2'd0: next_state = c_state ? 2'd1 : 2'd0;
            // EVAL: Both arrived. Assert downstream req. Wait for downstream ack.
            2'd1: next_state = ack_in ? 2'd2 : 2'd1;
            // ACK: Downstream consumed. Wait for A and B to drop request.
            2'd2: next_state = (!req_a && !req_b) ? 2'd3 : 2'd2;
            // RESET: A and B dropped. Wait for downstream to drop ack.
            2'd3: next_state = !ack_in ? 2'd0 : 2'd3;
            default: next_state = 2'd0;
        endcase
    end

    // Physical gate delay modeling
    initial state = 2'd0;
    always begin
        #1 state = next_state;
    end

    // Output logic (Strict RTZ)
    assign req_out = (state == 2'd1 || state == 2'd2);
    assign ack_a = (state == 2'd2 || state == 2'd3);
    assign ack_b = (state == 2'd2 || state == 2'd3);

endmodule
