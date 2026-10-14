//-----------------------------------------------------------------------------
// Module: spatial_pid_reg
// Desc  : Pipelined state register for PID Integral/Derivative terms.
//         Includes a spatial deadlock watchdog. If upstream fabric stalls,
//         it flushes the state to prevent integrator windup or motor runaway.
// Auth  : JBFRIZZY
//-----------------------------------------------------------------------------
module spatial_pid_reg #(
    parameter DATA_W      = 16,
    parameter TIMEOUT_CYC = 1024 // Max cycles before watchdog trips
) (
    input  logic                  clk,
    input  logic                  rst_n,
    
    input  logic                  valid_in,
    input  logic [DATA_W-1:0]     data_in_t,
    input  logic [DATA_W-1:0]     data_in_f,
    
    output logic                  valid_out,
    output logic [DATA_W-1:0]     data_out_t,
    output logic [DATA_W-1:0]     data_out_f,
    
    output logic                  watchdog_trip // Active high, kills ESCs
);

    logic [$clog2(TIMEOUT_CYC)-1:0] stall_counter;
    logic                           stall_detected;

    // Watchdog logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stall_counter <= '0;
            stall_detected <= 1'b0;
        end else if (valid_in) begin
            stall_counter <= '0;
            stall_detected <= 1'b0;
        end else begin
            if (stall_counter == TIMEOUT_CYC - 1) begin
                stall_detected <= 1'b1;
                // Counter saturates, doesn't roll over
            end else begin
                stall_counter <= stall_counter + 1;
            end
        end
    end

    // State register (Dual-rail)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_t <= '0;
            data_out_f <= '0;
            valid_out  <= 1'b0;
        end else if (stall_detected) begin
            // CRITICAL: Flush state to zero on deadlock. 
            // Prevents integrator windup if the IMU node hangs.
            data_out_t <= '0;
            data_out_f <= '0;
            valid_out  <= 1'b0;
        end else if (valid_in) begin
            data_out_t <= data_in_t;
            data_out_f <= data_in_f;
            valid_out  <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

    assign watchdog_trip = stall_detected;

endmodule
