`timescale 1ns / 1ps
module async_wddl_subtractor_tb;
    parameter DATA_W = 16;
    logic rst_n, req_in, ack_out, req_out, ack_in;
    logic [DATA_W-1:0] a_t, a_f, b_t, b_f, res_t, res_f;

    async_wddl_subtractor #(.DATA_W(DATA_W)) dut (
        .rst_n(rst_n),
        .req_in(req_in), .ack_out(ack_out),
        .req_out(req_out), .ack_in(ack_in),
        .a_t(a_t), .a_f(a_f), .b_t(b_t), .b_f(b_f),
        .res_t(res_t), .res_f(res_f)
    );

    initial begin
        $dumpfile("async_sub.vcd"); $dumpvars(0, async_wddl_subtractor_tb);
        
        $display("[TB] Test 1: Reset (Idle State)");
        rst_n = 0; req_in = 0; ack_in = 0;
        a_t = 0; a_f = 0; b_t = 0; b_f = 0;
        #10;
        if (req_out !== 0 || ack_out !== 0) $error("FAIL: Reset state not idle");
        else $display("[TB] PASS: Reset state is strictly idle (req=0, ack=0)");

        $display("[TB] Test 2: 4-Phase RTZ Handshake");
        rst_n = 1; #10;
        
        a_t = 16'd100; a_f = ~16'd100;
        b_t = 16'd60;  b_f = ~16'd60;
        
        // Phase 1: Upstream asserts Request
        req_in = 1;
        wait (req_out == 1);
        $display("[TB] PASS: Phase 1 - Eval complete. req_out asserted.");
        
        if (res_t !== 16'd40) $error("FAIL: Math error. res_t = %0d", res_t);

        // Phase 2: Downstream asserts Acknowledge
        ack_in = 1;
        wait (ack_out == 1);
        $display("[TB] PASS: Phase 2 - Downstream acknowledged.");

        // Phase 3: Upstream drops Request (Return to Zero)
        req_in = 0;
        wait (req_out == 0);
        $display("[TB] PASS: Phase 3 - Request dropped.");

        // Phase 4: Downstream drops Acknowledge (Return to Zero)
        ack_in = 0;
        wait (ack_out == 0);
        $display("[TB] PASS: Phase 4 - Acknowledge dropped. System idle.");

        $display("[TB] Simulation Complete.");
        $finish;
    end
endmodule
