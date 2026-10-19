module umml_top (
  input logic clk,
  input logic rst_n,
  input logic [15:0] speed_selector,
  input logic right_stick_press,
  input logic right_stick_backward_hold,
  input logic nav_forward,
  input logic nav_backward,
  input logic nav_left,
  input logic nav_right,
  input logic shoe_emergency_button,
  input logic tether_severed,
  input logic empty_battery,
  output logic [15:0] thruster_left,
  output logic [15:0] thruster_right
);

  // State machine: vertical_mode
  typedef enum logic [2:0] {ascend, hover, descend} vertical_mode_state_t;
  vertical_mode_state_t vertical_mode_state, vertical_mode_next_state;

  // State machine logic for vertical_mode
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) vertical_mode_state <= ascend;
    else vertical_mode_state <= vertical_mode_next_state;
  end

  always_comb begin
    vertical_mode_next_state = vertical_mode_state;
    case (vertical_mode_state)
      ascend: begin
      end
      hover: begin
      end
      descend: begin
      end
    endcase
  end

  // Emergency override logic
  always_comb begin
    if (tether_severed) vertical_mode_next_state = descend;
    if (empty_battery) vertical_mode_next_state = descend;
  end

endmodule                                                                                     
