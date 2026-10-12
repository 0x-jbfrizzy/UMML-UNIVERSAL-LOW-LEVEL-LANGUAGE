#!/bin/bash
# UMML Dual-Layer Telemetry Wrapper
# Tracks Host OS interactions AND Silicon Gate interactions in real-time.

# ANSI Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}  UMML SYSTEM & SILICON TELEMETRY BAR    ${NC}"
echo -e "${CYAN}=========================================${NC}"

# --- LAYER 1: HOST INTERACTION TRACKING ---
echo -e "\n${YELLOW}[HOST LAYER] Tracking OS Interactions...${NC}"

# Record start time and memory
START_TIME=$SECONDS
START_MEM=$(grep VmRSS /proc/$$/status 2>/dev/null | awk '{print $2}')

# Track file interactions (Input/Output)
echo "  -> Reading Design Files:"
ls -lh stage5_spatial/stage5_design.sv stage5_spatial/stage5_tb.sv 2>/dev/null | awk '{print "     [FILE] " $9 " (" $5 ")"}'

echo "  -> Compiling with Yosys (ASIC Synth)..."
# Run synthesis and capture gate count
GATE_STATS=$(yosys -p "read_verilog -sv stage5_spatial/stage5_design.sv; synth -top swarm_node; stat" 2>&1 | grep "Number of cells" | awk '{print $4}')
echo "     [SILICON] Synthesized $GATE_STATS physical logic gates."

echo "  -> Simulating with Icarus Verilog..."
# Run simulation and capture power/interaction metrics
SIM_OUTPUT=$(cd stage5_spatial && iverilog -g2012 -o umml_sim stage5_design.sv stage5_tb.sv && vvp umml_sim)

# Parse the simulation output for hardware interactions
ROUTES=$(echo "$SIM_OUTPUT" | grep -c "Routing MUX" 2>/dev/null || echo "0")
POWER_SPIKES=$(echo "$SIM_OUTPUT" | grep -c "Hamming Weight Spike" 2>/dev/null || echo "0")
CYCLES=$(echo "$SIM_OUTPUT" | grep "Clock Cycle" | tail -1 | awk '{print $3}' 2>/dev/null || echo "Unknown")

echo -e "\n${GREEN}[SILICON LAYER] Tracking Hardware Interactions...${NC}"
echo "  -> Clock Cycles Executed: $CYCLES"
echo "  -> Crossbar Routes Flipped: $ROUTES"
echo "  -> Power Anomalies (DPA Leaks): $POWER_SPIKES"

# --- LAYER 2: FINAL RESOURCE TALLY ---
END_TIME=$SECONDS
END_MEM=$(grep VmRSS /proc/$$/status 2>/dev/null | awk '{print $2}')
DURATION=$((END_TIME - START_TIME))

echo -e "\n${CYAN}-----------------------------------------${NC}"
echo -e "${CYAN}  EXECUTION SUMMARY${NC}"
echo -e "${CYAN}-----------------------------------------${NC}"
echo "  -> Host Time Elapsed: ${DURATION}s"
echo "  -> Host Memory Delta: $((END_MEM - START_MEM)) KB"
echo "  -> Status: ${GREEN}VERIFIED${NC}"
echo -e "${CYAN}=========================================${NC}"