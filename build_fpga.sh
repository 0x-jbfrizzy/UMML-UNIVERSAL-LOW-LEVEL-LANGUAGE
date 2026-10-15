#!/bin/sh
# UMML Open-Source FPGA Build Pipeline
# Target: Lattice iCE40 (Up5k)
# Tools: Yosys (Synthesis), nextpnr (Place & Route), IceStorm (Bitstream)

if [ -z "$1" ]; then
    echo "Usage: ./build_fpga.sh <top_module.v>"
    echo "Example: ./build_fpga.sh sequencer_no_assert.v"
    exit 1
fi

TOP_FILE=$1
TOP_MODULE=$(basename "$TOP_FILE" .v)
DESIGN_NAME="umml_top"

echo "========================================="
echo "  UMML FPGA BUILD PIPELINE (iCE40 Up5k)"
echo "========================================="
echo ""

# 1. SYNTHESIS (Yosys)
# Use the built-in synth_ice40 command - this is the modern, reliable approach
echo "[1/3] Synthesizing with Yosys (synth_ice40)..."
yosys -p "
    read_verilog -sv creidyll_brainstem/rtl/async_memory_cell.sv;
    read_verilog -sv creidyll_brainstem/rtl/async_lif_neuron.sv;
    read_verilog -sv creidyll_brainstem/rtl/async_metamorphic_router.sv;
    read_verilog -sv creidyll_brainstem/rtl/async_clock_spine.sv;
    read_verilog -sv $TOP_FILE;
    
    synth_ice40 -top $DESIGN_NAME -json ${DESIGN_NAME}.json;
"

if [ $? -ne 0 ]; then
    echo "[ERROR] Yosys synthesis failed!"
    exit 1
fi
echo "[1/3] Synthesis successful."
echo ""

# 2. PLACE AND ROUTE (nextpnr)
echo "[2/3] Placing and Routing with nextpnr-ice40..."
nextpnr-ice40 \
    --up5k \
    --package sg48 \
    --json ${DESIGN_NAME}.json \
    --asc ${DESIGN_NAME}.asc \
    --opt-timing

if [ $? -ne 0 ]; then
    echo "[ERROR] nextpnr place and route failed!"
    exit 1
fi
echo "[2/3] Place and Route successful."
echo ""

# 3. BITSTREAM GENERATION (IcePack)
echo "[3/3] Generating Bitstream with icepack..."
icepack ${DESIGN_NAME}.asc ${DESIGN_NAME}.bin

if [ $? -ne 0 ]; then
    echo "[ERROR] icepack bitstream generation failed!"
    exit 1
fi

echo ""
echo "========================================="
echo "  BUILD SUCCESSFUL!"
echo "========================================="
echo "Output file: ${DESIGN_NAME}.bin"
echo ""
echo "To flash to a physical iCE40 board via USB, run:"
echo "  iceprog ${DESIGN_NAME}.bin"
echo "========================================="
