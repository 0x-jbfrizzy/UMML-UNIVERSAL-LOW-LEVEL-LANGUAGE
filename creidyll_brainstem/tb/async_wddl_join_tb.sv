`timescale 1ns / 1ps
module async_wddl_join_tb;
    logic rst_n, req_a, ack_a, req_b, ack_b, req_out, ack_in;

    async_wddl_join dut (
        .rst_n(rst_n),
        .req_a(req_a), .ack_a(ack_a),
        .req_b(req_b), .ack_b(ack_b),
        .req_out(req_out), .ack_in(ack_in)
    );

    initial begin
        $dumpfile("async_join.vcd"); $dumpvars(0, async_wddl_join_tb);
        
        $display("[TB] Test 1: Reset");
        rst_n = 0; req_a = 0; req_b = 0; ack_in = 0;
        #10;
        if (req_out !== 0 || ack_a !== 0 || ack_b !== 0) $error("FAIL: Reset state");
        else $display("[TB] PASS: Reset state is strictly idle");

        $display("[TB] Test 2: Asynchronous Synchronization");
        rst_n = 1; #10;
        
        // Path A arrives first
        req_a = 1;
        #5;
        if (req_out !== 0) $error("FAIL: Premature req_out (waiting for B)");
        else $display("[TB] INFO: Path A arrived. Join node holding state.");

        // Path B arrives second -> Triggers C-element
        req_b = 1;
        wait (req_out == 1);
        $display("[TB] PASS: Path B arrived. C-element fired. req_out asserted.");

        // Downstream acknowledges
        ack_in = 1;
        wait (ack_a == 1 && ack_b == 1);
        $display("[TB] PASS: Downstream acknowledged. Upstream A and B acknowledged.");

        // Return to idle (4-phase)
        req_a = 0; req_b = 0;
        wait (req_out == 0);
        ack_in = 0;
        wait (ack_a == 0 && ack_b == 0);
        $display("[TB] PASS: System returned to zero-power idle state.");

        $display("[TB] Simulation Complete.");
        $finish;
    end
endmodule
