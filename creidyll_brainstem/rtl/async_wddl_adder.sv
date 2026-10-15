//-----------------------------------------------------------------------------
// Module: async_wddl_adder
// Desc  : Purely combinational WDDL adder for async dataflow.
//         No handshake logic; ripples through at the speed of silicon.
//-----------------------------------------------------------------------------
module async_wddl_adder #(
    parameter DATA_W = 16
) (
    input  logic [DATA_W-1:0] a_t, a_f,
    input  logic [DATA_W-1:0] b_t, b_f,
    output logic [DATA_W-1:0] res_t, res_f
);
    assign res_t = a_t + b_t;
    assign res_f = ~(a_t + b_t);
endmodule
