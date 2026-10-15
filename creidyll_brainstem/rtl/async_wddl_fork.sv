//-----------------------------------------------------------------------------
// Module: async_wddl_fork
// Desc  : 2-way Fork with Early Acknowledge and Decoupled Reset.
//-----------------------------------------------------------------------------
module async_wddl_fork (
    input  logic rst_n,
    input  logic req_in, output logic ack_out,
    output logic req_out_a, input  logic ack_in_a,
    output logic req_out_b, input  logic ack_in_b
);

    logic [1:0] state, next_state;

    always_comb begin
        if (!rst_n) next_state = 2'd0;
        else case (state)
            2'd0: next_state = req_in ? 2'd1 : 2'd0;
            2'd1: next_state = (ack_in_a && ack_in_b) ? 2'd2 : 2'd1;
            2'd2: next_state = !req_in ? 2'd0 : 2'd2; // DECOUPLED RESET
            default: next_state = 2'd0;
        endcase
    end

    initial state = 2'd0;
    always begin #1 state = next_state; end

    assign req_out_a = (state == 2'd1 || state == 2'd2);
    assign req_out_b = (state == 2'd1 || state == 2'd2);
    assign ack_out = (state == 2'd1 || state == 2'd2); // EARLY ACKNOWLEDGE

endmodule
