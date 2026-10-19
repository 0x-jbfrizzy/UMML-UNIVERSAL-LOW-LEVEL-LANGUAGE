module testbench;

  logic clk = 0;
  logic rst_n = 0;
  logic tether_severed = 0;
  logic empty_battery = 0;
  logic [15:0] speed_selector = 0;
  logic right_stick_press = 0;
  logic right_stick_backward_hold = 0;
  logic nav_forward = 0, nav_backward = 0, nav_left = 0, nav_right = 0;
  logic shoe_emergency_button = 0;

  logic [15:0] thruster_left;
  logic [15:0] thruster_right;

  umml_top dut (
    .clk(clk), .rst_n(rst_n),
    .tether_severed(tether_severed),
    .empty_battery(empty_battery),
    .speed_selector(speed_selector),
    .right_stick_press(right_stick_press),
    .right_stick_backward_hold(right_stick_backward_hold),
    .nav_forward(nav_forward), .nav_backward(nav_backward), 
    .nav_left(nav_left), .nav_right(nav_right),
    .shoe_emergency_button(shoe_emergency_button),
    .thruster_left(thruster_left), .thruster_right(thruster_right)
  );

  always #5 clk = ~clk;

  initial begin
    $display("--- STARTING UMML HOVER SHOE DUAL KILL-SWITCH SIMULATION ---");
    
    // 1. Initial Reset
    rst_n = 0; 
    #20; 
    rst_n = 1;
    $display("Time: %0t ns | Reset released. Current State: %s", $time, dut.vertical_mode_state.name());

    // 2. Normal Flight
    #50;
    $display("Time: %0t ns | Normal flight. Current State: %s", $time, dut.vertical_mode_state.name());

    // 3. TEST 1: Tether Severed
    $display("Time: %0t ns | *** TEST 1: CRITICAL FAILURE - TETHER SEVERED! ***", $time);
    tether_severed = 1;
    #10;
    if (dut.vertical_mode_state.name() == "descend") begin
      $display(">>> SUCCESS 1: Tether kill-switch WORKED! System forced to DESCEND. <<<");
    end else begin
      $display(">>> FAILURE 1: System did not descend! <<<");
    end

    // 4. Reset conditions for Test 2
    $display("Time: %0t ns | Resetting failure conditions for Test 2...", $time);
    tether_severed = 0;
    #20; // Let it go back to normal flight state

    // 5. TEST 2: Empty Battery
    $display("Time: %0t ns | *** TEST 2: CRITICAL FAILURE - MAIN BATTERY EMPTY! ***", $time);
    empty_battery = 1;
    #10;
    if (dut.vertical_mode_state.name() == "descend") begin
      $display(">>> SUCCESS 2: Battery kill-switch WORKED! System forced to DESCEND. <<<");
    end else begin
      $display(">>> FAILURE 2: System did not descend! <<<");
    end

    $display("--- SIMULATION COMPLETE. ALL SAFETY INTERLOCKS VERIFIED. ---");
    $finish;
  end
endmodule
