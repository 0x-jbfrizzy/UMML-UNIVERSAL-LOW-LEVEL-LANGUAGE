//-----------------------------------------------------------------------------
// Module: umml_spatial_pid_node
// Desc  : Single-cycle WDDL PID controller. 
//         Separates combinational math from sequential state to fix NBA bugs.
//-----------------------------------------------------------------------------
module umml_spatial_pid_node #(
    parameter DATA_W = 16,
    parameter RES_W  = 32,
    parameter KP = 16'd2, KI = 16'd1, KD = 16'd1,
    parameter WD_TIMEOUT = 1024
) (
    input  logic clk, rst_n, valid_in,
    output logic valid_out, watchdog_trip,
    input  logic [DATA_W-1:0] target_t, target_f, current_t, current_f,
    output logic [RES_W-1:0] control_t, control_f
);

    // State registers
    logic [DATA_W-1:0] prev_err_t, prev_err_f;
    logic [RES_W-1:0]  i_acc_t, i_acc_f;
    logic [$clog2(WD_TIMEOUT)-1:0] wd_cnt;

    // Combinational signals
    logic [DATA_W-1:0] err_t, err_f;
    logic [RES_W-1:0]  p_t, p_f, d_t, d_f, sum_t, sum_f;
    logic [RES_W-1:0]  i_next_t, i_next_f;

    // --- Combinational Math ---
    assign err_t = target_t - current_t;
    assign err_f = ~(target_t - current_t);

    assign p_t = err_t * KP;
    assign p_f = ~(err_t * KP);

    assign i_next_t = i_acc_t + (err_t * KI);
    assign i_next_f = ~(i_acc_t + (err_t * KI));

    assign d_t = (err_t - prev_err_t) * KD;
    assign d_f = ~((err_t - prev_err_t) * KD);

    assign sum_t = p_t + i_next_t + d_t;
    assign sum_f = ~(p_t + i_next_t + d_t);

    // --- Sequential State Update ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_err_t <= '0; prev_err_f <= '1;
            i_acc_t <= '0; i_acc_f <= '1;
            control_t <= '0; control_f <= '1;
            valid_out <= 1'b0;
            wd_cnt <= '0;
            watchdog_trip <= 1'b0;
        end else if (valid_in) begin
            prev_err_t <= err_t;
            prev_err_f <= err_f;
            i_acc_t <= i_next_t;
            i_acc_f <= i_next_f;
            control_t <= sum_t;
            control_f <= sum_f;
            valid_out <= 1'b1;
            wd_cnt <= '0;
            watchdog_trip <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            if (wd_cnt == WD_TIMEOUT - 1) watchdog_trip <= 1'b1;
            else wd_cnt <= wd_cnt + 1;
        end
    end
endmodule
