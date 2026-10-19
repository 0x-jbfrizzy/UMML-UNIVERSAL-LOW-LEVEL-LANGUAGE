module umml_top (
  input logic clk,
  input logic rst_n,
  input logic [15:0] skirt_pressure,
  input logic [15:0] battery_current,
  input logic [15:0] battery_temp,
  input logic [15:0] blower_rpm,
  input logic [0:0] emergency_button,
  output logic [15:0] blower_pwm,
  output logic [0:0] main_contactor
);

  // State machine: flight_state
  typedef enum logic [2:0] {GROUND, SPIN_UP, HOVER, EMERGENCY_DESCENT} flight_state_state_t;
  flight_state_state_t flight_state_state, flight_state_next_state;

  // State machine logic for flight_state
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) flight_state_state <= GROUND;
    else flight_state_state <= flight_state_next_state;
  end

  always_comb begin
    flight_state_next_state = flight_state_state;
    if (emergency_button == 0) flight_state_next_state = EMERGENCY_DESCENT;
    if (skirt_pressure < 1000) flight_state_next_state = EMERGENCY_DESCENT;
    if (battery_current > 4000) flight_state_next_state = EMERGENCY_DESCENT;
    if (battery_temp > 3500) flight_state_next_state = EMERGENCY_DESCENT;
    if (blower_rpm < 500) flight_state_next_state = EMERGENCY_DESCENT;
    case (flight_state_state)
      GROUND: begin
      end
      SPIN_UP: begin
      end
      HOVER: begin
      end
      EMERGENCY_DESCENT: begin
      end
    endcase
  end

  `ifdef FORMAL
  // ==========================================
  // MATHEMATICAL PROOFS (SVA)
  // ==========================================
  property safety_override_0;
    @(posedge clk) disable iff (!rst_n)
    (emergency_button == 0) |-> (flight_state_next_state == EMERGENCY_DESCENT);
  endproperty
  assert property (safety_override_0);

  property safety_sticky_0;
    @(posedge clk) disable iff (!rst_n)
    (flight_state_state == EMERGENCY_DESCENT) |=> (flight_state_next_state == EMERGENCY_DESCENT);
  endproperty
  assert property (safety_sticky_0);

  property safety_override_1;
    @(posedge clk) disable iff (!rst_n)
    (skirt_pressure < 1000) |-> (flight_state_next_state == EMERGENCY_DESCENT);
  endproperty
  assert property (safety_override_1);

  property safety_sticky_1;
    @(posedge clk) disable iff (!rst_n)
    (flight_state_state == EMERGENCY_DESCENT) |=> (flight_state_next_state == EMERGENCY_DESCENT);
  endproperty
  assert property (safety_sticky_1);

  property safety_override_2;
    @(posedge clk) disable iff (!rst_n)
    (battery_current > 4000) |-> (flight_state_next_state == EMERGENCY_DESCENT);
  endproperty
  assert property (safety_override_2);

  property safety_sticky_2;
    @(posedge clk) disable iff (!rst_n)
    (flight_state_state == EMERGENCY_DESCENT) |=> (flight_state_next_state == EMERGENCY_DESCENT);
  endproperty
  assert property (safety_sticky_2);

  property safety_override_3;
    @(posedge clk) disable iff (!rst_n)
    (battery_temp > 3500) |-> (flight_state_next_state == EMERGENCY_DESCENT);
  endproperty
  assert property (safety_override_3);

  property safety_sticky_3;
    @(posedge clk) disable iff (!rst_n)
    (flight_state_state == EMERGENCY_DESCENT) |=> (flight_state_next_state == EMERGENCY_DESCENT);
  endproperty
  assert property (safety_sticky_3);

  property safety_override_4;
    @(posedge clk) disable iff (!rst_n)
    (blower_rpm < 500) |-> (flight_state_next_state == EMERGENCY_DESCENT);
  endproperty
  assert property (safety_override_4);

  property safety_sticky_4;
    @(posedge clk) disable iff (!rst_n)
    (flight_state_state == EMERGENCY_DESCENT) |=> (flight_state_next_state == EMERGENCY_DESCENT);
  endproperty
  assert property (safety_sticky_4);

  `endif

endmodule
