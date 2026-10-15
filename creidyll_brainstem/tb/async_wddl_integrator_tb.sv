`timescale 1ns / 1ps
module async_wddl_integrator_tb;
    parameter DATA_W = 16;
    logic rst_n, req_in, ack_out, req_out, ack_in;
    logic [DATA_W-1:0] data_in_t, data_in_f, data_out_t, data_out_f;

    async_wddl_integrator #(.DATA_W(DATA_W)) dut (
        .rst_n(rst_n),
        .req_in(req_in), .ack_out(ack_out),
        .data_in_t(data_in_t), .data_in_f(data_in_f),
        .req_out(req_out), .ack_in(ack_in),
        .data_out_t(data_out_t), .data_out_f(data_out_f)
    );

    initial begin
        $dumpfile("async_integrator.vcd"); $dumpvars(0, async_wddl_integrator_tb);
        
        $display("[TB] Test 1: Reset");
        rst_n = 0; req_in = 0; ack_in = 0;
        data_in_t = 0; data_in_f = 0;
        #10;
        $display("[TB] PASS: Reset complete");

        $display("[TB] Test 2: Accumulate 10 + 20 + 30");
        rst_n = 1; #10;
        
        // Token 1: Add 10
        // Set data FIRST, then pulse req_in
        data_in_t = 16'd10; data_in_f = ~16'd10;
        #1; // Delta delay to stabilize data
        req_in = 1;
        wait (req_out == 1);
        if (data_out_t !== 16'd10) begin $error("FAIL: First sum = %0d (Expected 10)", data_out_t); $finish; end
        $display("[TB] PASS: Accumulated 10");
        ack_in = 1; wait (ack_out == 1);
        req_in = 0; ack_in = 0; wait (req_out == 0 && ack_out == 0);
        #1; // Delta delay to ensure state updates propagate

        // Token 2: Add 20 (Total = 30)
        data_in_t = 16'd20; data_in_f = ~16'd20;
        #1; // Delta delay to stabilize data
        req_in = 1;
        wait (req_out == 1);
        if (data_out_t !== 16'd30) begin $error("FAIL: Second sum = %0d (Expected 30)", data_out_t); $finish; end
        $display("[TB] PASS: Accumulated 30");
        ack_in = 1; wait (ack_out == 1);
        req_in = 0; ack_in = 0; wait (req_out == 0 && ack_out == 0);
        #1;

        // Token 3: Add 30 (Total = 60)
        data_in_t = 16'd30; data_in_f = ~16'd30;
        #1;
        req_in = 1;
        wait (req_out == 1);
        if (data_out_t !== 16'd60) begin $error("FAIL: Third sum = %0d (Expected 60)", data_out_t); $finish; end
        $display("[TB] PASS: Accumulated 60");
        ack_in = 1; wait (ack_out == 1);
        req_in = 0; ack_in = 0; wait (req_out == 0 && ack_out == 0);

        $display("[TB] Simulation Complete.");
        $finish;
    end
endmodule
