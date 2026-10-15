`timescale 1ns / 1ps
module tb_clicker;
    logic rst_n, player_click;
    logic reward_spike;

    umml_top dut (
        .rst_n(rst_n),
        .player_click(player_click)
    );

    assign reward_spike = dut.reward_spike;

    // Helper task to simulate a mouse click
    task click();
        player_click = 1; #10; player_click = 0; #10;
    endtask

    initial begin
        $dumpfile("clicker_sim.vcd"); $dumpvars(0, tb_clicker);
        
        $display("[GAME] Starting Async Clicker Game...");
        rst_n = 0; player_click = 0;
        #10; rst_n = 1; #10;
        $display("[GAME] Click the button 5 times to get a reward!");

        $display("[GAME] Click 1..."); click();
        $display("[GAME] Click 2..."); click();
        $display("[GAME] Click 3..."); click();
        $display("[GAME] Click 4..."); click();
        
        $display("[GAME] Click 5 (Threshold reached!)..."); 
        player_click = 1; #10; player_click = 0; #10;

        // Wait for the reward neuron to fire
        wait (reward_spike == 1);
        $display("[GAME] SUCCESS: REWARD UNLOCKED! The hardware accumulated the state perfectly.");
        
        #10;
        $display("[GAME] Game Over. English compiled to working game logic.");
        $finish;
    end
endmodule
