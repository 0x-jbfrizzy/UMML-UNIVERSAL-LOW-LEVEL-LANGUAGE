//-----------------------------------------------------------------------------
// Module: wddl_async_latch
// Desc  : 4-phase RTZ register with Early Acknowledge and Decoupled Reset.
//         Breaks circular reset dependencies by resetting when upstream drops.
//-----------------------------------------------------------------------------
module wddl_async_latch #(
    parameter DATA_W = 16
) (
    input  logic                  rst_n,
    input  logic                  init,
    input  logic                  req_in,
    output logic                  ack_out,
    input  logic                  ack_in,
    output logic                  req_out,
    input  logic [DATA_W-1:0]     data_in_t, data_in_f,
    output logic [DATA_W-1:0]     data_out_t, data_out_f
);

    logic [1:0] state, next_state;
    logic [DATA_W-1:0] next_data_t, next_data_f;

    always_comb begin
        next_state = state;
        next_data_t = data_out_t;
        next_data_f = data_out_f;

        if (!rst_n) begin
            next_state = 2'd0; next_data_t = '0; next_data_f = '1;
        end else if (init) begin
            next_state = 2'd1; next_data_t = '0; next_data_f = '1;
        end else case (state)
            2'd0: begin // IDLE: Wait for input.
                if (req_in) begin
                    next_data_t = data_in_t; next_data_f = data_in_f;
                    next_state = 2'd1; 
                end
            end
            2'd1: begin // FULL: Token captured. Early ack sent. Wait for downstream ack.
                if (ack_in) next_state = 2'd2;
            end
            2'd2: begin // DRAIN: Downstream consumed. DECOUPLED RESET: Reset when upstream drops.
                if (!req_in) next_state = 2'd0;
            end
        endcase
    end

    initial begin state = 2'd0; data_out_t = '0; data_out_f = '1; end
    always begin #1 begin state = next_state; data_out_t = next_data_t; data_out_f = next_data_f; end end

    assign req_out = (state == 2'd1 || state == 2'd2);
    assign ack_out = (state == 2'd1 || state == 2'd2); // EARLY ACKNOWLEDGE

endmodule
