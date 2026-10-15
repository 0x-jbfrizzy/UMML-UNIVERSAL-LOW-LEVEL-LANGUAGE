module umml_top(
  input logic rst_n
);
  async_lif_neuron #(.THRESHOLD(15), .LEAK(2)) u_eye (
    .rst_n(rst_n), .req_in(), .ack_out(), .data_in_t(), .data_in_f(),
    .spike_req(eye_spike), .spike_ack()
  );
  async_lif_neuron #(.THRESHOLD(30), .LEAK(1)) u_brain (
    .rst_n(rst_n), .req_in(), .ack_out(), .data_in_t(), .data_in_f(),
    .spike_req(brain_spike), .spike_ack()
  );
  async_stdp_rule #(.TRACE_MAX(20)) u_bridge (
    .rst_n(rst_n), .pre_req(), .pre_ack(), .post_req(), .post_ack(),
    .update_req(bridge_update), .update_ack(), .update_data_t(), .update_data_f()
  );
  wire w_1;
  assign w_1 = u_eye.spike_req;
  assign u_bridge.pre_req = w_1;
  wire w_2;
  assign w_2 = u_brain.spike_req;
  assign u_bridge.post_req = w_2;
  wire w_3;
  assign w_3 = u_bridge.update_req;
  assign u_brain.req_in = w_3;
endmodule
