module umml_top(
  input logic rst_n,
  input logic clk_in
);
  async_memory_cell #(.DATA_W(16)) u_step_kick (
    .rst_n(rst_n), .wr_req(), .wr_ack(), .wr_data_t(16'd0), .wr_data_f(~16'd0),
    .rd_req(), .rd_ack(), .rd_data_t(), .rd_data_f()
  );
  async_memory_cell #(.DATA_W(16)) u_step_snare (
    .rst_n(rst_n), .wr_req(), .wr_ack(), .wr_data_t(16'd0), .wr_data_f(~16'd0),
    .rd_req(), .rd_ack(), .rd_data_t(), .rd_data_f()
  );
  async_lif_neuron #(.THRESHOLD(1), .LEAK(0)) u_kick_drum (
    .rst_n(rst_n), .req_in(), .ack_out(),
    .data_in_t(16'd1), .data_in_f(~16'd1),
    .spike_req(kick_drum_spike), .spike_ack()
  );
  async_lif_neuron #(.THRESHOLD(1), .LEAK(0)) u_snare_drum (
    .rst_n(rst_n), .req_in(), .ack_out(),
    .data_in_t(16'd1), .data_in_f(~16'd1),
    .spike_req(snare_drum_spike), .spike_ack()
  );
  async_metamorphic_router #(.DATA_W(16)) u_secure_bus_kick (
    .rst_n(rst_n),
    .initial_key(8'hF0),
    .req_in(), .ack_out(), .data_in(16'd0), .req_out(), .ack_in(), .data_out()
  );
  async_metamorphic_router #(.DATA_W(16)) u_secure_bus_snare (
    .rst_n(rst_n),
    .initial_key(8'hA5),
    .req_in(), .ack_out(), .data_in(16'd0), .req_out(), .ack_in(), .data_out()
  );
  async_lif_neuron #(.THRESHOLD(1), .LEAK(0)) u_tempo_master (
    .rst_n(rst_n), .req_in(), .ack_out(),
    .data_in_t(16'd1), .data_in_f(~16'd1),
    .spike_req(tempo_master_spike), .spike_ack()
  );
  // FEATURE 4: Deterministic Clock Spine Initialization
  logic spine_enable;
  logic isolated_init_clk;
  async_clock_spine u_spine (
    .global_clk(clk_in),
    .rst_n(rst_n),
    .spine_enable(spine_enable),
    .isolated_clk(isolated_init_clk)
  );
  // FEATURE 2: Metamorphic Route: step_kick -> secure_bus_kick -> kick_drum
  wire w_morph_1_req, w_morph_1_ack;
  assign u_secure_bus_kick.req_in = u_step_kick.rd_ack;
  assign w_morph_1_ack = u_secure_bus_kick.ack_out;
  assign w_morph_1_req = u_secure_bus_kick.req_out;
  assign u_kick_drum.req_in = w_morph_1_req;
  assign u_secure_bus_kick.ack_in = u_kick_drum.ack_out;
  // FEATURE 2: Metamorphic Route: step_snare -> secure_bus_snare -> snare_drum
  wire w_morph_2_req, w_morph_2_ack;
  assign u_secure_bus_snare.req_in = u_step_snare.rd_ack;
  assign w_morph_2_ack = u_secure_bus_snare.ack_out;
  assign w_morph_2_req = u_secure_bus_snare.req_out;
  assign u_snare_drum.req_in = w_morph_2_req;
  assign u_secure_bus_snare.ack_in = u_snare_drum.ack_out;
  wire w_3;
  assign w_3 = u_tempo_master.spike_req;
  assign u_step_kick.rd_req = w_3;
  wire w_4;
  assign w_4 = u_tempo_master.spike_req;
  assign u_step_snare.rd_req = w_4;
endmodule
