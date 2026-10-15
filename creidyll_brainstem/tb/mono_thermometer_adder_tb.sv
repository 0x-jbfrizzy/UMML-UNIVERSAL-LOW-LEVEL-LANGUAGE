`timescale 1ns / 1ps
module mono_thermometer_adder_tb;
    logic rst_n, valid;
    logic [3:0] a, b, sum;

    mono_thermometer_adder dut (
        .rst_n(rst_n),
        .a(a), .b(b),
        .sum(sum),
        .valid(valid)
    );

    initial begin
        $dumpfile("mono_add.vcd"); $dumpvars(0, mono_thermometer_adder_tb);
        
        $display("[TB] Test 1: Reset");
        rst_n = 0;
        #10;
        $display("[TB] PASS: Reset complete");

        $display("[TB] Test 2: Add 2 + 2 = 4");
        rst_n = 1;
        a = 4'b0011;  // Value 2 (2 ones)
        b = 4'b0011;  // Value 2 (2 ones)
        #1;
        
        // Expected: 2 + 2 = 4, thermometer = 1111
        $display("[TB] INFO: sum = %b (expected 1111 for value 4)", sum);
        
        if (sum !== 4'b1111) begin
            $error("FAIL: sum = %b (expected 1111)", sum);
            $finish;
        end
        $display("[TB] PASS: 2 + 2 = 4");

        $display("[TB] Test 3: Add 3 + 1 = 4");
        a = 4'b0111;  // Value 3 (3 ones)
        b = 4'b0001;  // Value 1 (1 one)
        #1;
        
        // Expected: 3 + 1 = 4, thermometer = 1111
        $display("[TB] INFO: sum = %b (expected 1111 for value 4)", sum);
        
        if (sum !== 4'b1111) begin
            $error("FAIL: sum = %b (expected 1111)", sum);
            $finish;
        end
        $display("[TB] PASS: 3 + 1 = 4");

        $display("[TB] Test 4: Add 1 + 1 = 2");
        a = 4'b0001;  // Value 1
        b = 4'b0001;  // Value 1
        #1;
        
        // Expected: 1 + 1 = 2, thermometer = 0011
        $display("[TB] INFO: sum = %b (expected 0011 for value 2)", sum);
        
        if (sum !== 4'b0011) begin
            $error("FAIL: sum = %b (expected 0011)", sum);
            $finish;
        end
        $display("[TB] PASS: 1 + 1 = 2");

        $display("[TB] Simulation Complete.");
        $finish;
    end
endmodule
