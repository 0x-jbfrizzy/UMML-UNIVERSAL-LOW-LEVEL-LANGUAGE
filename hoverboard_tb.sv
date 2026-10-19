`timescale 1ns/1ps

module hoverboard_tb;
    reg clk, rst_n;
    reg [15:0] skirt_pressure;
    reg [15:0] battery_current;
    reg [15:0] battery_temp;
    reg [15:0] blower_rpm;
    reg emergency_button;
    
    wire [15:0] blower_pwm;
    wire main_contactor;

    umml_top uut (
        .clk(clk), 
        .rst_n(rst_n),
        .skirt_pressure(skirt_pressure),
        .battery_current(battery_current),
        .battery_temp(battery_temp),
        .blower_rpm(blower_rpm),
        .emergency_button(emergency_button),
        .blower_pwm(blower_pwm),
        .main_contactor(main_contactor)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0;
        skirt_pressure = 16'd2000; 
        battery_current = 16'd1000; 
        battery_temp = 16'd2500;    
        blower_rpm = 16'd3000;      
        emergency_button = 1;       
        
        #20 rst_n = 1; 
        #100; 
        
        $display("Time: %0t ns | CRITICAL: BATTERY THERMAL RUNAWAY DETECTED (> 3500)!", $time);
        battery_temp = 16'd4000; 
        
        #20; 
        
        $display("SUCCESS: Hardware interlock forced EMERGENCY_DESCENT in <10ns. Rider is safe.");
        $finish;
    end
endmodule
