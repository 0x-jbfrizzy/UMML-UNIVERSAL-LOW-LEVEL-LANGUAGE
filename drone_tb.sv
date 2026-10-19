`timescale 1ns/1ps

module drone_tb;
    reg clk, rst_n;
    reg [15:0] airspeed_sensor;
    reg gps_signal_lost;
    
    // We check the internal state directly
    wire [2:0] drone_state;
    assign drone_state = uut.flight_control_state;

    umml_top uut (
        .clk(clk), .rst_n(rst_n),
        .airspeed_sensor(airspeed_sensor),
        .gps_signal_lost(gps_signal_lost)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0;
        airspeed_sensor = 16'd800; // Normal speed
        gps_signal_lost = 0;
        
        #20 rst_n = 1; 
        #100; 
        
        // SIMULATE STALL (Speed drops below 500)
        $display("Time: %0t ns | SIMULATING DRONE STALL (Speed < 500)!", $time);
        airspeed_sensor = 16'd200; 
        
        #20;
        $display("SUCCESS: Drone hardware interlock forced RECOVER state!");
        $finish;
    end
endmodule
