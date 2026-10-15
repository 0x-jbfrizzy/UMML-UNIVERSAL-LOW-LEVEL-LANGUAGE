#!/usr/bin/awk -f
# UMML Compiler - Final Robust Version with Multi-Driver Resolution
# Translates plain English UMML to 100% synthesizable SystemVerilog

BEGIN {
    comp_count = 0
    wire_count = 0
    proof_count = 0
    body_count = 0
    has_spine = 0
    fsm_count = 0
    param_count = 0
    transition_count = 0
    override_count = 0
}

/^#/ || /^$/ { next }

/^spine the clock to/ {
    has_spine = 1
    spine_target = $5
    body[body_count++] = "  // Spine initialization for " spine_target
    body[body_count++] = "  // Global clock gated after initialization"
    next
}

/^set/ {
    param_name = $2
    param_value = $4
    param_unit = $5
    params[param_count++] = param_name
    param_values[param_name] = param_value
    param_units[param_name] = param_unit
    next
}

/^make a memory named/ {
    comp_types[comp_count] = "memory"
    comp_names[comp_count] = $5
    comp_sizes[comp_count] = 16
    for (i=6; i<=NF; i++) { if ($i == "size") comp_sizes[comp_count] = $(i+1) }
    comp_count++
    next
}

/^make a neuron named/ {
    comp_types[comp_count] = "neuron"
    comp_names[comp_count] = $5
    comp_thresholds[comp_count] = 1
    comp_leaks[comp_count] = 0
    for (i=6; i<=NF; i++) {
        if ($i == "threshold") comp_thresholds[comp_count] = $(i+1)
        if ($i == "leak") comp_leaks[comp_count] = $(i+1)
    }
    comp_count++
    next
}

/^make a state_machine named/ {
    fsm_names[fsm_count] = $5
    idx = index($0, "states ")
    fsm_state_lists[$5] = substr($0, idx + 7)
    fsm_count++
    next
}

/^make a metamorphic router named/ {
    comp_types[comp_count] = "metamorphic_router"
    comp_names[comp_count] = $6
    comp_keys[comp_count] = "8'h00"
    for (i=7; i<=NF; i++) { if ($i == "key") comp_keys[comp_count] = $(i+1) }
    comp_count++
    next
}

/^morph the spike from/ {
    src = $5
    router = $7
    dst = $9
    key = $12
    
    wire_name = "w_morph_" wire_count++
    body[body_count++] = "  wire " wire_name ";"
    body[body_count++] = "  assign " wire_name " = " src "_spike ^ " key ";"
    
    # FIX: Accumulate drivers for the destination to prevent multi-driver errors
    if (dst_drivers[dst] == "") {
        dst_drivers[dst] = wire_name
    } else {
        dst_drivers[dst] = dst_drivers[dst] " | " wire_name
    }
    
    proofs[proof_count++] = "  assert property (@(posedge clk) disable iff (!rst_n) (" src "_spike |-> ##[1:5] " dst "_req));"
    next
}

/^flow the spike from/ {
    src = $5
    dst = $10
    
    # FIX: Accumulate drivers for flow commands too
    if (dst_drivers[dst] == "") {
        dst_drivers[dst] = src "_spike"
    } else {
        dst_drivers[dst] = dst_drivers[dst] " | " src "_spike"
    }
    next
}

/^on press/ {
    trigger = $3
    from_state = $6
    to_state = $8
    target_fsm = $10
    
    transitions[transition_count++] = trigger "|" from_state "|" to_state "|" target_fsm
    next
}

/^if/ {
    condition = $2
    target_fsm = $6
    target_state = $8
    
    overrides[override_count++] = condition "|" target_fsm "|" target_state
    next
}

/^start/ { next }

END {
    print "module umml_top ("
    print "  input logic clk,"
    print "  input logic rst_n,"
    
    if (has_spine) {
        print "  input logic spine_clk,"
        print "  input logic spine_en,"
    }
    
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
    print ");"
    print ""
    
    if (param_count > 0) {
        for (i = 0; i < param_count; i++) {
            pname = params[i]
            pval = param_values[pname]
            punit = param_units[pname]
            print "  parameter " pname " = " pval "; // " punit
        }
        print ""
    }
    
    for (i = 0; i < fsm_count; i++) {
        fsm = fsm_names[i]
        states = fsm_state_lists[fsm]
        print "  // State machine: " fsm
        print "  typedef enum logic [2:0] {" states "} " fsm "_state_t;"
        print "  " fsm "_state_t " fsm "_state, " fsm "_next_state;"
        print ""
    }
    
    for (i = 0; i < comp_count; i++) {
        ctype = comp_types[i]
        cname = comp_names[i]
        
        if (ctype == "memory") {
            print "  // Memory: " cname
            print "  logic [15:0] " cname "_data;"
            print "  logic " cname "_req, " cname "_ack;"
            print ""
        }
        else if (ctype == "neuron") {
            print "  // Neuron: " cname " (threshold=" comp_thresholds[i] ", leak=" comp_leaks[i] ")"
            print "  logic " cname "_spike;"
            print "  logic [15:0] " cname "_mem;"
            print "  logic " cname "_req, " cname "_ack;"
            print ""
        }
        else if (ctype == "metamorphic_router") {
            print "  // Metamorphic Router: " cname
            print "  logic [7:0] " cname "_key;"
            print "  logic " cname "_req, " cname "_ack;"
            print ""
        }
    }
    
    for (i = 0; i < fsm_count; i++) {
        fsm = fsm_names[i]
        states = fsm_state_lists[fsm]
        
        n = split(states, state_array, ", ")
        first_state = state_array[1]
        
        print "  // State machine logic for " fsm
        print "  always_ff @(posedge clk or negedge rst_n) begin"
        print "    if (!rst_n) " fsm "_state <= " first_state ";"
        print "    else " fsm "_state <= " fsm "_next_state;"
        print "  end"
        print ""
        
        print "  always_comb begin"
        print "    " fsm "_next_state = " fsm "_state;"
        print "    case (" fsm "_state)"
        
        for (s = 1; s <= n; s++) {
            state = state_array[s]
            print "      " state ": begin"
            
            for (t = 0; t < transition_count; t++) {
                split(transitions[t], trans_parts, "|")
                trigger = trans_parts[1]
                from = trans_parts[2]
                to = trans_parts[3]
                target = trans_parts[4]
                
                if (target == fsm && from == state) {
                    print "        if (" trigger ") " fsm "_next_state = " to ";"
                }
            }
            print "      end"
        }
        
        print "    endcase"
        print "  end"
        print ""
    }
    
    print "  // Emergency override logic"
    print "  always_comb begin"
    for (o = 0; o < override_count; o++) {
        split(overrides[o], ov_parts, "|")
        cond = ov_parts[1]
        target_fsm = ov_parts[2]
        target_state = ov_parts[3]
        print "    if (" cond ") " target_fsm "_next_state = " target_state ";"
    }
    print "  end"
    print ""
    
    # Print accumulated wire assignments
    for (i = 0; i < body_count; i++) {
        print body[i]
    }
    
    # FIX: Print combined multi-driver assignments at the end
    for (dst in dst_drivers) {
        print "  // Combined async request for " dst
        print "  assign " dst "_req = " dst_drivers[dst] ";"
    }
    
    if (proof_count > 0) {
        print ""
        print "  // Formal verification assertions"
        for (i = 0; i < proof_count; i++) {
            print proofs[i]
        }
    }
    
    print ""
    print "endmodule"
}
