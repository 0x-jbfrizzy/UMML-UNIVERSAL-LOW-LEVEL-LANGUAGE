`timescale 1ns / 1ps
module umml_spatial_pid_node_tb;
    parameter DATA_W = 16, RES_W = 32, CLK = 10;
    logic clk, rst_n, valid_in, valid_out, wd_trip;
    logic [DATA_W-1:0] tgt_t, tgt_f, cur_t, cur_f;
    logic [RES_W-1:0] ctrl_t, ctrl_f;

    umml_spatial_pid_node #(.DATA_W(DATA_W), .RES_W(RES_W), .KP(2), .KI(1), .KD(1)) dut (
        .clk(clk), .rst_n(rst_n), .valid_in(valid_in), .valid_out(valid_out),
        .watchdog_trip(wd_trip), .target_t(tgt_t), .target_f(tgt_f),
        .current_t(cur_t), .current_f(cur_f), .control_t(ctrl_t), .control_f(ctrl_f)
    );

    initial clk = 0; always #(CLK/2) clk = ~clk;

    initial begin
        $dumpfile("pid_full.vcd"); $dumpvars(0, umml_spatial_pid_node_tb);
        
        $display("[TB] Test 1: Reset");
        rst_n = 0; valid_in = 0; 
        tgt_t = 100; tgt_f = ~100; cur_t = 90; cur_f = ~90;
        #(CLK*5);
        if (ctrl_t !== 0 || ctrl_f !== '1) $error("FAIL: Reset state invalid");
        else $display("[TB] PASS: Reset state");

        $display("[TB] Test 2: PID Step (1 cycle stimulus)");
        rst_n = 1; #(CLK*2);
        valid_in = 1;
        
        // Wait for the clock edge
        @(posedge clk); 
        // Wait 1ns for non-blocking assignments to settle
        #1; 
        
        if (ctrl_t == 40) $display("[TB] PASS: PID Sum = %0d", ctrl_t);
        else $error("FAIL: PID Sum = %0d (Exp 40)", ctrl_t);

        valid_in = 0;

        $display("[TB] Test 3: Watchdog");
        repeat(1030) @(posedge clk);
        if (wd_trip) $display("[TB] PASS: Watchdog tripped");
        else $error("FAIL: Watchdog did not trip");

        $display("[TB] Simulation Complete.");
        $finish;
    end
endmodule
