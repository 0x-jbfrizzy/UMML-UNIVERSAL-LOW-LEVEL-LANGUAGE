BEGIN {
    input_count = 0
    body_count = 0
    wire_count = 0
}

/^#/ || /^$/ { next }

/^make/ {
    type = $3; name = $5
    comp_type[name] = type
    
    thresh = 20; leak = 2; trace = 15; size = 16
    for(i=1; i<=NF; i++) {
        if ($i == "threshold") thresh = $(i+1)
        if ($i == "leak") leak = $(i+1)
        if ($i == "trace") trace = $(i+1)
        if ($i == "size") size = $(i+1)
    }
    if (type == "neuron") {
        body[body_count++] = sprintf("  async_lif_neuron #(.THRESHOLD(%d), .LEAK(%d)) u_%s (", thresh, leak, name)
        body[body_count++] = "    .rst_n(rst_n), .req_in(), .ack_out(),"
        body[body_count++] = "    .data_in_t(16'd1), .data_in_f(~16'd1),"
        body[body_count++] = sprintf("    .spike_req(%s_spike), .spike_ack()", name)
        body[body_count++] = "  );"
    } else if (type == "synapse") {
        body[body_count++] = sprintf("  async_stdp_rule #(.TRACE_MAX(%d)) u_%s (", trace, name)
        body[body_count++] = "    .rst_n(rst_n), .pre_req(), .pre_ack(), .post_req(), .post_ack(),"
        body[body_count++] = "    .update_req(), .update_ack(), .update_data_t(), .update_data_f()"
        body[body_count++] = "  );"
    } else if (type == "memory") {
        body[body_count++] = sprintf("  async_memory_cell #(.DATA_W(%d)) u_%s (", size, name)
        body[body_count++] = "    .rst_n(rst_n),"
        body[body_count++] = "    .wr_req(), .wr_ack(), .wr_data_t(16'd0), .wr_data_f(~16'd0),"
        body[body_count++] = "    .rd_req(), .rd_ack(), .rd_data_t(), .rd_data_f()"
        body[body_count++] = "  );"
    }
}

function get_out_port(name) {
    if (comp_type[name] == "neuron") return "spike_req"
    if (comp_type[name] == "synapse") return "update_req"
    return "req_out"
}

function get_in_port(name, port_hint) {
    if (port_hint == "pre") return "pre_req"
    if (port_hint == "post") return "post_req"
    if (port_hint == "write") return "wr_req"
    if (port_hint == "read") return "rd_req"
    if (comp_type[name] == "neuron") return "req_in"
    if (comp_type[name] == "synapse") return "pre_req"
    if (comp_type[name] == "memory") return "wr_req" # Default to write for memory
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
    dst_v1 = get_in_port(dst1, "input")
    dst_v2 = get_in_port(dst2, "input")
    
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

END {
    print "module umml_top("
    print "  input logic rst_n,"
    for (i=0; i<input_count; i++) {
        if (i == input_count - 1) printf "  input logic %s\n", inputs[i]
        else printf "  input logic %s,\n", inputs[i]
    }
    print ");"
    for (i=0; i<body_count; i++) {
        print body[i]
    }
    print "endmodule"
}

/^route/ {
    # "route the spike from brain1 to brain2 through the mesh"
    src_name = $5; dst_name = $9
    wire_count++
    body[body_count++] = sprintf("  // Async Mesh Route: %s to %s", src_name, dst_name)
    body[body_count++] = sprintf("  wire w_route_%d_req, w_route_%d_ack;", wire_count, wire_count)
    body[body_count++] = sprintf("  assign w_route_%d_req = u_%s.spike_req;", wire_count, src_name)
    body[body_count++] = sprintf("  assign u_%s.req_in = w_route_%d_req;", dst_name, wire_count)
}
