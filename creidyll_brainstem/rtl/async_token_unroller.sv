//-----------------------------------------------------------------------------
// Module: async_token_unroller
// Desc  : Asynchronous control loop for repeated addition (multiplication).
//         Takes value A and count B. Emits A exactly B times to downstream.
//         Paradigm Shift: Multiplication as orchestrated dataflow, not a circuit.
//-----------------------------------------------------------------------------
module async_token_unroller #(
    parameter DATA_W = 16
) (
    input  logic rst_n,
    
    // Upstream: Receive A and B
    input  logic req_in,
    output logic ack_out,
    input  logic [DATA_W-1:0] val_a_t, val_a_f,
    input  logic [DATA_W-1:0] val_b_t, val_b_f,
    
    // Downstream: Emit A repeatedly
    output logic req_out,
    input  logic ack_in,
    output logic [DATA_W-1:0] out_a_t, out_a_f
);

    logic [DATA_W-1:0] reg_a_t, reg_a_f;
    logic [DATA_W-1:0] reg_b_t, reg_b_f;
    logic [DATA_W-1:0] next_reg_a_t, next_reg_b_t;
    
    logic [2:0] state, next_state;

    // State Machine: 0=IDLE, 1=EMIT, 2=WAIT_ACK, 3=DECREMENT_CHECK
    always_comb begin
        next_state = state;
        next_reg_a_t = reg_a_t;
        next_reg_b_t = reg_b_t;

        if (!rst_n) begin
            next_state = 3'd0;
            next_reg_a_t = '0; next_reg_b_t = '0;
        end else begin
            case (state)
                3'd0: begin // IDLE: Wait for upstream
                    if (req_in) begin
                        next_reg_a_t = val_a_t;
                        next_reg_b_t = val_b_t;
                        next_state = 3'd1;
                    end
                end
                3'd1: begin // EMIT: Assert request to downstream
                    next_state = 3'd2;
                end
                3'd2: begin // WAIT_ACK: Wait for downstream to consume
                    if (ack_in) next_state = 3'd3;
                end
                3'd3: begin // DECREMENT_CHECK
                    if (reg_b_t == 1) begin
                        next_state = 3'd4; // Done
                    end else begin
                        next_reg_b_t = reg_b_t - 1;
                        next_state = 3'd1; // Loop back and emit again
                    end
                end
                3'd4: begin // DONE: Acknowledge upstream
                    if (!req_in) next_state = 3'd0;
                end
            endcase
        end
    end

    // Deterministic initialization and physical delay modeling
    initial begin 
        state = 3'd0; 
        reg_a_t = '0; reg_a_f = '1; 
        reg_b_t = '0; reg_b_f = '1; 
    end

    always begin
        #1 begin
            state = next_state;
            reg_a_t = next_reg_a_t;
            reg_a_f = ~next_reg_a_t;
            reg_b_t = next_reg_b_t;
            reg_b_f = ~next_reg_b_t;
        end
    end

    // Output assignments
    assign req_out = (state == 3'd1 || state == 3'd2 || state == 3'd3);
    assign ack_out = (state == 3'd4);
    assign out_a_t = reg_a_t;
    assign out_a_f = reg_a_f;

endmodule
