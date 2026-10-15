module umml_top(
  input logic rst_n,
  input logic motion_detected
);
  async_lif_neuron #(.THRESHOLD(1), .LEAK(0)) u_secure_room_a (
    .rst_n(rst_n), .req_in(), .ack_out(),
    .data_in_t(16'd1), .data_in_f(~16'd1),
    .spike_req(secure_room_a_spike), .spike_ack()
  );
  async_metamorphic_router #(.DATA_W(16)) u_secure_hallway (
    .rst_n(rst_n),
    .initial_key(8'hA5),
    .req_in(), .ack_out(), .data_in(16'd0), .req_out(), .ack_in(), .data_out()
  );
  async_lif_neuron #(.THRESHOLD(1), .LEAK(0)) u_secure_room_b (
    .rst_n(rst_n), .req_in(), .ack_out(),
    .data_in_t(16'd1), .data_in_f(~16'd1),
    .spike_req(secure_room_b_spike), .spike_ack()
  );
  // External Input: motion_detected
  assign u_secure_room_a.req_in = motion_detected;
  // FEATURE 2: Metamorphic Route: secure_room_a -> secure_hallway -> secure_room_b
  wire w_morph_1_req, w_morph_1_ack;
  assign u_secure_hallway.req_in = u_secure_room_a.spike_req;
  assign w_morph_1_ack = u_secure_hallway.ack_out;
  assign w_morph_1_req = u_secure_hallway.req_out;
  assign u_secure_room_b.req_in = w_morph_1_req;
  assign u_secure_hallway.ack_in = u_secure_room_b.ack_out;
endmodule
