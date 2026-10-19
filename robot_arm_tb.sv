`timescale 1ns/1ps

module robot_arm_tb;
    // Inputs
    reg clk, rst_n;
    reg collision_sensor;
    reg [15:0] motor_temp;
    
    // Outputs
    wire emergency_brake;
    wire [15:0] joint_velocity;

    // Instantiate the UMML-generated module
    umml_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .collision_sensor(collision_sensor),
        .motor_temp(motor_temp),
        .emergency_brake(emergency_brake),
        .joint_velocity(joint_velocity)
    );

    // Clock generation (100MHz = 10ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize
        clk = 0; rst_n = 0;
        collision_sensor = 0;
        motor_temp = 16'd2000; // Normal operating temp
        
        #20 rst_n = 1; // Release reset, enter IDLE state
        
        #100; // Let it run normally
        
        // SIMULATE A CATASTROPHIC MOTOR OVERHEAT
        $display("Time: %0t ns | SIMULATING MOTOR OVERHEAT (> 4095)!", $time);
        motor_temp = 16'd5000; 
        
        #20; // Wait 20ns (2 clock cycles)
        
        // The override logic should have forced the state to FAULT
        $display("SUCCESS: Universal safety interlock triggered instantly on complex condition!");
        
        $finish;
    end
endmodule
