//-----------------------------------------------------------------------------
// Module: umml_spatial_pid_node
// Desc  : Top-level spatial PID control node. 
//         Wires together the WDDL subtractor and state register.
//         Fully dual-rail encoded. No single-rail logic in the critical path.
// Auth  : JBFRIZZY
//-----------------------------------------------------------------------------
module umml_spatial_pid_node #(
    parameter DATA_W = 16
) (
    input  logic                  clk,
    input  logic                  rst_n,
    
    // Spatial handshake
    input  logic                  valid_in,
    output logic                  valid_out,
    output logic                  watchdog_trip,
    
    // Dual-rail Target (Setpoint)
    input  logic [DATA_W-1:0]     target_t,
    input  logic [DATA_W-1:0]     target_f,
    
    // Dual-rail Current (Feedback from IMU)
    input  logic [DATA_W-1:0]     current_t,
    input  logic [DATA_W-1:0]     current_f,
    
    // Dual-rail Control Output (To PWM/ESC driver)
    output logic [DATA_W-1:0]     control_t,
    output logic [DATA_W-1:0]     control_f
);

    // Internal dual-rail wires for routing between nodes
    logic [DATA_W-1:0] error_t;
    logic [DATA_W-1:0] error_f;
    logic              error_valid;

    // 1. ERROR CALCULATION: (Target - Current)
    wddl_subtractor #(
        .DATA_W(DATA_W)
    ) u_error_calc (
        .clk        (clk),
        .rst_n      (rst_n),
        .a_t        (target_t),
        .a_f        (target_f),
        .b_t        (current_t),
        .b_f        (current_f),
        .valid_in   (valid_in),
        .valid_out  (error_valid),
        .res_t      (error_t),
        .res_f      (error_f)
    );

    // 2. INTEGRAL STATE REGISTER (Holds the accumulated error)
    // Note: In a full PID, we would add a WDDL multiplier here for Kp/Ki gains.
    // For this foundational step, we route the error directly through the 
    // state register to prove the spatial pipeline and watchdog function.
    spatial_pid_reg #(
        .DATA_W      (DATA_W),
        .TIMEOUT_CYC (1024)
    ) u_i_term_reg (
        .clk         (clk),
        .rst_n       (rst_n),
        .valid_in    (error_valid),
        .data_in_t   (error_t),
        .data_in_f   (error_f),
        .valid_out   (valid_out),
        .data_out_t  (control_t),
        .data_out_f  (control_f),
        .watchdog_trip (watchdog_trip)
    );

endmodule
