//-----------------------------------------------------------------------------
// Module: umml_spatial_pid_node_tb
// Desc  : Testbench for the spatial PID node. 
//         Verifies dual-rail WDDL subtraction and spatial handshake propagation.
// Auth  : JBFRIZZY
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps

module umml_spatial_pid_node_tb;

    parameter DATA_W = 16;
    parameter CLK_PERIOD = 10; // 100 MHz

    // Testbench signals
    logic clk;
    logic rst_n;
    logic valid_in;
    logic [DATA_W-1:0] target_t, target_f;
    logic [DATA_W-1:0] current_t, current_f;
    
    logic valid_out;
    logic [DATA_W-1:0] control_t, control_f;
    logic watchdog_trip;

    // Instantiate the DUT (Device Under Test)
    umml_spatial_pid_node #(
        .DATA_W(DATA_W)
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .valid_in       (valid_in),
        .valid_out      (valid_out),
        .watchdog_trip  (watchdog_trip),
        .target_t       (target_t),
        .target_f       (target_f),
        .current_t      (current_t),
        .current_f      (current_f),
        .control_t      (control_t),
        .control_f      (control_f)
    );

    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // VCD Dump for waveform viewing
    initial begin
        $dumpfile("umml_spatial_pid_node.vcd");
        $dumpvars(0, umml_spatial_pid_node_tb);
    end

    // Stimulus and checking
    initial begin
        // Initialize
        rst_n = 0;
        valid_in = 0;
        target_t = 0; target_f = 0;
        current_t = 0; current_f = 0;

        // Wait a few cycles, then release reset
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        // --- TEST CASE 1: Basic Subtraction ---
        // Target = 100 (0x0064), Current = 60 (0x003C)
        // Expected Error (Control Output) = 40 (0x0028)
        
        $display("[TB] Starting Test Case 1: Basic Subtraction");
        
        // Drive dual-rail inputs (True rail gets value, False rail gets 0)
        target_t  = 16'd100; target_f = 16'd0;
        current_t = 16'd60;  current_f = 16'd0;
        valid_in  = 1;

        // Wait for the spatial pipeline to propagate (Subtractor + Register = 2 cycles)
        #(CLK_PERIOD * 3);

        // Check results
        if (valid_out) begin
            // In WDDL, the False rail holds the bitwise inverse of the True rail
            if (control_t == 16'd40 && control_f == ~16'd40) begin
                $display("[TB] PASS: control_t = %0d, control_f = %0d (WDDL Complementary)", control_t, control_f);
            end else begin
                $error("[TB] FAIL: control_t = %0d, control_f = %0d (Expected 40 and ~40)", control_t, control_f);
            end
        end else begin
            $error("[TB] FAIL: valid_out did not assert");
        end

        // --- TEST CASE 2: Watchdog Timeout Simulation ---
        $display("[TB] Starting Test Case 2: Watchdog Timeout");
        valid_in = 0; // Stop feeding data
        
        // Fast-forward time to trigger the 1024-cycle timeout
        #(CLK_PERIOD * 1030);

        if (watchdog_trip) begin
            $display("[TB] PASS: Watchdog tripped after stall (watchdog_trip = 1)");
        end else begin
            $error("[TB] FAIL: Watchdog did not trip");
        end

        $display("[TB] Simulation Complete.");
        $finish;
    end

endmodule
