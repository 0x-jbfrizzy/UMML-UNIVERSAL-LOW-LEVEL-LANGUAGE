`timescale 1ns / 1ps
module tb_smart_building;
    logic rst_n, motion_sensor_a, motion_sensor_b;
    logic room_a_spike, room_b_spike;

    umml_top dut (
        .rst_n(rst_n),
        .motion_sensor_a(motion_sensor_a),
        .motion_sensor_b(motion_sensor_b)
    );

    assign room_a_spike = dut.room_a_light_spike;
    assign room_b_spike = dut.room_b_light_spike;

    initial begin
        $dumpfile("building_sim.vcd"); $dumpvars(0, tb_smart_building);
        
        $display("[SIM] Initializing Smart Building Network...");
        rst_n = 0; motion_sensor_a = 0; motion_sensor_b = 0;
        #10; rst_n = 1; #10;
        $display("[SIM] Network Armed. Waiting for motion...");

        $display("[SIM] Motion detected in Room A!");
        motion_sensor_a = 1; #10; motion_sensor_a = 0; #1;

        wait (room_a_spike == 1);
        $display("[SIM] INFO: Room A light spiked. Token entering hallway router...");

        wait (room_b_spike == 1);
        $display("[SIM] SUCCESS: Room B light spiked! The async mesh routing worked perfectly.");
        
        #10;
        $display("[SIM] Simulation Complete. English compiled to working distributed hardware.");
        $finish;
    end
endmodule
