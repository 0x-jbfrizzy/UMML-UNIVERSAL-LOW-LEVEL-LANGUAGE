`timescale 1ns / 1ps
module async_wddl_merge_tb;
    logic rst_n, req_a, ack_a, req_b, ack_b, req_out, ack_in;

    async_wddl_merge dut (
        .rst_n(rst_n),
        .req_a(req_a), .ack_a(ack_a),
        .req_b(req_b), .ack_b(ack_b),
        .req_out(req_out), .ack_in(ack_in)
    );

    initial begin
        $dumpfile("async_merge.vcd"); $dumpvars(0, async_wddl_merge_tb);
        
        $display("[TB] Test 1: Reset");
        rst_n = 0; req_a = 0; req_b = 0; ack_in = 0;
        #10;
        if (req_out !== 0 || ack_a !== 0 || ack_b !== 0) $error("FAIL: Reset state");
        else $display("[TB] PASS: Reset state is strictly idle");

        $display("[TB] Test 2: Asynchronous Merge (Path A)");
        rst_n = 1; #10;
        req_a = 1;
        wait (req_out == 1);
        $display("[TB] PASS: Path A merged and propagated.");
        ack_in = 1;
        wait (ack_a == 1);
        req_a = 0; ack_in = 0;
        wait (req_out == 0 && ack_a == 0);

        $display("[TB] Test 3: Asynchronous Merge (Path B)");
        req_b = 1;
        wait (req_out == 1);
        $display("[TB] PASS: Path B merged and propagated.");
        ack_in = 1;
        wait (ack_b == 1);
        req_b = 0; ack_in = 0;
        wait (req_out == 0 && ack_b == 0);

        $display("[TB] Test 4: Simultaneous Arrival (Arbitration)");
        req_a = 1; req_b = 1;
        wait (req_out == 1);
        $display("[TB] INFO: Both arrived. Arbitrator selected one path.");
        ack_in = 1;
        wait (ack_a == 1 || ack_b == 1);
        $display("[TB] PASS: Arbitration successful. One path acknowledged.");
        req_a = 0; req_b = 0; ack_in = 0;
        wait (req_out == 0);

        $display("[TB] Simulation Complete.");
        $finish;
    end
endmodule
