//-----------------------------------------------------------------------------
// Module: async_wddl_differentiator
// Desc  : STATELESS differentiator using asynchronous delay lines.
//         No explicit state storage. "Memory" is emergent from physical 
//         propagation delay through a chain of async latches.
//         Paradigm Shift: Temporal differentiation through spatial propagation.
//-----------------------------------------------------------------------------
module async_wddl_differentiator #(
    parameter DATA_W = 16,
    parameter DELAY_STAGES = 4  // Configurable temporal window
) (
    input  logic rst_n,
    
    // Input token
    input  logic req_in,
    output logic ack_out,
    input  logic [DATA_W-1:0] data_in_t, data_in_f,
    
    // Output token (difference)
    output logic req_out,
    input  logic ack_in,
    output logic [DATA_W-1:0] diff_t, diff_f
);

    // Chain of delay latches (the "delay line")
    logic [DELAY_STAGES:0][DATA_W-1:0] stage_t, stage_f;
    logic [DELAY_STAGES:0] stage_req, stage_ack;
    
    // Stage 0 is the "current" input
    assign stage_t[0] = data_in_t;
    assign stage_f[0] = data_in_f;
    assign stage_req[0] = req_in;
    assign ack_out = stage_ack[0];
    
    // Chain of delay latches
    genvar i;
    generate
        for (i = 0; i < DELAY_STAGES; i = i + 1) begin : delay_chain
            wddl_async_latch #(.DATA_W(DATA_W)) u_delay (
                .rst_n(rst_n),
                .init(1'b0),
                .req_in(stage_req[i]),
                .ack_out(stage_ack[i]),
                .ack_in(stage_ack[i+1]),
                .req_out(stage_req[i+1]),
                .data_in_t(stage_t[i]),
                .data_in_f(stage_f[i]),
                .data_out_t(stage_t[i+1]),
                .data_out_f(stage_f[i+1])
            );
        end
    endgenerate
    
    // Compute difference between current (stage 0) and delayed (stage DELAY_STAGES)
    assign diff_t = stage_t[0] - stage_t[DELAY_STAGES];
    assign diff_f = ~(stage_t[0] - stage_t[DELAY_STAGES]);
    
    // Output request fires when both current and delayed are valid
    assign req_out = stage_req[0] && stage_req[DELAY_STAGES];

endmodule
