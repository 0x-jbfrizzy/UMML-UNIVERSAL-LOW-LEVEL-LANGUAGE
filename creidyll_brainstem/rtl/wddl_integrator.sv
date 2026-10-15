module wddl_integrator #(parameter DATA_W = 16) (
    input  logic clk, rst_n, valid_in,
    input  logic [DATA_W-1:0] in_t, in_f,
    output logic valid_out,
    output logic [DATA_W-1:0] out_t, out_f
);
    logic [DATA_W-1:0] acc_t;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_t <= '0; out_t <= '0; out_f <= '1; valid_out <= 1'b0;
        end else if (valid_in) begin
            acc_t <= acc_t + in_t;
            out_t <= acc_t + in_t;
            out_f <= ~(acc_t + in_t);
            valid_out <= 1'b1;
        end else begin
            out_t <= '0; out_f <= '1; valid_out <= 1'b0;
        end
    end
endmodule
