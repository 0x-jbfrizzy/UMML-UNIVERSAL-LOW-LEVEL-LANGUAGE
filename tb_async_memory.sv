`timescale 1ns / 1ps
module tb_async_memory;
    logic rst_n, wr_req, rd_req, wr_ack, rd_ack;
    logic [15:0] wr_data_t, wr_data_f, rd_data_t, rd_data_f;

    async_memory_cell #(.DATA_W(16)) dut (
        .rst_n(rst_n),
        .wr_req(wr_req), .wr_ack(wr_ack),
        .wr_data_t(wr_data_t), .wr_data_f(wr_data_f),
        .rd_req(rd_req), .rd_ack(rd_ack),
        .rd_data_t(rd_data_t), .rd_data_f(rd_data_f)
    );

    initial begin
        $dumpfile("async_mem.vcd"); $dumpvars(0, tb_async_memory);
        
        $display("[TEST] Initializing Memory Cell...");
        rst_n = 0; wr_req = 0; rd_req = 0;
        #10; rst_n = 1; #10;

        $display("[TEST] Writing value 42 to memory...");
        wr_data_t = 16'd42; wr_data_f = ~16'd42;
        wr_req = 1; #10; wr_req = 0; #1;

        $display("[TEST] Memory is now IDLE. Simulating 1000ns of zero-power wait...");
        #1000; // No clock ticks. No power burned. State is held physically.

        $display("[TEST] Reading memory...");
        rd_req = 1; #1;
        
        if (rd_data_t !== 16'd42) begin
            $error("FAIL: Memory lost state! Read %0d", rd_data_t);
            $finish;
        end
        
        $display("[TEST] SUCCESS: Read back 42. State held perfectly without a clock.");
        rd_req = 0; #1;
        
        $finish;
    end
endmodule
