BEGIN {
    input_count = 0
    wire_count = 0
    proof_count = 0
    comp_count = 0
    body_count = 0
}

/^#/ || /^$/ { next }

/^make/ {
    type = $3
    name = $5
    
    if ($3 == "metamorphic" && $4 == "router") {
        type = "metamorphic_router"
        name = $6
    }
    
    comp_type[name] = type
    
    thresh = 20; leak = 2; trace = 15; size = 16; key = "8'h00"
    for(i=1; i<=NF; i++) {
        if ($i == "threshold") thresh = $(i+1)
        if ($i == "leak") leak = $(i+1)
        if ($i == "trace") trace = $(i+1)
        if ($i == "size") size = $(i+1)
        if ($i == "key") key = $(i+1)
    }
    
    comp_name[comp_count] = name
    comp_type_arr[comp_count] = type
    comp_thresh[comp_count] = thresh
    comp_leak[comp_count] = leak
    comp_trace[comp_count] = trace
    comp_size[comp_count] = size
    comp_key[comp_count] = key
    comp_count++
}

function get_out_port(name) {
    if (comp_type[name] == "neuron") return "spike_req"
    if (comp_type[name] == "synapse") return "update_req"
    if (comp_type[name] == "memory") return "rd_ack"
    return "req_out"
}

function get_in_port(name, port_hint) {
    if (comp_type[name] == "memory") {
        if (port_hint == "write") return "wr_req"
        if (port_hint == "read") return "rd_req"
        return "wr_req"
    }
    if (comp_type[name] == "neuron") return "req_in"
    if (comp_type[name] == "synapse") return "pre_req"
    return "req_in"
}

/^put/ {
    src_name = $2; dst_port = $5; dst_name = $7
    inputs[input_count++] = src_name
    dst_v = get_in_port(dst_name, dst_port)
    body[body_count++] = sprintf("  // External Input: %s", src_name)
    body[body_count++] = sprintf("  assign u_%s.%s = %s;", dst_name, dst_v, src_name)
}

/^flow/ {
    src_port = $3; src_name = $5; dst_port = $8; dst_name = $10
    wire_count++; wire_name = "w_" wire_count
    body[body_count++] = sprintf("  wire %s;", wire_name)
    src_v = get_out_port(src_name)
    dst_v = get_in_port(dst_name, dst_port)
    body[body_count++] = sprintf("  assign %s = u_%s.%s;", wire_name, src_name, src_v)
    body[body_count++] = sprintf("  assign u_%s.%s = %s;", dst_name, dst_v, wire_name)
}

/^separate/ {
    src_port = $3; src_name = $5; dst1 = $7; dst2 = $9
    wire_count++
    body[body_count++] = sprintf("  // Async Fork: separate %s", src_name)
    body[body_count++] = sprintf("  wire w_sep_%d_a, w_sep_%d_b;", wire_count, wire_count)
    src_v = get_out_port(src_name)
    dst_v1 = get_in_port(dst1, "input"); dst_v2 = get_in_port(dst2, "input")
    body[body_count++] = sprintf("  assign w_sep_%d_a = u_%s.%s;", wire_count, src_name, src_v)
    body[body_count++] = sprintf("  assign w_sep_%d_b = u_%s.%s;", wire_count, src_name, src_v)
    body[body_count++] = sprintf("  assign u_%s.%s = w_sep_%d_a;", dst1, dst_v1, wire_count)
    body[body_count++] = sprintf("  assign u_%s.%s = w_sep_%d_b;", dst2, dst_v2, wire_count)
}

/^combine/ {
    src_port = $3; src1 = $5; src2 = $7; dst_port = $10; dst_name = $12
    wire_count++
    body[body_count++] = sprintf("  // Async Join (AND): combine %s and %s into %s", src1, src2, dst_name)
    body[body_count++] = sprintf("  wire w_join_%d_req, w_join_%d_ack;", wire_count, wire_count)
    body[body_count++] = sprintf("  async_wddl_join u_join_%d (", wire_count)
    body[body_count++] = "    .rst_n(rst_n),"
    body[body_count++] = sprintf("    .req_a(u_%s.%s), .ack_a(),", src1, get_out_port(src1))
    body[body_count++] = sprintf("    .req_b(u_%s.%s), .ack_b(),", src2, get_out_port(src2))
    body[body_count++] = sprintf("    .req_out(w_join_%d_req), .ack_in(1'b0)", wire_count)
    body[body_count++] = "  );"
    body[body_count++] = sprintf("  assign u_%s.%s = w_join_%d_req;", dst_name, get_in_port(dst_name, dst_port), wire_count)
}

/^merge/ {
    src_port = $3; src1 = $5; src2 = $7; dst_port = $10; dst_name = $12
    wire_count++
    body[body_count++] = sprintf("  // Async Merge (OR): merge %s and %s into %s", src1, src2, dst_name)
    body[body_count++] = sprintf("  wire w_merge_%d_req, w_merge_%d_ack_a, w_merge_%d_ack_b;", wire_count, wire_count, wire_count)
    body[body_count++] = sprintf("  async_wddl_merge u_merge_%d (", wire_count)
    body[body_count++] = "    .rst_n(rst_n),"
    body[body_count++] = sprintf("    .req_a(u_%s.%s), .ack_a(w_merge_%d_ack_a),", src1, get_out_port(src1), wire_count)
    body[body_count++] = sprintf("    .req_b(u_%s.%s), .ack_b(w_merge_%d_ack_b),", src2, get_out_port(src2), wire_count)
    body[body_count++] = sprintf("    .req_out(w_merge_%d_req), .ack_in(1'b0)", wire_count)
    body[body_count++] = "  );"
    body[body_count++] = sprintf("  assign u_%s.%s = w_merge_%d_req;", dst_name, get_in_port(dst_name, dst_port), wire_count)
}

/^route/ {
    src_port = $3; src_name = $5; router_name = $7; dst_name = $9
    wire_count++
    body[body_count++] = sprintf("  // Async Mesh Route: %s -> %s -> %s", src_name, router_name, dst_name)
    body[body_count++] = sprintf("  wire w_route_%d_req, w_route_%d_ack;", wire_count, wire_count)
    src_v = get_out_port(src_name)
    body[body_count++] = sprintf("  assign u_%s.local_req = u_%s.%s;", router_name, src_name, src_v)
    body[body_count++] = sprintf("  assign w_route_%d_ack = u_%s.local_ack;", wire_count, router_name)
    dst_v_req = get_in_port(dst_name, "input")
    body[body_count++] = sprintf("  assign w_route_%d_req = u_%s.east_req;", wire_count, router_name)
    body[body_count++] = sprintf("  assign u_%s.%s = w_route_%d_req;", dst_name, dst_v_req, wire_count)
    body[body_count++] = sprintf("  assign u_%s.east_ack = u_%s.ack_out;", router_name, dst_name)
    
    proof_count++
    proof[proof_count] = sprintf("  // FORMAL PROOF %d: Deadlock Freedom", proof_count)
    proof[proof_count] = proof[proof_count] sprintf("\n  property deadlock_free_%d;", wire_count)
    proof[proof_count] = proof[proof_count] sprintf("\n    @(posedge rst_n or posedge w_route_%d_req) disable iff (!rst_n)", wire_count)
    proof[proof_count] = proof[proof_count] sprintf("\n    (u_%s.local_req == 1'b1) |-> ##[0:20] (u_%s.east_ack == 1'b1);", router_name, router_name)
    proof[proof_count] = proof[proof_count] sprintf("\n  endproperty\n  assert property (deadlock_free_%d);", wire_count)
}

/^morph/ {
    src_port = $3; src_name = $5; router_name = $7; dst_name = $9; key_val = $12
    wire_count++
    body[body_count++] = sprintf("  // FEATURE 2: Metamorphic Route: %s -> %s -> %s", src_name, router_name, dst_name)
    body[body_count++] = sprintf("  wire w_morph_%d_req, w_morph_%d_ack;", wire_count, wire_count)
    src_v = get_out_port(src_name)
    body[body_count++] = sprintf("  assign u_%s.req_in = u_%s.%s;", router_name, src_name, src_v)
    body[body_count++] = sprintf("  assign w_morph_%d_ack = u_%s.ack_out;", wire_count, router_name)
    dst_v_req = get_in_port(dst_name, "input")
    body[body_count++] = sprintf("  assign w_morph_%d_req = u_%s.req_out;", wire_count, router_name)
    body[body_count++] = sprintf("  assign u_%s.%s = w_morph_%d_req;", dst_name, dst_v_req, wire_count)
    body[body_count++] = sprintf("  assign u_%s.ack_in = u_%s.ack_out;", router_name, dst_name)
    for(i=0; i<comp_count; i++) {
        if (comp_name[i] == router_name) comp_key[i] = key_val
    }
}

END {
    print "module umml_top("
    print "  input logic rst_n"
    
    # FIX: Deduplicate inputs before printing
    unique_count = 0
    for (i=0; i<input_count; i++) {
        if (!seen[inputs[i]]) {
            seen[inputs[i]] = 1
            unique_inputs[unique_count++] = inputs[i]
        }
    }
    
    if (unique_count > 0) {
        print ","
        for (i=0; i<unique_count; i++) {
            if (i == unique_count - 1) printf "  input logic %s\n", unique_inputs[i]
            else printf "  input logic %s,\n", unique_inputs[i]
        }
    }
    print ");"
    
    for(i=0; i<comp_count; i++) {
        name = comp_name[i]; type = comp_type_arr[i]
        if (type == "neuron") {
            printf "  async_lif_neuron #(.THRESHOLD(%d), .LEAK(%d)) u_%s (\n", comp_thresh[i], comp_leak[i], name
            print "    .rst_n(rst_n), .req_in(), .ack_out(),"
            print "    .data_in_t(16'd1), .data_in_f(~16'd1),"
            printf "    .spike_req(%s_spike), .spike_ack()\n  );\n", name
        } else if (type == "synapse") {
            printf "  async_stdp_rule #(.TRACE_MAX(%d)) u_%s (\n", comp_trace[i], name
            print "    .rst_n(rst_n), .pre_req(), .pre_ack(), .post_req(), .post_ack(),"
            print "    .update_req(), .update_ack(), .update_data_t(), .update_data_f()\n  );"
        } else if (type == "memory") {
            printf "  async_memory_cell #(.DATA_W(%d)) u_%s (\n", comp_size[i], name
            print "    .rst_n(rst_n), .wr_req(), .wr_ack(), .wr_data_t(16'd0), .wr_data_f(~16'd0),"
            print "    .rd_req(), .rd_ack(), .rd_data_t(), .rd_data_f()\n  );"
        } else if (type == "router") {
            printf "  async_mesh_router u_%s (\n", name
            print "    .rst_n(rst_n), .west_req(1'b0), .west_ack(), .east_req(), .east_ack(), .local_req(), .local_ack()\n  );"
        } else if (type == "metamorphic_router") {
            printf "  async_metamorphic_router #(.DATA_W(16)) u_%s (\n", name
            print "    .rst_n(rst_n),"
            printf "    .initial_key(%s),\n", comp_key[i]
            print "    .req_in(), .ack_out(), .data_in(16'd0), .req_out(), .ack_in(), .data_out()\n  );"
        }
    }
    
    for (i=0; i<body_count; i++) { print body[i] }
    
    if (proof_count > 0) {
        print "\n  // =========================================="
        print "  // UMML FEATURE 1: SELF-PROVING ASSERTIONS"
        print "  // =========================================="
        for (i=1; i<=proof_count; i++) { print proof[i] }
        print "  // =========================================="
    }
    
    print "endmodule"
}
