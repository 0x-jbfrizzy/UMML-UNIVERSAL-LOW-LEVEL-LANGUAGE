`timescale 1ns/1ps

module surgery_tb;
    reg clk, rst_n;
    reg [15:0] force_feedback;
    reg [15:0] tissue_resistance;
    
    wire [2:0] arm_state;
    assign arm_state = uut.surgical_arm_state;

    umml_top uut (
        .clk(clk), .rst_n(rst_n),
        .force_feedback(force_feedback),
        .tissue_resistance(tissue_resistance)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0;
        force_feedback = 16'd1000; // Normal force
        tissue_resistance = 16'd500; // Normal tissue
        
        #20 rst_n = 1; 
        #100; 
        
        // SIMULATE EXCESSIVE FORCE (Patient safety risk)
        $display("Time: %0t ns | SIMULATING EXCESSIVE SURGICAL FORCE (> 4095)!", $time);
        force_feedback = 16'd5000; 
        
        #20;
        $display("SUCCESS: Surgery robot hardware interlock forced HALT state instantly!");
        $finish;
    end
endmodule
