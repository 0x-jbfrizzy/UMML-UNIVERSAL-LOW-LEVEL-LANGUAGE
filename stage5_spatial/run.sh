#!/usr/bin/env bash
set -euo pipefail

# Compile UMML Stage 5 Spatial Fabric
iverilog -g2012 -o umml_stage5_sim stage5_design.sv stage5_tb.sv

# Run Simulation
vvp umml_stage5_sim
