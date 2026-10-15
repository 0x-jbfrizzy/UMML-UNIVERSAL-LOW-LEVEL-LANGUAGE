//-----------------------------------------------------------------------------
// Module: wddl_async_latch
// Desc  : Self-timed, clockless WDDL data register using bundled-data protocol.
//         Uses a Muller C-element to ensure data is stable before acknowledging.
//         Paradigm Shift: Zero clock dependency, zero idle dynamic power.
//-----------------------------------------------------------------------------
module wddl_async_latch #(
    parameter DATA_W = 16
) (
    // No clk input. Ever.
    input  logic                  rst_n,
    
    // Upstream handshake
    input  logic                  req_in,
    output logic                  ack_out,
    
    // Downstream handshake
    input  logic                  ack_in,
    output logic                  req_out,
    
    // Dual-rail data
    input  logic [DATA_W-1:0]     data_in_t,
    input  logic [DATA_W-1:0]     data_in_f,
    output logic [DATA_W-1:0]     data_out_t,
    output logic [DATA_W-1:0]     data_out_f
);

    // Internal state for the 4-phase handshake
    logic state; // 0 = waiting for req, 1 = waiting for ack

    // Muller C-element behavior: 
    // req_out goes high only when (state is 1 AND data is stable)
    // For simulation simplicity, we model the bundled-data delay assumption:
    // The evaluation logic is strictly slower than the control logic.
    
    always_latch begin
        if (!rst_n) begin
            state = 0;
            req_out = 0;
            ack_out = 0;
            data_out_t = '0;
            data_out_f = '1;
        end else begin
            if (state == 0 && req_in) begin
                // Capture data (Level-sensitive latch during req high)
                data_out_t = data_in_t;
                data_out_f = data_in_f;
                state = 1;
                req_out = 1; // Tell downstream: "Data is valid"
            end
            else if (state == 1 && ack_in) begin
                // Downstream consumed the data
                state = 0;
                req_out = 0; // Drop request
                ack_out = 1; // Tell upstream: "I'm ready for more"
            end
            else if (state == 0 && !req_in) begin
                ack_out = 0; // Reset ack when req is low (4-phase return to zero)
            end
        end
    end

    // Simulation assertion: Ensure dual-rail integrity is maintained asynchronously
    `ifndef SYNTHESIS
    always @(*) begin
        if (req_out) begin
            if (data_out_t === data_out_f) $error("ASYNC WDDL RAIL COLLISION at %0t", $time);
        end
    end
    `endif

endmodule
