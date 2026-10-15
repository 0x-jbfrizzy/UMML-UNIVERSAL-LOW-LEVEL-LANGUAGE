//-----------------------------------------------------------------------------
// Module: async_wddl_fork
// Desc  : Asynchronous 2-way Fork Node. 
//         Duplicates a request to two downstream paths and waits for BOTH 
//         acknowledgments before acknowledging upstream.
//         Paradigm Shift: Natural backpressure and data integrity in async fabric.
//-----------------------------------------------------------------------------
module async_wddl_fork (
    input  logic rst_n,
    
    // Upstream handshake
    input  logic req_in,
    output logic ack_out,
    
    // Downstream Path A
    output logic req_out_a,
    input  logic ack_in_a,
    
    // Downstream Path B
    output logic req_out_b,
    input  logic ack_in_b
);

    // 4-Phase RTZ State Machine
    logic [1:0] state;
    logic [1:0] next_state;

    always_comb begin
        if (!rst_n) next_state = 2'd0;
        else case (state)
            // IDLE: Wait for upstream data
            2'd0: next_state = req_in ? 2'd1 : 2'd0;
            // EVAL: Assert both downstream reqs. Wait for BOTH acks.
            2'd1: next_state = (ack_in_a && ack_in_b) ? 2'd2 : 2'd1;
            // ACK: Both consumed. Acknowledge upstream. Wait for upstream to drop req.
            2'd2: next_state = !req_in ? 2'd3 : 2'd2;
            // RESET: Wait for downstream to drop acks.
            2'd3: next_state = (!ack_in_a && !ack_in_b) ? 2'd0 : 2'd3;
            default: next_state = 2'd0;
        endcase
    end

    // Physical gate delay modeling
    initial state = 2'd0;
    always begin
        #1 state = next_state;
    end

    // Output logic (Strict RTZ)
    assign req_out_a = (state == 2'd1 || state == 2'd2);
    assign req_out_b = (state == 2'd1 || state == 2'd2);
    assign ack_out = (state == 2'd2 || state == 2'd3);

endmodule
