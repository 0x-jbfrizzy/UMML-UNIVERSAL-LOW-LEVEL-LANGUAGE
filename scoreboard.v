module umml_top(
  input logic rst_n,
  input logic player_button
);
  async_memory_cell #(.DATA_W(16)) u_high_score (
    .rst_n(rst_n),
    .wr_req(), .wr_ack(), .wr_data_t(16'd0), .wr_data_f(~16'd0),
    .rd_req(), .rd_ack(), .rd_data_t(), .rd_data_f()
  );
  async_lif_neuron #(.THRESHOLD(1), .LEAK(0)) u_player_action (
    .rst_n(rst_n), .req_in(), .ack_out(),
    .data_in_t(16'd1), .data_in_f(~16'd1),
    .spike_req(player_action_spike), .spike_ack()
  );
  // External Input: player_button
  assign u_high_score.wr_req = player_button;
  wire w_1;
  assign w_1 = u_player_action.spike_req;
  assign u_high_score.rd_req = w_1;
endmodule
