#!/usr/bin/awk -f
# UMML Compiler - v3.7 (Aerospace-Grade, Clean Variable Naming)

BEGIN {
    comp_count = 0; wire_count = 0; proof_count = 0; body_count = 0
    has_spine = 0; fsm_count = 0; param_count = 0
    transition_count = 0; override_count = 0
    pin_count = 0
}

/^#/ || /^$/ { next }

/^pin / {
    pin_name = $2; pin_dir = $3; pin_width = $4
    if (pin_width == "") pin_width = "1"
    width_minus_one = pin_width - 1
    pin_names[pin_count] = pin_name; pin_dirs[pin_count] = pin_dir
    pin_widths[pin_count] = width_minus_one; pin_count++
    next
}

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
    param_values[param_name] = param_value; param_units[param_name] = param_unit
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
    for (i=1; i<=NF; i++) {
        if ($i == "states") {
            fsm_state_lists[fsm_name] = ""
            for (j=i+1; j<=NF; j++) {
                fsm_state_lists[fsm_name] = fsm_state_lists[fsm_name] $j
                if (j < NF) fsm_state_lists[fsm_name] = fsm_state_lists[fsm_name] " "
            }
            break
        }
    }
    fsm_names[fsm_count] = fsm_name; fsm_count++; next
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
        if ($i == "of") dst = $(i+1)
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

/^if / {
    line = $0; sub(/^if /, "", line)
    split(line, parts, " force ")
    condition = parts[1]
    rest = parts[2]; split(rest, target_parts, " to ")
    target_fsm = target_parts[1]; target_state = target_parts[2]
    overrides[override_count++] = condition "|" target_fsm "|" target_state
    next
}

/^start/ { next }

END {
    print "module umml_top ("
    print "  input logic clk,"
    print "  input logic rst_n,"
    if (has_spine) { print "  input logic spine_clk,"; print "  input logic spine_en," }
    
    for (i = 0; i < pin_count; i++) {
        if (pin_dirs[i] == "input") port_str = "  input logic [" pin_widths[i] ":0] " pin_names[i]
        else port_str = "  output logic [" pin_widths[i] ":0] " pin_names[i]
        if (i < pin_count - 1) print port_str ","
        else print port_str
    }
    print ");\n"

    if (param_count > 0) {
        for (i = 0; i < param_count; i++) print "  parameter " params[i] " = " param_values[params[i]] "; // " param_units[params[i]]
        print ""
    }

    for (i = 0; i < fsm_count; i++) {
        fsm = fsm_names[i]
        print "  // State machine: " fsm
        print "  typedef enum logic [2:0] {" fsm_state_lists[fsm] "} " fsm "_t;"
        # FIX: Use fsm and fsm_next to avoid double "_state" (e.g., flight_state and flight_state_next)
        print "  " fsm "_t " fsm ", " fsm "_next;\n"
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
        fsm = fsm_names[i]; states = fsm_state_lists[fsm]
        n = split(states, state_array, ", ")
        print "  // State machine logic for " fsm
        print "  always_ff @(posedge clk or negedge rst_n) begin"
        print "    if (!rst_n) " fsm " <= " state_array[1] ";"
        print "    else " fsm " <= " fsm "_next;"
        print "  end\n"
        
        print "  always_comb begin"
        print "    " fsm "_next = " fsm ";"
        for (o = 0; o < override_count; o++) {
            split(overrides[o], ov, "|")
            if (ov[2] == fsm) {
                print "    if (" ov[1] ") " fsm "_next = " ov[3] ";"
            }
        }
        print "    case (" fsm ")"
        for (s = 1; s <= n; s++) {
            print "      " state_array[s] ": begin"
            for (t = 0; t < transition_count; t++) {
                split(transitions[t], tp, "|")
                if (tp[4] == fsm && tp[2] == state_array[s]) print "        if (" tp[1] ") " fsm "_next = " tp[3] ";"
            }
            print "      end"
        }
        print "    endcase"
        print "  end\n"
    }

    for (i = 0; i < body_count; i++) print body[i]
    for (dst in dst_drivers) {
        print "  // Combined async request for " dst
        print "  assign " dst "_req = " dst_drivers[dst] ";"
    }

    if (proof_count > 0) {
        print "\n  // Formal verification assertions"
        for (i = 0; i < proof_count; i++) print proofs[i]
    }

    if (override_count > 0) {
        print "  `ifdef FORMAL"
        print "  // =========================================="
        print "  // MATHEMATICAL PROOFS (SVA)"
        print "  // =========================================="
        for (o = 0; o < override_count; o++) {
            split(overrides[o], ov, "|")
            # Proof 1: The Override
            print "  property safety_override_" o ";"
            print "    @(posedge clk) disable iff (!rst_n)"
            print "    (" ov[1] ") |-> (" ov[2] "_next == " ov[3] ");"
            print "  endproperty"
            print "  assert property (safety_override_" o ");"
            print ""
            
            # Proof 2: The Stability/Liveness (Sticky)
            print "  property safety_sticky_" o ";"
            print "    @(posedge clk) disable iff (!rst_n)"
            print "    (" ov[2] " == " ov[3] ") |=> (" ov[2] "_next == " ov[3] ");"
            print "  endproperty"
            print "  assert property (safety_sticky_" o ");"
            print ""
        }
        print "  `endif"
    }
    print "\nendmodule"
}
