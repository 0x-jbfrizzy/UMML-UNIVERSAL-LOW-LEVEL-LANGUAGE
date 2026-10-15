module umml_top(
  input logic rst_n,
  input logic quarter_inserted
);
  async_memory_cell #(.DATA_W(16)) u_wallet (
    .rst_n(rst_n),
    .wr_req(), .wr_ack(), .wr_data_t(16'd0), .wr_data_f(~16'd0),
    .rd_req(), .rd_ack(), .rd_data_t(), .rd_data_f()
  );
  async_lif_neuron #(.THRESHOLD(1), .LEAK(0)) u_item_dispenser (
    .rst_n(rst_n), .req_in(), .ack_out(),
    .data_in_t(16'd1), .data_in_f(~16'd1),
    .spike_req(item_dispenser_spike), .spike_ack()
  );
  async_lif_neuron #(.THRESHOLD(1), .LEAK(0)) u_coin_slot (
    .rst_n(rst_n), .req_in(), .ack_out(),
    .data_in_t(16'd1), .data_in_f(~16'd1),
    .spike_req(coin_slot_spike), .spike_ack()
  );
  // External Input: quarter_inserted
  assign u_wallet.wr_req = quarter_inserted;
  wire w_1;
  assign w_1 = u_coin_slot.spike_req;
  assign u_item_dispenser.req_in = w_1;
endmodule
