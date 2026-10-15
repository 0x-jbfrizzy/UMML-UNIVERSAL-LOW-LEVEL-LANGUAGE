`timescale 1ns / 1ps
module tb_alarm;
    logic rst_n, physical_motion, physical_door;
    logic siren_spike;

    umml_top dut (
        .rst_n(rst_n),
        .physical_motion(physical_motion),
        .physical_door(physical_door)
    );

    assign siren_spike = dut.siren_spike;

    initial begin
        $dumpfile("alarm_sim.vcd"); $dumpvars(0, tb_alarm);
        
        $display("[TEST] Initializing Alarm System...");
        rst_n = 0; physical_motion = 0; physical_door = 0;
        #10; rst_n = 1; #10;
        $display("[TEST] System Armed. Waiting for triggers...");

        $display("[TEST] Triggering Motion Sensor ONLY (10ns pulse)...");
        // FIX: Widen the pulse to 10ns so the async gates have time to propagate
        // and the 'wait' statement doesn't miss the edge.
        physical_motion = 1; #10; physical_motion = 0; #1;

        // With OR logic, the siren should fire and hold for the duration of the pulse!
        wait (siren_spike == 1);
        $display("[TEST] SUCCESS: Siren spiked! The OR merge worked perfectly.");
        
        #10;
        $display("[TEST] Simulation Complete. English compiled to working silicon.");
        $finish;
    end
endmodule
