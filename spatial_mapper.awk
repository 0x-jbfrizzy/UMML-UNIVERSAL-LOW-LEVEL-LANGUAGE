BEGIN {
    print "# UMML FEATURE 3: Cross-Architecture Spatial Mapping"
    print "# Input: RISC-V Assembly -> Output: UMML Spatial Dataflow"
    print ""
    
    alu_count = 0
    print "make a memory named reg_x1 with size 16"
    print "make a memory named reg_x2 with size 16"
    print "make a memory named reg_x3 with size 16"
    print "make a memory named reg_x5 with size 16"
    print "make a memory named reg_x6 with size 16"
    print ""
}

/add/ {
    rd = $2; sub(/,/, "", rd)
    rs1 = $3; sub(/,/, "", rs1)
    rs2 = $4; sub(/,/, "", rs2)
    
    alu_count++
    print "# Mapped Instruction: ADD " rd ", " rs1 ", " rs2
    # FIX: Use threshold 1 since merge gate handles the OR logic
    print "make a neuron named alu_" alu_count " with threshold 1 and leak 0"
    # FIX: Use the merge command to properly combine inputs
    print "merge the spike from reg_" rs1 " and reg_" rs2 " into the input of alu_" alu_count
    print "flow the spike from alu_" alu_count " into the write of reg_" rd
    print ""
}

/sub/ {
    rd = $2; sub(/,/, "", rd)
    rs1 = $3; sub(/,/, "", rs1)
    rs2 = $4; sub(/,/, "", rs2)
    
    alu_count++
    print "# Mapped Instruction: SUB " rd ", " rs1 ", " rs2
    print "make a neuron named alu_" alu_count " with threshold 1 and leak 0"
    print "merge the spike from reg_" rs1 " and reg_" rs2 " into the input of alu_" alu_count
    print "flow the spike from alu_" alu_count " into the write of reg_" rd
    print ""
}

END {
    print "start the system"
}
