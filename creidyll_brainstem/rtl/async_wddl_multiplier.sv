//-----------------------------------------------------------------------------
// Module: async_wddl_multiplier
// Desc  : Asynchronous multiplier via token unrolling and integration.
//         O(1) hardware area. Zero idle power. Pure async dataflow.
//-----------------------------------------------------------------------------
module async_wddl_multiplier #(
    parameter DATA_W = 16
) (
    input  logic rst_n,
    
    input  logic req_in,
    output logic ack_out,
    input  logic [DATA_W-1:0] data_a_t, data_a_f, // Multiplicand
    input  logic [DATA_W-1:0] data_b_t, data_b_f, // Multiplier (count)
    
    output logic req_out,
    input  logic ack_in,
    output logic [DATA_W-1:0] result_t, result_f
);

    // Internal handshakes
    logic unroll_req, unroll_ack;
    logic integ_req, integ_ack;
    logic [DATA_W-1:0] unroll_out_t, unroll_out_f;
    logic [DATA_W-1:0] integ_out_t, integ_out_f;

    // 1. Unroller: Emits 'data_a' exactly 'data_b' times
    async_token_unroller #(.DATA_W(DATA_W)) u_unroll (
        .rst_n(rst_n),
        .req_in(req_in), .ack_out(ack_out),
        .val_a_t(data_a_t), .val_a_f(data_a_f),
        .val_b_t(data_b_t), .val_b_f(data_b_f),
        .req_out(unroll_req), .ack_in(unroll_ack),
        .out_a_t(unroll_out_t), .out_a_f(unroll_out_f)
    );

    // 2. Integrator: Accumulates the stream of 'data_a'
    async_wddl_integrator #(.DATA_W(DATA_W)) u_integ (
        .rst_n(rst_n),
        .req_in(unroll_req), .ack_out(unroll_ack),
        .data_in_t(unroll_out_t), .data_in_f(unroll_out_f),
        .req_out(integ_req), .ack_in(integ_ack),
        .data_out_t(integ_out_t), .data_out_f(integ_out_f)
    );

    // Pass the final result downstream
    assign req_out = integ_req;
    assign integ_ack = ack_in;
    assign result_t = integ_out_t;
    assign result_f = integ_out_f;

endmodule
