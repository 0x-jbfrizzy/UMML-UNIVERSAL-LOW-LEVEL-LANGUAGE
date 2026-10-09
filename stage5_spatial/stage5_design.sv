// ==========================================
// STAGE 5.4: DUAL-RAIL CRYPTO & CONSTANT TIME
// ==========================================
module dual_rail_encoder_32 (
    input wire clk, rst, input wire [31:0] single_rail_data, input wire data_valid,
    output reg [63:0] dual_rail_data, output reg data_ready
);
    integer i;
    integer k;
    reg [31:0] violation_check;
    
    always @(posedge clk) begin
        if (rst) begin dual_rail_data <= 64'd0; data_ready <= 1'b0; end 
        else begin
            data_ready <= 1'b0;
            if (data_valid) begin
                for (i = 0; i < 32; i = i + 1) begin
                    dual_rail_data[i] <= single_rail_data[i];
                    dual_rail_data[i + 32] <= ~single_rail_data[i];
                end
                data_ready <= 1'b1;
            end
        end
    end

    // ==========================================
    // RUNTIME VERIFICATION: WDDL INVARIANT CHECK
    // ==========================================
    // Property: In a valid Dual-Rail encoding, the true rail and false rail 
    // must NEVER be high at the same time for the same bit.
    always @(posedge clk) begin
        if (!rst && data_ready) begin
            violation_check = 32'd0;
            for (k = 0; k < 32; k = k + 1) begin
                if (dual_rail_data[k] && dual_rail_data[k + 32]) begin
                    violation_check[k] = 1'b1;
                end
            end
            if (violation_check !== 32'd0) begin
                $error("WDDL VIOLATION DETECTED: True and False rails are both high!");
                $display("Violation mask: %b", violation_check);
            end
        end
    end
endmodule