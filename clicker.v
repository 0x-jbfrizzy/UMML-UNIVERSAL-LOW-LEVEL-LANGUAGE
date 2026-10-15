module umml_top(
  input logic rst_n,
  input logic player_click
);
  async_lif_neuron #(.THRESHOLD(5), .LEAK(0)) u_score (
    .rst_n(rst_n), .req_in(), .ack_out(),
    .data_in_t(16'd1), .data_in_f(~16'd1),
    .spike_req(score_spike), .spike_ack()
  );
  async_lif_neuron #(.THRESHOLD(1), .LEAK(0)) u_reward (
    .rst_n(rst_n), .req_in(), .ack_out(),
    .data_in_t(16'd1), .data_in_f(~16'd1),
    .spike_req(reward_spike), .spike_ack()
  );
  // External Input: player_click
  assign u_score.req_in = player_click;
  wire w_1;
  assign w_1 = u_score.spike_req;
  assign u_reward.req_in = w_1;
endmodule
