`timescale 1ns/1ps

// ==========================================
// STAGE 5.1 & 5.2: HARDWARE COMPILER & CROSSBAR
// ==========================================
module grid_compiler_node (
    input wire clk, rst,
    input wire [7:0] char_in,
    input wire char_valid,
    output reg [1:0] route_src,
    output reg [1:0] route_dst,
    output reg route_configured
);
    localparam [7:0] C=8'd67, O=8'd79, N=8'd78, E=8'd69, T=8'd84;
    reg [7:0] shift_conn [0:6];
    reg [1:0] state; 

    always @(posedge clk) begin
        if (rst) begin
            state <= 2'd0; route_configured <= 1'b0;
        end else begin
            if (char_valid) begin
                shift_conn[0] <= shift_conn[1]; shift_conn[1] <= shift_conn[2];
                shift_conn[2] <= shift_conn[3]; shift_conn[3] <= shift_conn[4];
                shift_conn[4] <= shift_conn[5]; shift_conn[5] <= shift_conn[6];
                shift_conn[6] <= char_in;

                case (state)
                    2'd0: begin 
                        if (shift_conn[0]==C && shift_conn[1]==O && shift_conn[2]==N && 
                            shift_conn[3]==N && shift_conn[4]==E && shift_conn[5]==C && shift_conn[6]==T) 
                            state <= 2'd1; 
                    end
                    2'd1: begin 
                        if (char_in >= 8'd48 && char_in <= 8'd49) begin 
                            route_src <= char_in - 8'd48; state <= 2'd2; 
                        end
                    end
                    2'd2: begin 
                        if (char_in == 8'd84) state <= 2'd3; 
                    end
                    2'd3: begin 
                        if (char_in >= 8'd48 && char_in <= 8'd49) begin
                            route_dst <= char_in - 8'd48; state <= 2'd0;
                            route_configured <= 1'b1; 
                        end
                    end
                endcase
            end
        end
    end
endmodule

module crossbar_node (
    input wire clk, rst,
    input wire [1:0] route_src, input wire [1:0] route_dst,
    input wire route_configured,
    input wire [15:0] in_0_data, in_1_data,
    input wire in_0_ready, in_1_ready,
    output reg [15:0] out_0_data, out_1_data,
    output reg out_0_ready, out_1_ready
);
    reg [1:0] src_reg, dst_reg; reg configured;
    always @(posedge clk) begin
        if (rst) begin configured <= 1'b0; out_0_ready <= 1'b0; out_1_ready <= 1'b0; end 
        else begin
            if (route_configured) begin src_reg <= route_src; dst_reg <= route_dst; configured <= 1'b1; end
            out_0_ready <= 1'b0; out_1_ready <= 1'b0;
            if (configured) begin
                if (dst_reg == 2'd0) begin out_0_data <= (src_reg == 2'd0) ? in_0_data : in_1_data; out_0_ready <= (src_reg == 2'd0) ? in_0_ready : in_1_ready; end 
                else if (dst_reg == 2'd1) begin out_1_data <= (src_reg == 2'd0) ? in_0_data : in_1_data; out_1_ready <= (src_reg == 2'd0) ? in_0_ready : in_1_ready; end
            end
        end
    end
endmodule

// ==========================================
// STAGE 5.3: MEMORY & POWER MONITOR
// ==========================================
module memory_node (
    input wire clk, rst,
    input wire [1:0] write_addr, input wire [15:0] write_data, input wire write_valid,
    input wire [1:0] read_addr, input wire read_valid,
    output reg [15:0] read_data, output reg read_ready
);
    reg [15:0] mem [0:3]; reg busy;
    reg prev_write_valid, prev_read_valid;
    wire write_pulse = write_valid && !prev_write_valid;
    wire read_pulse = read_valid && !prev_read_valid;

    always @(posedge clk) begin
        prev_write_valid <= write_valid; prev_read_valid <= read_valid;
        if (rst) begin read_ready <= 1'b0; busy <= 1'b0; mem[0]<=0; mem[1]<=0; mem[2]<=0; mem[3]<=0; end 
        else begin
            if (write_pulse) mem[write_addr] <= write_data;
            if (read_pulse) begin busy <= 1'b1; read_ready <= 1'b0; end 
            else if (busy) begin read_data <= mem[read_addr]; read_ready <= 1'b1; busy <= 1'b0; end
        end
    end
endmodule

module power_monitor_node (
    input wire clk, rst,
    input wire [15:0] data_bus, input wire data_valid, 
    output reg [4:0] power_draw, output reg power_valid
);
    integer k; reg [4:0] temp_count;
    reg prev_data_valid; wire data_pulse = data_valid && !prev_data_valid;
    always @(posedge clk) begin
        prev_data_valid <= data_valid;
        if (rst) begin power_draw <= 5'd0; power_valid <= 1'b0; end 
        else begin
            if (data_pulse) begin
                temp_count = 0;
                for (k = 0; k < 16; k = k + 1) if (data_bus[k]) temp_count = temp_count + 1;
                power_draw <= temp_count; power_valid <= 1'b1; 
            end else power_valid <= 1'b0;
        end
    end
endmodule

// ==========================================
// STAGE 5.4: DUAL-RAIL CRYPTO & CONSTANT TIME
// ==========================================
module dual_rail_encoder_32 (
    input wire clk, rst, input wire [31:0] single_rail_data, input wire data_valid,
    output reg [63:0] dual_rail_data, output reg data_ready
);
    integer i;
    always @(posedge clk) begin
        if (rst) begin dual_rail_data <= 64'd0; data_ready <= 1'b0; end 
        else begin
            data_ready <= 1'b0;
            if (data_valid) begin
                for (i = 0; i < 32; i = i + 1) begin
                    dual_rail_data[i] <= single_rail_data[i];
                    dual_rail_data[i + 32] <= ~single_rail_data[i];
                end
                data_ready <= 1'b1;
            end
        end
    end
endmodule

module constant_time_node (
    input wire clk, rst, input wire secret_bit, input wire data_valid,
    output reg [7:0] result, output reg result_ready
);
    reg [2:0] counter; reg busy; reg [7:0] path_1_result, path_0_result;
    always @(posedge clk) begin
        if (rst) begin counter <= 3'd0; busy <= 1'b0; result_ready <= 1'b0; result <= 8'd0; end 
        else begin
            result_ready <= 1'b0;
            if (data_valid && !busy) begin
                busy <= 1'b1; counter <= 3'd5;
                path_1_result <= 8'hFF; path_0_result <= 8'h00; 
            end else if (busy) begin
                if (counter > 3'd1) counter <= counter - 3'd1;
                else begin result <= secret_bit ? path_1_result : path_0_result; result_ready <= 1'b1; busy <= 1'b0; end
            end
        end
    end

// ==========================================
// STAGE 5.5: DECENTRALIZED DATAFLOW SWARM NODE
// ==========================================
module swarm_node (
    input wire clk, rst, 
    input wire [15:0] op_a, op_b, 
    input wire op_valid,
    input wire [3:0] configured_latency, 
    output reg [15:0] result, 
    output reg result_ready
);
    reg [3:0] counter; 
    reg busy; 
    reg [15:0] latch_a, latch_b;
    
    always @(posedge clk) begin
        if (rst) begin 
            counter <= 0; 
            busy <= 0; 
            result <= 0; 
            result_ready <= 0; 
        end else begin
            result_ready <= 0;
            if (op_valid && !busy) begin 
                latch_a <= op_a; 
                latch_b <= op_b; 
                counter <= configured_latency; 
                busy <= 1; 
            end else if (busy) begin
                if (counter > 1) counter <= counter - 1;
                else begin 
                    result <= latch_a * latch_b; 
                    result_ready <= 1; 
                    busy <= 0; 
                end
            end
        end
    end
endmodule
endmodule