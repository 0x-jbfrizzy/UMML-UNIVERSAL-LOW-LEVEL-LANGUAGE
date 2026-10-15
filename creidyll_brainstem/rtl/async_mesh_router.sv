//-----------------------------------------------------------------------------
// Module: async_mesh_router
// Desc  : Asynchronous 2D Mesh Router. Routes spike tokens North, South, East, West.
//         Uses pure handshake pressure. Zero idle power. No clock.
//-----------------------------------------------------------------------------
module async_mesh_router (
    input  logic rst_n,
    
    // North Port
    input  logic n_req, output logic n_ack,
    // South Port
    input  logic s_req, output logic s_ack,
    // East Port
    input  logic e_req, output logic e_ack,
    // West Port
    input  logic w_req, output logic w_ack,
    
    // Local Compute Port (Connects to a Neuron/Memory)
    input  logic local_req, output logic local_ack
);

    // Simplified Routing Logic for Primitive Testing:
    // Local fires -> goes North. North fires -> goes Local.
    // (In a full mesh, we would add destination headers to the token).
    
    assign n_req = local_req;
    assign local_ack = n_ack;
    
    assign local_req = n_req; 
    assign n_ack = local_ack;

    // Unused ports tied off to prevent floating wires
    assign s_ack = s_req;
    assign e_ack = e_req;
    assign w_ack = w_req;

endmodule
