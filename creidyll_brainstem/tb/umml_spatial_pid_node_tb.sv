`timescale 1ns / 1ps

module umml_spatial_pid_node_tb;

    parameter DATA_W = 16;
    parameter RES_W  = 32;
    parameter CLK_PERIOD = 10;

    logic clk, rst_n, valid_in, valid_out, watchdog_trip;
    logic [DATA_W-1:0] target_t, target_f, current_t, current_f;
    logic [RES_W-1:0]  control_t, control_f;

    umml_spatial_pid_node #(
        .DATA_W(DATA_W),
        .RES_W(RES_W),
        .KP_GAIN(16'd2)
    ) dut (
        .clk(clk), .rst_n(rst_n), .valid_in(valid_in),
        .valid_out(valid_out), .watchdog_trip(watchdog_trip),
        .target_t(target_t), .target_f(target_f),
        .current_t(current_t), .current_f(current_f),
        .control_t(control_t), .control_f(control_f)
    );

    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        $dumpfile("umml_spatial_pid_node.vcd");
        $dumpvars(0, umml_spatial_pid_node_tb);

        rst_n = 0; valid_in = 0;
        target_t = 0; target_f = 0; current_t = 0; current_f = 0;

        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        // TEST: Target=100, Current=60 -> Error=40. Kp=2. Expected Output=80.
        $display("[TB] Starting Test Case 1: Subtraction + Multiplication");
        
        target_t  = 16'd100; target_f = 16'd0;
        current_t = 16'd60;  current_f = 16'd0;
        valid_in  = 1;

        // Subtractor (1 cycle) + Multiplier (1 cycle) + Reg (1 cycle) = 3 cycles
        #(CLK_PERIOD * 4);

        if (valid_out) begin
            if (control_t == 32'd80 && control_f == ~32'd80) begin
                $display("[TB] PASS: control_t = %0d, control_f = %0d (WDDL Complementary)", control_t, control_f);
            end else begin
                $error("[TB] FAIL: control_t = %0d, control_f = %0d (Expected 80 and ~80)", control_t, control_f);
            end
        end else begin
            $error("[TB] FAIL: valid_out did not assert");
        end

        $display("[TB] Simulation Complete.");
        $finish;
    end
endmodule
