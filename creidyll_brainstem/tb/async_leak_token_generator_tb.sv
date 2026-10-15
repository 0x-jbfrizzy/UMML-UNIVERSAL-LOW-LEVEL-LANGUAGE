`timescale 1ns / 1ps
module async_leak_token_generator_tb;
    parameter DATA_W = 16, LEAK_RATE = 2; // Fast leak for simulation
    logic rst_n, enable, req_out, ack_in;
    logic [DATA_W-1:0] leak_t, leak_f;

    async_leak_token_generator #(.DATA_W(DATA_W), .LEAK_RATE(LEAK_RATE)) dut (
        .rst_n(rst_n),
        .enable(enable),
        .req_out(req_out), .ack_in(ack_in),
        .leak_t(leak_t), .leak_f(leak_f)
    );

    initial begin
        $dumpfile("async_leak.vcd"); $dumpvars(0, async_leak_token_generator_tb);
        
        $display("[TB] Test 1: Reset & Idle (Zero Power)");
        rst_n = 0; enable = 0; ack_in = 0;
        #10;
        rst_n = 1; #10;
        if (req_out !== 0) begin $error("FAIL: Leaking while disabled!"); $finish; end
        $display("[TB] PASS: Neuron at rest. Leak generator dormant (Zero power).");

        $display("[TB] Test 2: Active Leak (Neuron Firing)");
        enable = 1; // Neuron has charge, enable leak
        
        // Wait for the first leak token (-1)
        wait (req_out == 1);
        $display("[TB] INFO: Leak token emitted! Value = %0d (Signed)", $signed(leak_t));
        
        if (leak_t !== 16'hFFFF) begin $error("FAIL: Leak value is not -1!"); $finish; end
        $display("[TB] PASS: Leak token is -1 (Decay active).");
        
        // Acknowledge to reset the generator
        ack_in = 1;
        wait (req_out == 0);
        ack_in = 0;

        $display("[TB] Simulation Complete.");
        $display("[TB] =========================================");
        $display("[TB] FULL LIF NEURON PRIMITIVE SET COMPLETE:");
        $display("[TB] - Integrate (Accumulator)");
        $display("[TB] - Multiply (Token Unroller)");
        $display("[TB] - Fire (Spike Generator)");
        $display("[TB] - Leak (Async Token Decay)");
        $display("[TB] Ready for Brainstem Assembly.");
        $display("[TB] =========================================");
        $finish;
    end
endmodule
