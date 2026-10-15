module umml_top(
  input logic rst_n
);
  async_lif_neuron #(.THRESHOLD(10), .LEAK(0)) u_siren (
    .rst_n(rst_n), .req_in(), .ack_out(), .data_in_t(), .data_in_f(),
    .spike_req(siren_spike), .spike_ack()
  );
  async_stdp_rule #(.TRACE_MAX(10)) u_motion_detector (
    .rst_n(rst_n), .pre_req(), .pre_ack(), .post_req(), .post_ack(),
    .update_req(motion_detector_update), .update_ack(), .update_data_t(), .update_data_f()
  );
  async_stdp_rule #(.TRACE_MAX(10)) u_door_sensor (
    .rst_n(rst_n), .pre_req(), .pre_ack(), .post_req(), .post_ack(),
    .update_req(door_sensor_update), .update_ack(), .update_data_t(), .update_data_f()
  );
  // External Input: physical_motion
  assign u_motion_detector.req_in = 1;
  // External Input: physical_door
  assign u_door_sensor.req_in = 1;
  // Async Join (C-Element): combine motion_detector and door_sensor into siren
  wire w_join_1_req, w_join_1_ack;
  async_wddl_join u_join_1 (
    .rst_n(rst_n),
    .req_a(u_motion_detector.spike_req), .ack_a(),
    .req_b(u_door_sensor.spike_req), .ack_b(),
    .req_out(w_join_1_req), .ack_in(1'b0)
  );
  assign u_siren.req_in = w_join_1_req;
endmodule
