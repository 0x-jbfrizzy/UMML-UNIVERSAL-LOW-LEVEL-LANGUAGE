//-----------------------------------------------------------------------------
// Module: mono_thermometer_adder
// Desc  : Monotone thermometer adder. Addition as merge (sorting network).
//         No carry propagation. No inverters. Pure monotone logic.
//-----------------------------------------------------------------------------
module mono_thermometer_adder (
    input rst_n,
    input [3:0] a, b,  // Thermometer codes (values 0-4)
    output [3:0] sum,
    output valid
);

    // Concatenate inputs
    logic [7:0] concat;
    assign concat = {b, a};
    
    // 8-bit sorting network (descending order: 1s at top, 0s at bottom)
    // Using optimal sorting network for 8 elements
    logic [7:0] s1, s2, s3, s4;
    
    // Stage 1: Compare pairs (0,1), (2,3), (4,5), (6,7)
    assign s1[0] = concat[0] & concat[1];  // min
    assign s1[1] = concat[0] | concat[1];  // max
    assign s1[2] = concat[2] & concat[3];
    assign s1[3] = concat[2] | concat[3];
    assign s1[4] = concat[4] & concat[5];
    assign s1[5] = concat[4] | concat[5];
    assign s1[6] = concat[6] & concat[7];
    assign s1[7] = concat[6] | concat[7];
    
    // Stage 2: Compare (0,2), (1,3), (4,6), (5,7)
    assign s2[0] = s1[0];
    assign s2[1] = s1[1] & s1[3];
    assign s2[2] = s1[1] | s1[3];
    assign s2[3] = s1[2];
    assign s2[4] = s1[4];
    assign s2[5] = s1[5] & s1[7];
    assign s2[6] = s1[5] | s1[7];
    assign s2[7] = s1[6];
    
    // Stage 3: Compare (1,2), (5,6)
    assign s3[0] = s2[0];
    assign s3[1] = s2[1] & s2[2];
    assign s3[2] = s2[1] | s2[2];
    assign s3[3] = s2[3];
    assign s3[4] = s2[4];
    assign s3[5] = s2[5] & s2[6];
    assign s3[6] = s2[5] | s2[6];
    assign s3[7] = s2[7];
    
    // Stage 4: Compare (0,4), (1,5), (2,6), (3,7)
    assign s4[0] = s3[0] & s3[4];
    assign s4[1] = s3[0] | s3[4];
    assign s4[2] = s3[1] & s3[5];
    assign s4[3] = s3[1] | s3[5];
    assign s4[4] = s3[2] & s3[6];
    assign s4[5] = s3[2] | s3[6];
    assign s4[6] = s3[3] & s3[7];
    assign s4[7] = s3[3] | s3[7];
    
    // Stage 5: Final merge (1,2), (3,4), (5,6)
    logic [7:0] sorted;
    assign sorted[0] = s4[0];
    assign sorted[1] = s4[1] & s4[2];
    assign sorted[2] = s4[1] | s4[2];
    assign sorted[3] = s4[3] & s4[4];
    assign sorted[4] = s4[3] | s4[4];
    assign sorted[5] = s4[5] & s4[6];
    assign sorted[6] = s4[5] | s4[6];
    assign sorted[7] = s4[7];
    
    // Output: top 4 bits (saturated to max value 4)
    assign sum = sorted[7:4];
    
    assign valid = 1'b1;

endmodule
