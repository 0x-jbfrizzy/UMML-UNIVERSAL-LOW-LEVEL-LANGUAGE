//-----------------------------------------------------------------------------
// Module: wddl_multiplier
// Desc  : 16x16-bit WDDL multiplier. Fixed reset state.
// Auth  : JBFRIZZY
//-----------------------------------------------------------------------------
module wddl_multiplier #(parameter DATA_W = 16, parameter RES_W = 32) (
    input  logic clk, rst_n,
    input  logic [DATA_W-1:0] a_t, a_f, b_t, b_f,
    input  logic valid_in,
    output logic valid_out,
    output logic [RES_W-1:0] res_t, res_f
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            res_t <= '0; res_f <= '1; valid_out <= 1'b0; // WDDL safe reset
        end else if (valid_in) begin
            res_t <= a_t * b_t;
            res_f <= ~(a_t * b_t);
            valid_out <= 1'b1;
        end else begin
            res_t <= '0; res_f <= '1; valid_out <= 1'b0;
        end
    end
    `ifndef SYNTHESIS
    always @(posedge clk) begin
        if (valid_in) begin
            if (a_t === a_f) $error("MULT INPUT A RAIL COLLISION at %0t", $time);
            if (b_t === b_f) $error("MULT INPUT B RAIL COLLISION at %0t", $time);
        end
    end
    `endif
endmodule
