#!/usr/bin/env bash
set -euo pipefail

# UMML Telemetry Collector
# Captures synthesis metrics and simulation traces for analysis.

OUTPUT_DIR="telemetry_data"
mkdir -p "$OUTPUT_DIR"

# 1. Host Layer Metrics
START_TIME=$(date +%s)
START_MEM_KB=$(grep VmRSS /proc/$$/status | awk '{print $2}')

# 2. ASIC Synthesis (Yosys)
echo "[INFO] Running Yosys synthesis..." >&2
yosys -q -p "read_verilog -sv stage5_spatial/stage5_design.sv; synth -top swarm_node; stat" \
    | tee "$OUTPUT_DIR/yosys_stat.txt"

GATES=$(grep "Number of cells" "$OUTPUT_DIR/yosys_stat.txt" | awk '{print $4}')

# 3. Simulation Trace (Icarus Verilog)
echo "[INFO] Running Icarus simulation..." >&2
cd stage5_spatial
iverilog -g2012 -o umml_sim stage5_design.sv stage5_tb.sv
./umml_sim > ../"$OUTPUT_DIR/vvp_trace.log" 2>&1 || true
cd ..

# Parse trace for key hardware events
ROUTES_FLIPPED=$(grep -c "Routing MUX" "$OUTPUT_DIR/vvp_trace.log" || echo 0)
POWER_SPIKES=$(grep -c "Hamming Weight Spike" "$OUTPUT_DIR/vvp_trace.log" || echo 0)
CYCLES=$(grep "Clock Cycle" "$OUTPUT_DIR/vvp_trace.log" | tail -1 | awk '{print $3}' || echo 0)

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MEM_DELTA=$(( $(grep VmRSS /proc/$$/status | awk '{print $2}') - START_MEM_KB ))

# 4. Generate Structured Report (JSON-like for easy parsing by Python/CI)
cat <<REPORT > "$OUTPUT_DIR/metrics.json"
{
  "timestamp": "$START_TIME",
  "host_metrics": {
    "elapsed_seconds": $ELAPSED,
    "memory_delta_kb": $MEM_DELTA
  },
  "silicon_metrics": {
    "synth_gates": $GATES,
    "sim_cycles": $CYCLES,
    "mux_routes_flipped": $ROUTES_FLIPPED,
    "hd_power_spikes": $POWER_SPIKES
  }
}
REPORT

echo "[DONE] Metrics written to $OUTPUT_DIR/metrics.json" >&2
