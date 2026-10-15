module umml_top(
  input logic rst_n,
  input logic physical_motion,
  input logic physical_door
);
  async_lif_neuron #(.THRESHOLD(1), .LEAK(0)) u_motion_detector (
    .rst_n(rst_n), .req_in(), .ack_out(),
    .data_in_t(16'd1), .data_in_f(~16'd1),
    .spike_req(motion_detector_spike), .spike_ack()
  );
  async_lif_neuron #(.THRESHOLD(1), .LEAK(0)) u_door_sensor (
    .rst_n(rst_n), .req_in(), .ack_out(),
    .data_in_t(16'd1), .data_in_f(~16'd1),
    .spike_req(door_sensor_spike), .spike_ack()
  );
  async_lif_neuron #(.THRESHOLD(1), .LEAK(0)) u_siren (
    .rst_n(rst_n), .req_in(), .ack_out(),
    .data_in_t(16'd1), .data_in_f(~16'd1),
    .spike_req(siren_spike), .spike_ack()
  );
  // External Input: physical_motion
  assign u_motion_detector.req_in = physical_motion;
  // External Input: physical_door
  assign u_door_sensor.req_in = physical_door;
  // Async Merge (OR): merge motion_detector and door_sensor into siren
  wire w_merge_1_req, w_merge_1_ack_a, w_merge_1_ack_b;
  async_wddl_merge u_merge_1 (
    .rst_n(rst_n),
    .req_a(u_motion_detector.spike_req), .ack_a(w_merge_1_ack_a),
    .req_b(u_door_sensor.spike_req), .ack_b(w_merge_1_ack_b),
    .req_out(w_merge_1_req), .ack_in(1'b0)
  );
  assign u_siren.req_in = w_merge_1_req;
endmodule
