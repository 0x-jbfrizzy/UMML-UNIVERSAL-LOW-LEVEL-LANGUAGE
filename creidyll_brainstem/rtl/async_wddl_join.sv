//-----------------------------------------------------------------------------
// Module: async_wddl_join
// Desc  : 2-input Join with Early Acknowledge and Decoupled Reset.
//-----------------------------------------------------------------------------
module async_wddl_join (
    input  logic rst_n,
    input  logic req_a, output logic ack_a,
    input  logic req_b, output logic ack_b,
    output logic req_out, input  logic ack_in
);

    logic [1:0] state, next_state;

    always_comb begin
        if (!rst_n) next_state = 2'd0;
        else case (state)
            2'd0: next_state = (req_a && req_b) ? 2'd1 : 2'd0;
            2'd1: next_state = ack_in ? 2'd2 : 2'd1;
            2'd2: next_state = (!req_a && !req_b) ? 2'd0 : 2'd2; // DECOUPLED RESET
            default: next_state = 2'd0;
        endcase
    end

    initial state = 2'd0;
    always begin #1 state = next_state; end

    assign req_out = (state == 2'd1 || state == 2'd2);
    assign ack_a = (state == 2'd1 || state == 2'd2); // EARLY ACKNOWLEDGE
    assign ack_b = (state == 2'd1 || state == 2'd2); // EARLY ACKNOWLEDGE

endmodule
