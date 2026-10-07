#!/bin/bash
# UMML Native Assembler
# Usage: ./asm.sh <input.cop> <output.hex>

if [ "$#" -ne 2 ]; then
    echo "Usage: ./asm.sh <input.cop> <output.hex>"
    exit 1
fi

awk '
BEGIN {
    # Opcode Map
    op["NOP"]=0; op["MOV"]=1; op["ADD"]=2; op["LOAD"]=3; op["STORE"]=4;
    op["SUB"]=6; op["SHLI"]=10; op["OR"]=11; op["JMP"]=8; op["STORE_INST"]=9; op["HALT"]=15;
}
{
    # Remove comments
    sub(/;.*/, "");
    if (NF == 0) next;

    cmd = toupper($1);
    if (cmd in op) {
        opcode = op[cmd];
        rd = 0; rs = 0; imm = 0;

        # Parse operands based on instruction type
        if (cmd == "MOV" || cmd == "ADD" || cmd == "SUB" || cmd == "OR") {
            rd = substr($2, 2) + 0;
            rs = substr($3, 2) + 0;
        } else if (cmd == "LOAD" || cmd == "STORE") {
            gsub(/[\[\]]/, "", $2);
            rd = substr($2, 2) + 0;
            if (NF > 2) {
                gsub(/[\[\]]/, "", $3);
                rs = substr($3, 2) + 0;
            }
        } else if (cmd == "SHLI" || cmd == "JMP") {
            rd = substr($2, 2) + 0;
            if (NF > 2) imm = $3 + 0;
        } else if (cmd == "STORE_INST") {
            rd = substr($2, 2) + 0;
            rs = substr($3, 2) + 0;
        }

        # Pack the 16-bit instruction: OOOO DDDD SSSS IIII
        val = opcode * 4096 + rd * 256 + rs * 16 + imm;
        printf "%04X\n", val;
    }
}
' "$1" > "$2"

echo "Assembled $1 to $2 natively."