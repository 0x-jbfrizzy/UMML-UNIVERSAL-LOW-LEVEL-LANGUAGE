module umml_top(
  input logic rst_n
);
  async_lif_neuron #(.THRESHOLD(10), .LEAK(5)) u_kick_drum (
    .rst_n(rst_n), .req_in(), .ack_out(), .data_in_t(), .data_in_f(),
    .spike_req(kick_drum_spike), .spike_ack()
  );
  async_lif_neuron #(.THRESHOLD(15), .LEAK(3)) u_snare_drum (
    .rst_n(rst_n), .req_in(), .ack_out(), .data_in_t(), .data_in_f(),
    .spike_req(snare_drum_spike), .spike_ack()
  );
  async_lif_neuron #(.THRESHOLD(20), .LEAK(1)) u_master_output (
    .rst_n(rst_n), .req_in(), .ack_out(), .data_in_t(), .data_in_f(),
    .spike_req(master_output_spike), .spike_ack()
  );
  // External Input: midi_kick_trigger
  assign u_kick_drum.req_in = 1;
  // External Input: midi_snare_trigger
  assign u_snare_drum.req_in = 1;
  // Async Fork: separate kick_drum
  wire w_sep_1_a, w_sep_1_b;
  assign w_sep_1_a = u_kick_drum.spike_req;
  assign w_sep_1_b = u_kick_drum.spike_req;
  assign u_effect_a.req_in = w_sep_1_a;
  assign u_effect_b.req_in = w_sep_1_b;
  // Async Fork: separate snare_drum
  wire w_sep_2_a, w_sep_2_b;
  assign w_sep_2_a = u_snare_drum.spike_req;
  assign w_sep_2_b = u_snare_drum.spike_req;
  assign u_effect_c.req_in = w_sep_2_a;
  assign u_effect_d.req_in = w_sep_2_b;
  // Async Join (C-Element): combine effect_a and effect_c into master_output
  wire w_join_3_req, w_join_3_ack;
  async_wddl_join u_join_3 (
    .rst_n(rst_n),
    .req_a(u_effect_a.spike_req), .ack_a(),
    .req_b(u_effect_c.spike_req), .ack_b(),
    .req_out(w_join_3_req), .ack_in(1'b0)
  );
  assign u_master_output.req_in = w_join_3_req;
endmodule
