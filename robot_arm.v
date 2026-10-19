module umml_top (
  input logic clk,
  input logic rst_n,
  input logic [0:0] collision_sensor,
  input logic [15:0] motor_temp,
  output logic [0:0] emergency_brake,
  output logic [15:0] joint_velocity
);

  // State machine: arm_control
  typedef enum logic [2:0] {IDLE, MOVING, FAULT} arm_control_state_t;
  arm_control_state_t arm_control_state, arm_control_next_state;

  // State machine logic for arm_control
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) arm_control_state <= IDLE;
    else arm_control_state <= arm_control_next_state;
  end

  always_comb begin
    arm_control_next_state = arm_control_state;
    case (arm_control_state)
      IDLE: begin
      end
      MOVING: begin
      end
      FAULT: begin
      end
    endcase
  end

  // Emergency override logic
  always_comb begin
    if (collision_sensor) arm_control_next_state = FAULT;
    if (motor_temp > 4095) arm_control_next_state = FAULT;
  end


endmodule
