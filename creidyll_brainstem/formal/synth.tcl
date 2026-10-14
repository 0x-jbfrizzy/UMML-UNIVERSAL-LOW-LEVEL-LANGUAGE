# Read the RTL files
read_verilog -sv ../rtl/wddl_subtractor.sv
read_verilog -sv ../rtl/spatial_pid_reg.sv
read_verilog -sv ../rtl/umml_spatial_pid_node.sv

# Set the top module
hierarchy -check -top umml_spatial_pid_node

# Synthesize to generic gates
proc; opt; fsm; opt; memory; opt;

# Map to standard cells (generic)
techmap; opt;

# Map flip-flops
dfflibmap -liberty +/cells.lib
abc -liberty +/cells.lib

# Clean up
clean -purge

# Output statistics
stat

# Write the gate-level netlist
write_verilog -noattr synth_umml_spatial_pid_node.v
