`timescale 1ns / 1ps
module wddl_async_latch_tb;
    parameter DATA_W = 16;
    logic rst_n, req_in, ack_out, ack_in, req_out;
    logic [DATA_W-1:0] data_in_t, data_in_f, data_out_t, data_out_f;

    wddl_async_latch #(.DATA_W(DATA_W)) dut (
        .rst_n(rst_n),
        .req_in(req_in), .ack_out(ack_out),
        .ack_in(ack_in), .req_out(req_out),
        .data_in_t(data_in_t), .data_in_f(data_in_f),
        .data_out_t(data_out_t), .data_out_f(data_out_f)
    );

    initial begin
        $dumpfile("async_latch.vcd"); $dumpvars(0, wddl_async_latch_tb);
        
        $display("[TB] Test 1: Reset");
        rst_n = 0; req_in = 0; ack_in = 0;
        data_in_t = 16'd40; data_in_f = ~16'd40;
        #10;
        if (req_out !== 0 || data_out_t !== 0) $error("FAIL: Reset state");
        else $display("[TB] PASS: Reset state");

        $display("[TB] Test 2: Asynchronous Data Ripple");
        rst_n = 1;
        #10;
        
        // Upstream pushes data
        data_in_t = 16'd40; data_in_f = ~16'd40;
        req_in = 1;
        
        // Wait for the latch to process and assert req_out
        wait (req_out == 1);
        $display("[TB] INFO: Latch captured data. req_out asserted. data_out_t = %0d", data_out_t);
        
        if (data_out_t == 16'd40 && data_out_f == ~16'd40) 
            $display("[TB] PASS: Data propagated asynchronously");
        else 
            $error("FAIL: Data mismatch");

        // Downstream acknowledges
        #5;
        ack_in = 1;
        
        // Wait for latch to drop req_out and assert ack_out
        wait (ack_out == 1);
        $display("[TB] PASS: Handshake completed. ack_out asserted.");
        
        // Return to idle (4-phase)
        req_in = 0;
        #5;
        ack_in = 0;
        #5;
        if (ack_out == 0 && req_out == 0) $display("[TB] PASS: Returned to idle state");

        $display("[TB] Simulation Complete.");
        $finish;
    end
endmodule
