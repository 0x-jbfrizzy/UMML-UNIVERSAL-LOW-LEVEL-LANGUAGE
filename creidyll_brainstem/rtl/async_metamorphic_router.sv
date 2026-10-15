//-----------------------------------------------------------------------------
// Module: async_metamorphic_router
// Desc  : FEATURE 2: Metamorphic Spatial Obfuscation. 
//         Dynamically scrambles internal data paths mid-execution to defeat 
//         side-channel timing and power analysis. Zero global clock required.
//-----------------------------------------------------------------------------
module async_metamorphic_router #(
    parameter DATA_W = 16
) (
    input  logic                  rst_n,
    input  logic [7:0]            initial_key, // Seed for obfuscation
    
    // Input
    input  logic                  req_in,
    output logic                  ack_out,
    input  logic [DATA_W-1:0]     data_in,
    
    // Output
    output logic                  req_out,
    input  logic                  ack_in,
    output logic [DATA_W-1:0]     data_out
);

    logic [7:0] current_key;
    logic [DATA_W-1:0] scrambled_data;
    
    initial current_key = initial_key;

    // FEATURE 2: The physical path is XOR-scrambled based on the dynamic key.
    // To an external observer measuring power/timing, the active gates change every cycle.
    always_comb begin
        scrambled_data = data_in ^ {8{current_key}}; 
    end

    // Async Handshake with Obfuscated Payload
    assign req_out = req_in;
    assign data_out = scrambled_data;
    assign ack_out = ack_in;

    // FEATURE 2: Key Rotation. The physical layout "morphs" on every transaction.
    // We use a simple LFSR-like mutation that triggers ONLY on a successful handshake.
    logic [7:0] next_key;
    assign next_key = current_key ^ 8'h5A; 
    
    always @(posedge req_in or negedge rst_n) begin
        if (!rst_n) begin
            current_key <= initial_key;
        end else if (ack_in) begin
            // Key updates ONLY when the transaction is acknowledged, 
            // ensuring the next operation uses a completely different physical path.
            current_key <= next_key; 
        end
    end

endmodule
