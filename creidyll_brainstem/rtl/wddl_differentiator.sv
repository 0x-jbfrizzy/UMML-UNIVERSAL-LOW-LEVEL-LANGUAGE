module wddl_differentiator #(parameter DATA_W = 16) (
    input  logic clk, rst_n, valid_in,
    input  logic [DATA_W-1:0] current_t, current_f,
    output logic valid_out,
    output logic [DATA_W-1:0] diff_t, diff_f
);
    logic [DATA_W-1:0] prev_t, prev_f;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_t <= '0; prev_f <= '1;
            diff_t <= '0; diff_f <= '1;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            prev_t <= current_t;
            prev_f <= current_f;
            diff_t <= current_t - prev_t;
            diff_f <= ~(current_t - prev_t);
            valid_out <= 1'b1;
        end else begin
            diff_t <= '0; diff_f <= '1;
            valid_out <= 1'b0;
        end
    end
endmodule
