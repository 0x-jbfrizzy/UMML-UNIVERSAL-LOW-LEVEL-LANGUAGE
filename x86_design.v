module umml_top(
  input logic rst_n
);
  async_memory_cell #(.DATA_W(64)) u_reg_rax (
    .rst_n(rst_n), .wr_req(), .wr_ack(), .wr_data_t(16'd0), .wr_data_f(~16'd0),
    .rd_req(), .rd_ack(), .rd_data_t(), .rd_data_f()
  );
  async_memory_cell #(.DATA_W(64)) u_reg_rbx (
    .rst_n(rst_n), .wr_req(), .wr_ack(), .wr_data_t(16'd0), .wr_data_f(~16'd0),
    .rd_req(), .rd_ack(), .rd_data_t(), .rd_data_f()
  );
  async_memory_cell #(.DATA_W(64)) u_reg_rcx (
    .rst_n(rst_n), .wr_req(), .wr_ack(), .wr_data_t(16'd0), .wr_data_f(~16'd0),
    .rd_req(), .rd_ack(), .rd_data_t(), .rd_data_f()
  );
  async_lif_neuron #(.THRESHOLD(1), .LEAK(0)) u_alu_1 (
    .rst_n(rst_n), .req_in(), .ack_out(),
    .data_in_t(16'd1), .data_in_f(~16'd1),
    .spike_req(alu_1_spike), .spike_ack()
  );
  async_lif_neuron #(.THRESHOLD(1), .LEAK(0)) u_alu_2 (
    .rst_n(rst_n), .req_in(), .ack_out(),
    .data_in_t(16'd1), .data_in_f(~16'd1),
    .spike_req(alu_2_spike), .spike_ack()
  );
  // Async Merge (OR): merge reg_rbx and reg_rax into alu_1
  wire w_merge_1_req, w_merge_1_ack_a, w_merge_1_ack_b;
  async_wddl_merge u_merge_1 (
    .rst_n(rst_n),
    .req_a(u_reg_rbx.rd_ack), .ack_a(w_merge_1_ack_a),
    .req_b(u_reg_rax.rd_ack), .ack_b(w_merge_1_ack_b),
    .req_out(w_merge_1_req), .ack_in(1'b0)
  );
  assign u_alu_1.req_in = w_merge_1_req;
  wire w_2;
  assign w_2 = u_alu_1.spike_req;
  assign u_reg_rax.wr_req = w_2;
  // Async Merge (OR): merge reg_rax and reg_rcx into alu_2
  wire w_merge_3_req, w_merge_3_ack_a, w_merge_3_ack_b;
  async_wddl_merge u_merge_3 (
    .rst_n(rst_n),
    .req_a(u_reg_rax.rd_ack), .ack_a(w_merge_3_ack_a),
    .req_b(u_reg_rcx.rd_ack), .ack_b(w_merge_3_ack_b),
    .req_out(w_merge_3_req), .ack_in(1'b0)
  );
  assign u_alu_2.req_in = w_merge_3_req;
  wire w_4;
  assign w_4 = u_alu_2.spike_req;
  assign u_reg_rcx.wr_req = w_4;
endmodule
