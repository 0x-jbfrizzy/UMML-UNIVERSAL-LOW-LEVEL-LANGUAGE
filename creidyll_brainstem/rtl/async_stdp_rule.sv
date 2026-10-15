//-----------------------------------------------------------------------------
// Module: async_stdp_rule
// Desc  : Asynchronous Spike-Timing Dependent Plasticity (STDP) engine.
//         Uses a free-running clock with gated decay for robust simulation.
//-----------------------------------------------------------------------------
module async_stdp_rule #(
    parameter DATA_W = 16,
    parameter TRACE_MAX = 15
) (
    input  logic                  rst_n,
    input  logic                  pre_req,
    output logic                  pre_ack,
    input  logic                  post_req,
    output logic                  post_ack,
    output logic                  update_req,
    input  logic                  update_ack,
    output logic [DATA_W-1:0]     update_data_t, update_data_f
);

    logic [DATA_W-1:0] pre_trace;
    logic [DATA_W-1:0] update_data;
    logic update_pending;
    logic clk;
    
    initial begin
        pre_trace = 0;
        update_data = 0;
        update_pending = 0;
        clk = 0;
    end

    // Free-running clock (50MHz = 20ns period)
    always #10 clk = ~clk;

    // Single-driver state machine
    always @(posedge clk or posedge pre_req or posedge post_req or posedge update_ack or negedge rst_n) begin
        if (!rst_n) begin
            pre_trace <= 0;
            update_pending <= 0;
        end else if (update_ack) begin
            update_pending <= 0; 
        end else if (pre_req) begin
            pre_trace <= TRACE_MAX;
        end else if (post_req) begin
            update_pending <= 1;
            if (pre_trace > 0) begin
                update_data <= 16'd1; // LTP
                pre_trace <= 0;
            end else begin
                update_data <= 16'hFFFF; // LTD
            end
        end else begin
            // Gated decay: only decrement if trace > 0
            if (pre_trace > 0) pre_trace <= pre_trace - 1;
        end
    end

    assign update_req = update_pending;
    assign update_data_t = update_data;
    assign update_data_f = ~update_data;
    
    assign pre_ack = pre_req;
    assign post_ack = post_req;

endmodule
