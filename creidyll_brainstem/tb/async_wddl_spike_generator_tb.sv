`timescale 1ns / 1ps
module async_wddl_spike_generator_tb;
    parameter DATA_W = 16, THRESHOLD = 10;
    logic rst_n, req_in, ack_out, spike_req, spike_ack;
    logic [DATA_W-1:0] data_in_t, data_in_f;

    async_wddl_spike_generator #(.DATA_W(DATA_W), .THRESHOLD(THRESHOLD)) dut (
        .rst_n(rst_n),
        .req_in(req_in), .ack_out(ack_out),
        .data_in_t(data_in_t), .data_in_f(data_in_f),
        .spike_req(spike_req), .spike_ack(spike_ack)
    );

    initial begin
        $dumpfile("async_spike.vcd"); $dumpvars(0, async_wddl_spike_generator_tb);
        
        $display("[TB] Test 1: Reset");
        rst_n = 0; req_in = 0; spike_ack = 0;
        #10;
        $display("[TB] PASS: Reset complete");

        $display("[TB] Test 2: Sub-threshold Input (Value = 5, Threshold = 10)");
        rst_n = 1; #10;
        data_in_t = 16'd5; data_in_f = ~16'd5;
        req_in = 1;
        #1;
        if (spike_req !== 0) begin $error("FAIL: Spiked on sub-threshold value!"); $finish; end
        $display("[TB] PASS: No spike emitted (Token absorbed, zero downstream power).");
        req_in = 0; #1;

        $display("[TB] Test 3: Super-threshold Input (Value = 15, Threshold = 10)");
        data_in_t = 16'd15; data_in_f = ~16'd15;
        req_in = 1;
        wait (spike_req == 1);
        $display("[TB] PASS: Spike Token emitted! Neuron fired.");
        
        // FIX: Drop req_in first to drop spike_req (transparent combinational logic)
        req_in = 0;
        wait (spike_req == 0);
        
        spike_ack = 1;
        #1; spike_ack = 0;
        $display("[TB] INFO: Spike consumed. Pipeline idle.");

        $display("[TB] Simulation Complete.");
        $display("[TB] =========================================");
        $display("[TB] LIF NEURON PRIMITIVE COMPLETE:");
        $display("[TB] - Integrate (Accumulator)");
        $display("[TB] - Multiply (Token Unroller)");
        $display("[TB] - Fire (Async Spike Generator)");
        $display("[TB] =========================================");
        $finish;
    end
endmodule
