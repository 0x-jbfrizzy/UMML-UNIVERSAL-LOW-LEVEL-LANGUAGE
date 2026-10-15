//-----------------------------------------------------------------------------
// Module: async_wddl_merge
// Desc  : Asynchronous Merge (OR logic). Passes a spike if EITHER input fires.
//-----------------------------------------------------------------------------
module async_wddl_merge (
    input  logic rst_n,
    input  logic req_a,
    input  logic req_b,
    output logic req_out,
    input  logic ack_in,
    output logic ack_a,
    output logic ack_b
);
    // For simple spike tokens, a wired-OR with basic handshake routing works.
    assign req_out = req_a | req_b;
    assign ack_a = req_a & ack_in;
    assign ack_b = req_b & ack_in;
endmodule
