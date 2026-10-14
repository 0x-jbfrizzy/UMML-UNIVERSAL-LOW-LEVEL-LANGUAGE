`timescale 1ns / 1ps

module umml_spatial_pid_node_tb;

    parameter DATA_W = 16;
    parameter RES_W  = 32;
    parameter CLK_PERIOD = 10;

    logic clk, rst_n, valid_in, valid_out, watchdog_trip;
    logic [DATA_W-1:0] target_t, target_f, current_t, current_f;
    logic [RES_W-1:0]  control_t, control_f;

    umml_spatial_pid_node #(
        .DATA_W(DATA_W), .RES_W(RES_W),
        .KP_GAIN(16'd1), .KI_GAIN(16'd1)
    ) dut (
        .clk(clk), .rst_n(rst_n), .valid_in(valid_in),
        .valid_out(valid_out), .watchdog_trip(watchdog_trip),
        .target_t(target_t), .target_f(target_f),
        .current_t(current_t), .current_f(current_f),
        .control_t(control_t), .control_f(control_f)
    );

    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    logic [RES_W-1:0] last_valid_control_t;
    always @(posedge clk) begin
        if (valid_out) begin
            last_valid_control_t <= control_t;
            $display("[TB] Valid Output at time %0t: control_t = %0d", $time, control_t);
        end
    end

    initial begin
        $dumpfile("umml_spatial_pid_node.vcd");
        $dumpvars(0, umml_spatial_pid_node_tb);

        rst_n = 0; valid_in = 0;
        target_t = 0; target_f = 0; current_t = 0; current_f = 0;

        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        // Error = 10. Drive valid for exactly 4 cycles.
        target_t = 100; current_t = 90;
        valid_in = 1;

        repeat (4) @(posedge clk);
        
        valid_in = 0;
        
        // Wait for pipeline flush
        repeat (5) @(posedge clk);

        if (last_valid_control_t == 32'd40) begin
            $display("[TB] PASS: PI Accumulation verified. Final control_t = %0d", last_valid_control_t);
        end else begin
            $error("[TB] FAIL: Final control_t = %0d (Expected 40)", last_valid_control_t);
        end

        $display("[TB] Simulation Complete.");
        $finish;
    end
endmodule
