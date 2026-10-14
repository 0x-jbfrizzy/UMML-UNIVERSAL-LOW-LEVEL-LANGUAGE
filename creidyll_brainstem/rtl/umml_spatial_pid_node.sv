//-----------------------------------------------------------------------------
// Module: umml_spatial_pid_node
// Desc  : Top-level spatial PID control node. 
//         Wires WDDL subtractor, multiplier (Kp gain), and state register.
// Auth  : JBFRIZZY
//-----------------------------------------------------------------------------
module umml_spatial_pid_node #(
    parameter DATA_W = 16,
    parameter RES_W  = 32,
    parameter KP_GAIN = 16'd2  // Example Kp constant
) (
    input  logic                  clk,
    input  logic                  rst_n,
    
    input  logic                  valid_in,
    output logic                  valid_out,
    output logic                  watchdog_trip,
    
    input  logic [DATA_W-1:0]     target_t,
    input  logic [DATA_W-1:0]     target_f,
    input  logic [DATA_W-1:0]     current_t,
    input  logic [DATA_W-1:0]     current_f,
    
    output logic [RES_W-1:0]      control_t,
    output logic [RES_W-1:0]      control_f
);

    logic [DATA_W-1:0] error_t, error_f;
    logic              error_valid;
    
    logic [RES_W-1:0]  p_term_t, p_term_f;
    logic              p_valid;

    // 1. Error Calculation (Target - Current)
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

    // 2. Proportional Gain (Error * Kp)
    wddl_multiplier #(
        .DATA_W(DATA_W),
        .RES_W (RES_W)
    ) u_p_gain (
        .clk        (clk),
        .rst_n      (rst_n),
        .a_t        (error_t),
        .a_f        (error_f),
        .b_t        (KP_GAIN),
        .b_f        (~KP_GAIN), // Kp constant dual-rail encoding
        .valid_in   (error_valid),
        .valid_out  (p_valid),
        .res_t      (p_term_t),
        .res_f      (p_term_f)
    );

    // 3. Integral State Register (Holds P term for now, ready for I-term expansion)
    spatial_pid_reg #(
        .DATA_W      (RES_W),
        .TIMEOUT_CYC (1024)
    ) u_i_term_reg (
        .clk           (clk),
        .rst_n         (rst_n),
        .valid_in      (p_valid),
        .data_in_t     (p_term_t),
        .data_in_f     (p_term_f),
        .valid_out     (valid_out),
        .data_out_t    (control_t),
        .data_out_f    (control_f),
        .watchdog_trip (watchdog_trip)
    );

endmodule
