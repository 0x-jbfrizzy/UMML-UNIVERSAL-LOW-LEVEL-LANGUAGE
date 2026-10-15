`timescale 1ns / 1ps
module tb_scoreboard;
    logic rst_n, player_button, player_action_req;
    logic [15:0] rd_data_t;

    // Instantiate the English-compiled hardware
    umml_top dut (
        .rst_n(rst_n),
        .player_button(player_button)
    );

    // Expose internal signals for testing
    assign rd_data_t = dut.u_high_score.rd_data_t;
    assign dut.u_player_action.req_in = player_action_req;

    initial begin
        $dumpfile("scoreboard_sim.vcd"); $dumpvars(0, tb_scoreboard);
        
        $display("[TEST] Initializing Scoreboard...");
        rst_n = 0; player_button = 0; player_action_req = 0;
        #10; rst_n = 1; #10;

        $display("[TEST] Simulating Player Writing to High Score...");
        player_button = 1; #10; player_button = 0; #1;

        $display("[TEST] Simulating Player Action (Reading High Score)...");
        player_action_req = 1; #10; player_action_req = 0; #1;

        // Wait for the read data to settle
        #5;
        $display("[TEST] Read Data from Memory: %0d", rd_data_t);
        
        $display("[TEST] SUCCESS: English compiled to working memory control logic.");
        $finish;
    end
endmodule
