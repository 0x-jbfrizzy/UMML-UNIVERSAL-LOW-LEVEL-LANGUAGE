import sys

# The Master UMML Opcode Table
OPCODES = {
    'NOP':           0x0,
    'MOV':           0x1,
    'ADD':           0x2,
    'LOAD':          0x3,
    'STORE':         0x4,
    'READ_CYCLES':   0x5,
    'SUB':           0x6,
    'VC_ALLOC':      0x7,
    'VC_BLOCK':      0x8,
    'PROBE':         0x9,
    'HOP_DELAY':     0xA,
    'SAVE_REG':      0xB,
    'ROLLBACK':      0xC,
    'RFO':           0xD,
    'FORCE_MISPRED': 0xE,
    'HALT':          0xF
}

def assemble(input_file, output_file):
    with open(input_file, 'r') as f:
        lines = f.readlines()

    clean_lines = []
    address = 0

    # Pass 1: Strip comments and blank lines
    for line in lines:
        if ';' in line:
            line = line[:line.index(';')]
        line = line.strip()
        if not line:
            continue
        clean_lines.append((line, address))
        address += 1

    machine_code = []

    # Pass 2: Translate to 16-bit machine code
    for line, addr in clean_lines:
        parts = line.replace(',', ' ').split()
        mnemonic = parts[0].upper()
        
        if mnemonic not in OPCODES:
            print(f"Error: Unknown instruction '{mnemonic}' at line {addr}")
            sys.exit(1)

        opcode = OPCODES[mnemonic]
        rd = 0
        rs = 0
        imm = 0

        # Parse operands based on instruction type
        if mnemonic in ['MOV', 'ADD', 'SUB', 'PROBE']:
            rd = int(parts[1][1:])
            rs = int(parts[2][1:])
            
        elif mnemonic in ['LOAD', 'STORE', 'HOP_DELAY']:
            rd_str = parts[1].strip('[]')
            rd = int(rd_str[1:])
            if len(parts) > 2:
                rs_str = parts[2].strip('[]')
                rs = int(rs_str[1:])
                
        elif mnemonic in ['VC_ALLOC', 'VC_BLOCK']:
            # Uses raw integers for Virtual Channel IDs
            rd = int(parts[1])
            rs = 0
            
        elif mnemonic == 'READ_CYCLES':
            rd = int(parts[1][1:])
            rs = 0
            
        elif mnemonic in ['SAVE_REG', 'ROLLBACK', 'FORCE_MISPRED', 'HALT', 'NOP']:
            rd = 0
            rs = 0

        # Pack into 16-bit binary: OOOO DDDD SSSS IIII
        instruction = (opcode << 12) | (rd << 8) | (rs << 4) | imm
        machine_code.append(f"{instruction:04X}")

    # Write to output file
    with open(output_file, 'w') as f:
        for code in machine_code:
            f.write(f"{code}\n")

    print(f"Successfully assembled {len(machine_code)} instructions to {output_file}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 copper_asm.py input.cop output.hex")
    else:
        assemble(sys.argv[1], sys.argv[2])