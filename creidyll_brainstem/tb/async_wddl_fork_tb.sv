`timescale 1ns / 1ps
module async_wddl_fork_tb;
    logic rst_n, req_in, ack_out, req_out_a, ack_in_a, req_out_b, ack_in_b;

    async_wddl_fork dut (
        .rst_n(rst_n),
        .req_in(req_in), .ack_out(ack_out),
        .req_out_a(req_out_a), .ack_in_a(ack_in_a),
        .req_out_b(req_out_b), .ack_in_b(ack_in_b)
    );

    initial begin
        $dumpfile("async_fork.vcd"); $dumpvars(0, async_wddl_fork_tb);
        
        $display("[TB] Test 1: Reset");
        rst_n = 0; req_in = 0; ack_in_a = 0; ack_in_b = 0;
        #10;
        if (req_out_a !== 0 || req_out_b !== 0 || ack_out !== 0) $error("FAIL: Reset state");
        else $display("[TB] PASS: Reset state is strictly idle");

        $display("[TB] Test 2: Asynchronous Fan-Out and Backpressure");
        rst_n = 1; #10;
        
        // Upstream pushes data
        req_in = 1;
        wait (req_out_a == 1 && req_out_b == 1);
        $display("[TB] PASS: Data fanned out to Path A and Path B.");

        // Simulate Backpressure: Path A is fast, Path B is slow
        ack_in_a = 1;
        #5;
        if (ack_out !== 0) $error("FAIL: Premature ack_out (waiting for slow Path B)");
        else $display("[TB] INFO: Path A acknowledged. Fork holding state (Backpressure active).");

        // Path B finally acknowledges
        ack_in_b = 1;
        wait (ack_out == 1);
        $display("[TB] PASS: Path B acknowledged. Fork acknowledged upstream.");

        // Return to idle (4-phase)
        req_in = 0;
        wait (req_out_a == 0 && req_out_b == 0);
        ack_in_a = 0; ack_in_b = 0;
        wait (ack_out == 0);
        $display("[TB] PASS: System returned to zero-power idle state.");

        $display("[TB] Simulation Complete.");
        $finish;
    end
endmodule
