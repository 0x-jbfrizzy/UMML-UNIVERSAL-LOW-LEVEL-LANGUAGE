//-----------------------------------------------------------------------------
// Module: umml_spatial_pid_node
// Desc  : Spatial PI controller (Proportional + Integral).
//         Derivative term omitted for initial stability testing.
// Auth  : JBFRIZZY
//-----------------------------------------------------------------------------
module umml_spatial_pid_node #(
    parameter DATA_W = 16,
    parameter RES_W  = 32,
    parameter KP_GAIN = 16'd1,
    parameter KI_GAIN = 16'd1
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  valid_in,
    output logic                  valid_out,
    output logic                  watchdog_trip,
    
    input  logic [DATA_W-1:0]     target_t, target_f,
    input  logic [DATA_W-1:0]     current_t, current_f,
    
    output logic [RES_W-1:0]      control_t, control_f
);

    logic [DATA_W-1:0] error_t, error_f;
    logic              error_valid;
    
    logic [RES_W-1:0]  p_term_t, p_term_f, i_scaled_t, i_scaled_f;
    logic              p_valid, i_scaled_valid;
    
    logic [RES_W-1:0]  i_accum_t, i_accum_f;
    logic              i_accum_valid;

    // 1. Error Calculation
    wddl_subtractor #(.DATA_W(DATA_W)) u_error_calc (
        .clk(clk), .rst_n(rst_n),
        .a_t(target_t), .a_f(target_f), .b_t(current_t), .b_f(current_f),
        .valid_in(valid_in), .valid_out(error_valid),
        .res_t(error_t), .res_f(error_f)
    );

    // 2. Proportional Gain
    wddl_multiplier #(.DATA_W(DATA_W), .RES_W(RES_W)) u_p_gain (
        .clk(clk), .rst_n(rst_n),
        .a_t(error_t), .a_f(error_f), .b_t(KP_GAIN), .b_f(~KP_GAIN),
        .valid_in(error_valid), .valid_out(p_valid),
        .res_t(p_term_t), .res_f(p_term_f)
    );

    // 3. Integral Scaling
    wddl_multiplier #(.DATA_W(DATA_W), .RES_W(RES_W)) u_i_gain (
        .clk(clk), .rst_n(rst_n),
        .a_t(error_t), .a_f(error_f), .b_t(KI_GAIN), .b_f(~KI_GAIN),
        .valid_in(error_valid), .valid_out(i_scaled_valid),
        .res_t(i_scaled_t), .res_f(i_scaled_f)
    );

    // 4. Integral Accumulation (Feedback Loop)
    // Adds current scaled error to the previous accumulated state.
    wddl_adder #(.DATA_W(RES_W)) u_i_accum_add (
        .clk(clk), .rst_n(rst_n),
        .a_t(i_accum_t), .a_f(i_accum_f), 
        .b_t(i_scaled_t), .b_f(i_scaled_f),
        .valid_in(i_scaled_valid), .valid_out(i_accum_valid),
        .res_t(i_accum_t), .res_f(i_accum_f) // Feedback loop
    );

    // 5. Final Summation (P + I)
    wddl_adder #(.DATA_W(RES_W)) u_final_sum (
        .clk(clk), .rst_n(rst_n),
        .a_t(p_term_t), .a_f(p_term_f),
        .b_t(i_accum_t), .b_f(i_accum_f),
        .valid_in(p_valid), .valid_out(valid_out), // Align with P-term timing
        .res_t(control_t), .res_f(control_f)
    );

    // Watchdog placeholder (tied low for now, requires separate timer module)
    assign watchdog_trip = 1'b0;

endmodule
