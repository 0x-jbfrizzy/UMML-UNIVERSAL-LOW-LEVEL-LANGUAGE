BEGIN {
    print "module umml_top("
    print "  input logic rst_n"
    print ");"
    wire_count = 0
}

/^#/ || /^$/ { next }

/^make/ {
    type = $3; name = $5
    thresh = 20; leak = 2; trace = 15
    for(i=1; i<=NF; i++) {
        if ($i == "threshold") thresh = $(i+1)
        if ($i == "leak") leak = $(i+1)
        if ($i == "trace") trace = $(i+1)
    }
    if (type == "neuron") {
        printf "  async_lif_neuron #(.THRESHOLD(%d), .LEAK(%d)) u_%s (\n", thresh, leak, name
        printf "    .rst_n(rst_n), .req_in(), .ack_out(), .data_in_t(), .data_in_f(),\n"
        printf "    .spike_req(%s_spike), .spike_ack()\n  );\n", name
    } else if (type == "synapse") {
        printf "  async_stdp_rule #(.TRACE_MAX(%d)) u_%s (\n", trace, name
        printf "    .rst_n(rst_n), .pre_req(), .pre_ack(), .post_req(), .post_ack(),\n"
        printf "    .update_req(%s_update), .update_ack(), .update_data_t(), .update_data_f()\n  );\n", name
    }
}

/^flow/ {
    src_port = $3; src_name = $5; dst_port = $8; dst_name = $10
    wire_count++; wire_name = "w_" wire_count
    printf "  wire %s;\n", wire_name
    
    if (src_port == "spike") src_v = "spike_req"
    else if (src_port == "update") src_v = "update_req"
    else src_v = src_port
    
    if (dst_port == "input") dst_v = "req_in"
    else if (dst_port == "pre") dst_v = "pre_req"
    else if (dst_port == "post") dst_v = "post_req"
    else dst_v = dst_port

    printf "  assign %s = u_%s.%s;\n", wire_name, src_name, src_v
    printf "  assign u_%s.%s = %s;\n", dst_name, dst_v, wire_name
}

/^put/ {
    src_name = $2; dst_port = $5; dst_name = $7
    if (dst_port == "input") dst_v = "req_in"
    else dst_v = dst_port
    printf "  // External Input: %s\n", src_name
    printf "  assign u_%s.%s = 1;\n", dst_name, dst_v
}

/^separate/ {
    src_port = $3; src_name = $5; dst1 = $7; dst2 = $9
    wire_count++
    printf "  // Async Fork: separate %s\n", src_name
    printf "  wire w_sep_%d_a, w_sep_%d_b;\n", wire_count, wire_count
    printf "  assign w_sep_%d_a = u_%s.spike_req;\n", wire_count, src_name
    printf "  assign w_sep_%d_b = u_%s.spike_req;\n", wire_count, src_name
    printf "  assign u_%s.req_in = w_sep_%d_a;\n", dst1, wire_count
    printf "  assign u_%s.req_in = w_sep_%d_b;\n", dst2, wire_count
}

/^combine/ {
    # UPGRADE: Use a true async C-element join instead of a wire OR
    src_port = $3; src1 = $5; src2 = $7; dst_port = $10; dst_name = $12
    wire_count++
    printf "  // Async Join (C-Element): combine %s and %s into %s\n", src1, src2, dst_name
    printf "  wire w_join_%d_req, w_join_%d_ack;\n", wire_count, wire_count
    printf "  async_wddl_join u_join_%d (\n", wire_count
    printf "    .rst_n(rst_n),\n"
    printf "    .req_a(u_%s.spike_req), .ack_a(),\n", src1
    printf "    .req_b(u_%s.spike_req), .ack_b(),\n", src2
    printf "    .req_out(w_join_%d_req), .ack_in(1'b0)\n  );\n", wire_count
    
    if (dst_port == "input") dst_v = "req_in"
    else dst_v = dst_port
    printf "  assign u_%s.%s = w_join_%d_req;\n", dst_name, dst_v, wire_count
}

END {
    print "endmodule"
}
