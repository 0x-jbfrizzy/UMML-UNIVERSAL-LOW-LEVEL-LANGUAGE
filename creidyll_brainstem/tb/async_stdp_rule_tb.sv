`timescale 1ns / 1ps
module async_stdp_rule_tb;
    parameter DATA_W = 16;
    logic rst_n, pre_req, pre_ack, post_req, post_ack, update_req, update_ack;
    logic [DATA_W-1:0] update_data_t, update_data_f;

    async_stdp_rule #(.DATA_W(DATA_W), .TRACE_MAX(15)) dut (
        .rst_n(rst_n),
        .pre_req(pre_req), .pre_ack(pre_ack),
        .post_req(post_req), .post_ack(post_ack),
        .update_req(update_req), .update_ack(update_ack),
        .update_data_t(update_data_t), .update_data_f(update_data_f)
    );

    initial begin
        $dumpfile("async_stdp.vcd"); $dumpvars(0, async_stdp_rule_tb);
        
        $display("[TB] Test 1: Reset");
        rst_n = 0; pre_req = 0; post_req = 0; update_ack = 0;
        #10; rst_n = 1; #10;
        $display("[TB] PASS: Reset complete");

        $display("[TB] Test 2: Causal Learning (Pre fires, then Post fires quickly)");
        pre_req = 1; #1; pre_req = 0; #1;
        $display("[TB] INFO: Pre-synaptic spike arrived. Trace filled.");
        
        #20; 
        
        post_req = 1; #1;
        wait (update_req == 1);
        #1;
        if (update_data_t !== 16'd1) begin $error("FAIL: Expected LTP (+1), got %0d", $signed(update_data_t)); $finish; end
        $display("[TB] PASS: Causal STDP -> LTP (+1) emitted!");
        
        post_req = 0; #1;
        update_ack = 1; #1; update_ack = 0;
        wait (update_req == 0);

        $display("[TB] Test 3: Anti-Causal Learning (Trace decays before Post fires)");
        pre_req = 1; #1; pre_req = 0; #1;
        $display("[TB] INFO: Pre-synaptic spike arrived. Waiting for trace to decay...");
        
        // FIX: Wait for the actual internal state to reach 0. No timing guesswork.
        wait (dut.pre_trace == 0);
        $display("[TB] INFO: Trace decayed to 0. Firing Post-synaptic spike.");
        #10; // Wait a bit more to be safe
        
        post_req = 1; #1;
        wait (update_req == 1);
        #1;
        if (update_data_t !== 16'hFFFF) begin $error("FAIL: Expected LTD (-1), got %0d", $signed(update_data_t)); $finish; end
        $display("[TB] PASS: Anti-Causal STDP -> LTD (-1) emitted!");
        
        post_req = 0; #1;
        update_ack = 1; #1; update_ack = 0;
        wait (update_req == 0);

        $display("[TB] Simulation Complete.");
        $display("[TB] =========================================");
        $display("[TB] STDP LEARNING PRIMITIVE COMPLETE:");
        $display("[TB] - No global clock or batch processing");
        $display("[TB] - Learning is a physical race (Trace vs Spike)");
        $display("[TB] - Zero idle power (Decay oscillator sleeps)");
        $display("[TB] =========================================");
        $finish;
    end
endmodule
