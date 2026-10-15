`timescale 1ns / 1ps
module async_wddl_differentiator_tb;
    parameter DATA_W = 16, DELAY_STAGES = 4;
    logic rst_n, req_in, ack_out, req_out, ack_in;
    logic [DATA_W-1:0] data_in_t, data_in_f, diff_t, diff_f;

    async_wddl_differentiator #(.DATA_W(DATA_W), .DELAY_STAGES(DELAY_STAGES)) dut (
        .rst_n(rst_n),
        .req_in(req_in), .ack_out(ack_out),
        .data_in_t(data_in_t), .data_in_f(data_in_f),
        .req_out(req_out), .ack_in(ack_in),
        .diff_t(diff_t), .diff_f(diff_f)
    );

    initial begin
        $dumpfile("async_diff.vcd"); $dumpvars(0, async_wddl_differentiator_tb);
        
        $display("[TB] Test 1: Reset");
        rst_n = 0; req_in = 0; ack_in = 0;
        data_in_t = 0; data_in_f = 0;
        #10;
        $display("[TB] PASS: Reset complete");

        $display("[TB] Test 2: Temporal Differentiation (50 -> 30 = -20)");
        rst_n = 1; #10;
        
        // Fill the delay line with 50
        repeat(DELAY_STAGES) begin
            data_in_t = 16'd50; data_in_f = ~16'd50;
            req_in = 1;
            wait (ack_out == 1);
            req_in = 0;
            wait (ack_out == 0);
            #1;
        end
        
        // Now input 30 (should compute 30 - 50 = -20)
        data_in_t = 16'd30; data_in_f = ~16'd30;
        req_in = 1;
        wait (req_out == 1);
        
        // -20 in 16-bit signed is 16'hFFEC
        if (diff_t !== 16'hFFEC) begin 
            $error("FAIL: Difference = %0d (Expected -20)", $signed(diff_t)); 
            $finish; 
        end
        $display("[TB] PASS: Computed difference = -20 (Stateless differentiation works!)");
        
        ack_in = 1;
        wait (ack_out == 1);
        req_in = 0; ack_in = 0;

        $display("[TB] Simulation Complete.");
        $finish;
    end
endmodule
