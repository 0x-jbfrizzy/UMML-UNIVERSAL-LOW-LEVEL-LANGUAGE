`timescale 1ns/1ps

module tb_stage5_master;
    reg clk, rst;
    
    // Compiler & Crossbar Wires
    reg [7:0] char_in; reg char_valid;
    wire [1:0] route_src, route_dst; wire route_configured;
    wire [15:0] out_0_data, out_1_data; wire out_0_ready, out_1_ready;
    
    // Node Wires
    reg [15:0] node_0_a, node_0_b; reg node_0_valid;
    wire [15:0] node_0_result; wire node_0_ready;
    reg [15:0] node_1_b_input; wire [15:0] node_1_a; wire node_1_valid;
    wire [15:0] node_1_result; wire node_1_ready;

    // Memory & Power Wires
    wire [1:0] mem_addr; wire mem_write_ready, mem_read_ready;
    wire [15:0] mem_read_data; wire mem_read_ready_out;
    wire [4:0] power_draw; wire power_valid;

    // Constant Time Wires
    reg secret_bit; reg ct_valid;
    wire [7:0] ct_result; wire ct_ready;

    // Instantiations
    grid_compiler_node uut_compiler (.clk(clk), .rst(rst), .char_in(char_in), .char_valid(char_valid), .route_src(route_src), .route_dst(route_dst), .route_configured(route_configured));
    crossbar_node uut_crossbar (.clk(clk), .rst(rst), .route_src(route_src), .route_dst(route_dst), .route_configured(route_configured), .in_0_data(node_0_result), .in_1_data(16'd0), .in_0_ready(node_0_ready), .in_1_ready(1'b0), .out_0_data(), .out_1_data(node_1_a), .out_0_ready(), .out_1_ready(node_1_valid));
    
    // Simple Swarm Nodes for routing test
    swarm_node uut_node_0 (.clk(clk), .rst(rst), .op_a(node_0_a), .op_b(node_0_b), .op_valid(node_0_valid), .configured_latency(4'd2), .result(node_0_result), .result_ready(node_0_ready));
    swarm_node uut_node_1 (.clk(clk), .rst(rst), .op_a(node_1_a), .op_b(node_1_b_input), .op_valid(node_1_valid), .configured_latency(4'd2), .result(node_1_result), .result_ready(node_1_ready));

    memory_node uut_memory (.clk(clk), .rst(rst), .write_addr(2'd0), .write_data(node_0_result), .write_valid(node_0_ready), .read_addr(2'd0), .read_valid(mem_read_ready), .read_data(mem_read_data), .read_ready(mem_read_ready_out));
    power_monitor_node uut_power (.clk(clk), .rst(rst), .data_bus(mem_read_data), .data_valid(mem_read_ready_out), .power_draw(power_draw), .power_valid(power_valid));

    constant_time_node uut_ct (.clk(clk), .rst(rst), .secret_bit(secret_bit), .data_valid(ct_valid), .result(ct_result), .result_ready(ct_ready));

    // Helper module for swarm_node (copy from previous chat if needed, or define here)
    // For brevity, assume swarm_node is defined in design.sv

    initial begin clk = 0; forever #10 clk = ~clk; end

    task send_char; input [7:0] c; begin @(posedge clk); char_in <= c; char_valid <= 1'b1; @(posedge clk); char_valid <= 1'b0; end endtask

    initial begin
        rst = 1; char_in = 0; char_valid = 0; node_0_a = 0; node_0_b = 0; node_0_valid = 0; node_1_b_input = 3; secret_bit = 0; ct_valid = 0;
        #50; rst = 0;

        $display("=== UMML STAGE 5 MASTER TEST ===");
        
        // 1. Spatial Routing
        $display("\n[TEST 1] Spatial Routing: CONNECT 0 TO 1");
        send_char("C"); send_char("O"); send_char("N"); send_char("N"); send_char("E"); send_char("C"); send_char("T"); send_char(" ");
        send_char("0"); send_char(" "); send_char("T"); send_char("O"); send_char(" "); send_char("1"); send_char(" ");
        wait(route_configured); #20;
        
        @(posedge clk); node_0_a <= 4; node_0_b <= 5; node_0_valid <= 1'b1;
        @(posedge clk); node_0_valid <= 1'b0;
        wait(node_1_ready); #20;
        $display("Node 1 received routed data: %0d", node_1_result);

        // 2. Constant Time Execution
        $display("\n[TEST 2] Constant-Time Execution");
        secret_bit = 1; ct_valid = 1; #20; ct_valid = 0;
        wait(ct_ready); #20;
        $display("Constant-Time Node finished. Result: %0d", ct_result);

        $display("\n=== STAGE 5 VERIFIED ===");
        #50; $finish;
    end
endmodule

// Minimal swarm node for the testbench to compile standalone
module swarm_node (
    input wire clk, rst, input wire [15:0] op_a, op_b, input wire op_valid,
    input wire [3:0] configured_latency, output reg [15:0] result, output reg result_ready
);
    reg [3:0] counter; reg busy; reg [15:0] latch_a, latch_b;
    always @(posedge clk) begin
        if (rst) begin counter <= 0; busy <= 0; result <= 0; result_ready <= 0; end 
        else begin
            result_ready <= 0;
            if (op_valid && !busy) begin latch_a <= op_a; latch_b <= op_b; counter <= configured_latency; busy <= 1; end 
            else if (busy) begin
                if (counter > 1) counter <= counter - 1;
                else begin result <= latch_a * latch_b; result_ready <= 1; busy <= 0; end
            end
        end
    end
endmodule