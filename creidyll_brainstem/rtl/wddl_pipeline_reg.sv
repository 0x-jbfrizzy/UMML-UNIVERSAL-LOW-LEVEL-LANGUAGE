module wddl_pipeline_reg #(parameter DATA_W = 16) (
    input  logic clk, rst_n, valid_in,
    input  logic [DATA_W-1:0] data_t, data_f,
    output logic valid_out,
    output logic [DATA_W-1:0] data_out_t, data_out_f
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_t <= '0; data_out_f <= '1; valid_out <= 1'b0;
        end else if (valid_in) begin
            data_out_t <= data_t; data_out_f <= data_f; valid_out <= 1'b1;
        end else begin
            data_out_t <= '0; data_out_f <= '1; valid_out <= 1'b0;
        end
    end
endmodule
