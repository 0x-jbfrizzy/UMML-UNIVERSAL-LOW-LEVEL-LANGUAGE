//-----------------------------------------------------------------------------
// Module: async_mesh_router
// Desc  : Asynchronous Linear Pipeline Router. 
//         Routes tokens from West to East, or injects Local tokens.
//         Uses pure handshake pressure. Zero idle power. No clock.
//-----------------------------------------------------------------------------
module async_mesh_router (
    input  logic rst_n,
    
    // West Port (Incoming from previous node)
    input  logic west_req, output logic west_ack,
    
    // East Port (Outgoing to next node)
    output logic east_req, input  logic east_ack,
    
    // Local Port (Injecting from a local neuron/memory)
    input  logic local_req, output logic local_ack
);

    // Async Merge Logic: East fires if West OR Local has a token.
    assign east_req = west_req | local_req;
    
    // Back-pressure Logic: 
    // West is acknowledged ONLY if East is ready AND Local is NOT injecting.
    assign west_ack = east_ack & ~local_req;
    
    // Local is acknowledged ONLY if East is ready AND West is NOT injecting.
    assign local_ack = east_ack & ~west_req;

endmodule
