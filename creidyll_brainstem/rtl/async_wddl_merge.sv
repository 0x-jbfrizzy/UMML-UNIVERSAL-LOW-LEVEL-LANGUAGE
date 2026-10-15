//-----------------------------------------------------------------------------
// Module: async_wddl_merge
// Desc  : Asynchronous 2-input Merge Node with latched arbitration.
//         Fixes deadlock by remembering the granted path through all states.
//-----------------------------------------------------------------------------
module async_wddl_merge (
    input  logic rst_n,
    input  logic req_a,
    output logic ack_a,
    input  logic req_b,
    output logic ack_b,
    output logic req_out,
    input  logic ack_in
);

    logic [2:0] state, next_state;
    logic is_a, next_is_a; // Latched arbitration decision

    always_comb begin
        if (!rst_n) begin
            next_state = 3'd0;
            next_is_a = 1'b0;
        end else begin
            next_is_a = is_a; // Hold previous decision by default
            case (state)
                3'd0: begin // IDLE: Arbitrate
                    if (req_a && !req_b) next_is_a = 1'b1;
                    else if (req_b && !req_a) next_is_a = 1'b0;
                    else if (req_a && req_b) next_is_a = !is_a; // Toggle
                    
                    if ((next_is_a && req_a) || (!next_is_a && req_b))
                        next_state = 3'd1;
                    else
                        next_state = 3'd0;
                end
                3'd1: next_state = ack_in ? 3'd2 : 3'd1; // EVAL
                3'd2: next_state = (is_a ? !req_a : !req_b) ? 3'd3 : 3'd2; // ACK
                3'd3: next_state = !ack_in ? 3'd0 : 3'd3; // RESET
                default: next_state = 3'd0;
            endcase
        end
    end

    // Physical gate delay modeling
    initial state = 3'd0;
    initial is_a = 1'b0;
    always begin
        #1 begin
            state = next_state;
            is_a = next_is_a;
        end
    end

    // Output logic (Strict RTZ)
    assign req_out = (state == 3'd1 || state == 3'd2);
    assign ack_a = (state == 3'd2 && is_a) || (state == 3'd3 && is_a);
    assign ack_b = (state == 3'd2 && !is_a) || (state == 3'd3 && !is_a);

endmodule
