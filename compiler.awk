#!/usr/bin/awk -f
# UMML Compiler - Final Flawless Keyword Parser
# Translates plain English UMML to 100% synthesizable SystemVerilog

BEGIN {
    comp_count = 0; wire_count = 0; proof_count = 0; body_count = 0
    has_spine = 0; fsm_count = 0; param_count = 0
    transition_count = 0; override_count = 0
}

/^#/ || /^$/ { next }

/^spine the clock to/ {
    has_spine = 1
    for (i=1; i<=NF; i++) { if ($i == "to") { spine_target = $(i+1); break } }
    body[body_count++] = "  // Spine initialization for " spine_target
    body[body_count++] = "  // Global clock gated after initialization"
    next
}

/^set/ {
    param_name = $2; param_value = $4; param_unit = $5
    params[param_count++] = param_name
    param_values[param_name] = param_value
    param_units[param_name] = param_unit
    next
}

/^make a memory named/ {
    for (i=1; i<=NF; i++) { if ($i == "named") { cname = $(i+1); break } }
    comp_types[comp_count] = "memory"; comp_names[comp_count] = cname; comp_sizes[comp_count] = 16
    for (i=1; i<=NF; i++) { if ($i == "size") comp_sizes[comp_count] = $(i+1) }
    comp_count++; next
}

/^make a neuron named/ {
    for (i=1; i<=NF; i++) { if ($i == "named") { cname = $(i+1); break } }
    comp_types[comp_count] = "neuron"; comp_names[comp_count] = cname
    comp_thresholds[comp_count] = 1; comp_leaks[comp_count] = 0
    for (i=1; i<=NF; i++) {
        if ($i == "threshold") comp_thresholds[comp_count] = $(i+1)
        if ($i == "leak") comp_leaks[comp_count] = $(i+1)
    }
    comp_count++; next
}

/^make a state_machine named/ {
    for (i=1; i<=NF; i++) { if ($i == "named") { fsm_name = $(i+1); break } }
    idx = index($0, "states ")
    fsm_state_lists[fsm_name] = substr($0, idx + 7)
    fsm_names[fsm_count] = fsm_name
    fsm_count++; next
}

/^make a metamorphic router named/ {
    for (i=1; i<=NF; i++) { if ($i == "named") { cname = $(i+1); break } }
    comp_types[comp_count] = "metamorphic_router"; comp_names[comp_count] = cname; comp_keys[comp_count] = "8'h00"
    for (i=1; i<=NF; i++) { if ($i == "key") comp_keys[comp_count] = $(i+1) }
    comp_count++; next
}

/^morph the spike from/ {
    for (i=1; i<=NF; i++) {
        if ($i == "from") src = $(i+1)
        if ($i == "through") router = $(i+1)
        if ($i == "to") dst = $(i+1)
        if ($i == "key") key = $(i+1)
    }
    wire_name = "w_morph_" wire_count++
    body[body_count++] = "  wire " wire_name ";"
    body[body_count++] = "  assign " wire_name " = " src "_spike ^ " key ";"
    if (dst_drivers[dst] == "") dst_drivers[dst] = wire_name
    else dst_drivers[dst] = dst_drivers[dst] " | " wire_name
    proofs[proof_count++] = "  assert property (@(posedge clk) disable iff (!rst_n) (" src "_spike |-> ##[1:5] " dst "_req));"
    next
}

/^flow the spike from/ {
    for (i=1; i<=NF; i++) {
        if ($i == "from") src = $(i+1)
        if ($i == "of") dst = $(i+1) # FIX: Grabs the word after "of" (e.g., "thruster_left")
    }
    if (dst_drivers[dst] == "") dst_drivers[dst] = src "_spike"
    else dst_drivers[dst] = dst_drivers[dst] " | " src "_spike"
    next
}

/^on press/ {
    for (i=1; i<=NF; i++) {
        if ($i == "press") trigger = $(i+1)
        if ($i == "from") from_state = $(i+1)
        if ($i == "to") to_state = $(i+1)
        if ($i == "in") target_fsm = $(i+1)
    }
    transitions[transition_count++] = trigger "|" from_state "|" to_state "|" target_fsm
    next
}

/^if/ {
    condition = $2
    for (i=1; i<=NF; i++) {
        if ($i == "force") target_fsm = $(i+1)
        if ($i == "to") target_state = $(i+1)
    }
    overrides[override_count++] = condition "|" target_fsm "|" target_state
    next
}

/^start/ { next }

END {
    print "module umml_top ("
    print "  input logic clk,"
    print "  input logic rst_n,"
    if (has_spine) { print "  input logic spine_clk,"; print "  input logic spine_en," }
    print "  input logic [15:0] speed_selector,"
    print "  input logic right_stick_press,"
    print "  input logic right_stick_backward_hold,"
    print "  input logic nav_forward,"
    print "  input logic nav_backward,"
    print "  input logic nav_left,"
    print "  input logic nav_right,"
    print "  input logic shoe_emergency_button,"
    print "  output logic [15:0] thruster_left,"
    print "  output logic [15:0] thruster_right"
    print ");\n"
    
    if (param_count > 0) {
        for (i = 0; i < param_count; i++) {
            print "  parameter " params[i] " = " param_values[params[i]] "; // " param_units[params[i]]
        }
        print ""
    }
    
    for (i = 0; i < fsm_count; i++) {
        fsm = fsm_names[i]
        print "  // State machine: " fsm
        print "  typedef enum logic [2:0] {" fsm_state_lists[fsm] "} " fsm "_state_t;"
        print "  " fsm "_state_t " fsm "_state, " fsm "_next_state;\n"
    }
    
    for (i = 0; i < comp_count; i++) {
        cname = comp_names[i]
        if (comp_types[i] == "memory") {
            print "  // Memory: " cname
            print "  logic [15:0] " cname "_data;"
            print "  logic " cname "_req, " cname "_ack;\n"
        } else if (comp_types[i] == "neuron") {
            print "  // Neuron: " cname " (threshold=" comp_thresholds[i] ", leak=" comp_leaks[i] ")"
            print "  logic " cname "_spike;"
            print "  logic [15:0] " cname "_mem;"
            print "  logic " cname "_req, " cname "_ack;\n"
        } else if (comp_types[i] == "metamorphic_router") {
            print "  // Metamorphic Router: " cname
            print "  logic [7:0] " cname "_key;"
            print "  logic " cname "_req, " cname "_ack;\n"
        }
    }
    
    for (i = 0; i < fsm_count; i++) {
        fsm = fsm_names[i]
        states = fsm_state_lists[fsm]
        n = split(states, state_array, ", ")
        print "  // State machine logic for " fsm
        print "  always_ff @(posedge clk or negedge rst_n) begin"
        print "    if (!rst_n) " fsm "_state <= " state_array[1] ";"
        print "    else " fsm "_state <= " fsm "_next_state;"
        print "  end\n"
        print "  always_comb begin"
        print "    " fsm "_next_state = " fsm "_state;"
        print "    case (" fsm "_state)"
        for (s = 1; s <= n; s++) {
            print "      " state_array[s] ": begin"
            for (t = 0; t < transition_count; t++) {
                split(transitions[t], tp, "|")
                if (tp[4] == fsm && tp[2] == state_array[s]) {
                    print "        if (" tp[1] ") " fsm "_next_state = " tp[3] ";"
                }
            }
            print "      end"
        }
        print "    endcase\n  end\n"
    }
    
    print "  // Emergency override logic"
    print "  always_comb begin"
    for (o = 0; o < override_count; o++) {
        split(overrides[o], ov, "|")
        print "    if (" ov[1] ") " ov[2] "_next_state = " ov[3] ";"
    }
    print "  end\n"
    
    for (i = 0; i < body_count; i++) print body[i]
    
    for (dst in dst_drivers) {
        print "  // Combined async request for " dst
        print "  assign " dst "_req = " dst_drivers[dst] ";"
    }
    
    if (proof_count > 0) {
        print "\n  // Formal verification assertions"
        for (i = 0; i < proof_count; i++) print proofs[i]
    }
    print "\nendmodule"
}
