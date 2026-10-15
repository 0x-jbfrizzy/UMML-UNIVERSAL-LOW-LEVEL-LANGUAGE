module umml_top(
  input logic rst_n,
  input logic motion_sensor_a,
  input logic motion_sensor_b
);
  async_lif_neuron #(.THRESHOLD(1), .LEAK(0)) u_room_a_light (
    .rst_n(rst_n), .req_in(), .ack_out(),
    .data_in_t(16'd1), .data_in_f(~16'd1),
    .spike_req(room_a_light_spike), .spike_ack()
  );
  async_mesh_router u_hallway_router (
    .rst_n(rst_n),
    .west_req(1'b0), .west_ack(),
    .east_req(), .east_ack(),
    .local_req(), .local_ack()
  );
  async_lif_neuron #(.THRESHOLD(1), .LEAK(0)) u_room_b_light (
    .rst_n(rst_n), .req_in(), .ack_out(),
    .data_in_t(16'd1), .data_in_f(~16'd1),
    .spike_req(room_b_light_spike), .spike_ack()
  );
  // External Input: motion_sensor_a
  assign u_room_a_light.req_in = motion_sensor_a;
  // External Input: motion_sensor_b
  assign u_room_b_light.req_in = motion_sensor_b;
  // Async Mesh Route: room_a_light -> hallway_router -> room_b_light
  wire w_route_1_req, w_route_1_ack;
  assign u_hallway_router.local_req = u_room_a_light.spike_req;
  assign u_hallway_router.local_ack = w_route_1_ack;
  assign w_route_1_req = u_hallway_router.east_req;
  assign u_room_b_light.req_in = w_route_1_req;
  assign u_hallway_router.east_ack = u_room_b_light.ack_out;
endmodule
