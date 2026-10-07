#!/bin/bash
# UMML Native Spatial Compiler
# Usage: ./spatial_asm.sh <input.umml> <output.hex>

if [ "$#" -ne 2 ]; then
    echo "Usage: ./spatial_asm.sh <input.umml> <output.hex>"
    exit 1
fi

awk '
BEGIN {
    op["PASS"]=0; op["ADD"]=1; op["SUB"]=2; op["AND"]=3;
    dir["NORTH"]=0; dir["SOUTH"]=1; dir["EAST"]=2; dir["WEST"]=3;
}
/^NODE/ {
    x = $2 + 0;
    y = $3 + 0;
    o = op[$4];
    
    # Handle 7 fields (ADD) and 6 fields (PASS)
    if (NF == 7) {
        ia = dir[$5];
        ib = dir[$6];
        od = dir[$7];
    } else if (NF == 6) {
        ia = dir[$5];
        ib = dir[$5]; # Dummy input for PASS nodes
        od = dir[$6];
    }

    # Pack into 16 bits: [15:14] OP, [13:10] X, [9:6] Y, [5:4] IN_A, [3:2] IN_B, [1:0] OUT
    val = o * 16384 + x * 1024 + y * 64 + ia * 16 + ib * 4 + od;
    printf "%04X\n", val;
}
' "$1" > "$2"

echo "Compiled $1 to $2 natively."