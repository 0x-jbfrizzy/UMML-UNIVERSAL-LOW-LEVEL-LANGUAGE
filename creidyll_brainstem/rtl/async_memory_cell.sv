//-----------------------------------------------------------------------------
// Module: async_memory_cell
// Desc  : Asynchronous Event-Driven Memory Cell. 
//         Zero idle power. No clock. Pure state storage triggered by tokens.
//-----------------------------------------------------------------------------
module async_memory_cell #(
    parameter DATA_W = 16
) (
    input  logic                  rst_n,
    
    // Write Port
    input  logic                  wr_req,
    output logic                  wr_ack,
    input  logic [DATA_W-1:0]     wr_data_t, wr_data_f,
    
    // Read Port
    input  logic                  rd_req,
    output logic                  rd_ack,
    output logic [DATA_W-1:0]     rd_data_t, rd_data_f
);

    logic [DATA_W-1:0] mem_t, mem_f;
    
    // Deterministic initialization
    initial begin
        mem_t = '0;
        mem_f = '1;
    end

    // Write Logic: State updates ONLY when a write token arrives
    always @(posedge wr_req or negedge rst_n) begin
        if (!rst_n) begin
            mem_t <= '0;
            mem_f <= '1;
        end else begin
            mem_t <= wr_data_t;
            mem_f <= wr_data_f;
        end
    end

    // Read Logic: Data is emitted ONLY when a read token arrives
    assign rd_data_t = rd_req ? mem_t : '0;
    assign rd_data_f = rd_req ? mem_f : '1;
    
    // Simple pulse acknowledgements
    assign wr_ack = wr_req;
    assign rd_ack = rd_req;

endmodule
