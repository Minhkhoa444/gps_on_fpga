`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/16/2025 08:36:18 PM
// Design Name: 
// Module Name: ifft_bitreverse
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

import fft_pkg::*;

module fft_bitreverse
#(
    parameter SIZE = FFT_SIZE,
    localparam WIDTH = $clog2(SIZE)
)
(
    input   logic       clk,
    input   logic       rst_n,
    // input   logic       i_sync,
    input   logic       i_vld,
    input   data_t      i_data,
    `ifdef ADDITION
    input   logic       i_sync_rst,
    `endif

    output  logic       o_vld,
    output  data_t      o_data,
    output  logic       o_sync
);

    data_t  pingpong_mem    [0:SIZE*2-1];

    logic   [WIDTH:0]   wraddr;
    logic   [WIDTH:0]   wraddr_nxt;
    logic   [WIDTH:0]   rdaddr;

    logic   start;
    logic   start_tmp;
    logic   start_en;
    assign  start_en = &(wraddr[WIDTH-1:0]);
    // logic   vld;
    assign  start_tmp = (start_en) ? i_vld : start;
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            start <= 1'b0;
        end
        else begin
            if(i_sync_rst) begin
                start <= 'b0;
            end
            else begin
                start <= start_tmp;
            end

            // if(start_en) begin
            //     // The input must be stable and continuous, the start signal is only used for the case the pingpong memory does not
            //     // receive any more data but still store some left data in 1 of 2 buffers and must be continued sending out data
            //     start <= i_vld;
            // end
        end
    end

    logic en;
    assign en = (i_vld | start);
    logic   [WIDTH:0]   wraddr_tmp;
    assign  wraddr_tmp = (en) ? wraddr + 1'b1 : wraddr;
    // logic   [WIDTH:0]   wraddr_nxt_tmp;
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            wraddr <= 'b0;
            wraddr_nxt <= 'b0;
        end
        else begin
            if(i_sync_rst) begin
                wraddr <= 'b0;
                wraddr_nxt <= 'b0;
            end
            else begin
                wraddr <= wraddr_tmp;
                wraddr_nxt[0] <= wraddr[0];
                wraddr_nxt[WIDTH:1] <= wraddr[WIDTH:1] + 1'b1;
            end
        end
    end

	genvar	i;
	generate 
        for(i=0; i<WIDTH; i=i+1)
        begin
            assign rdaddr[i] = wraddr_nxt[WIDTH-1-i];
        end 
    endgenerate
    assign  rdaddr[WIDTH] = ~wraddr_nxt[WIDTH];

    always_ff @(posedge clk) begin
        if(en) begin
            pingpong_mem[wraddr] <= i_data;
        end
        o_data <= pingpong_mem[rdaddr];
    end

    logic o_sync_tmp;
    assign o_sync_tmp = (start_en & i_vld);
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            o_sync <= 'b0;
        end
        else begin
            if(i_sync_rst) begin
                o_sync <= 'b0;
            end
            else begin
                o_sync <= o_sync_tmp;
            end
        end
    end

    assign o_vld = start;


    // data_t  mem [0:SIZE-1];
    // logic   [WIDTH-1:0] addr;

    // always_ff @(posedge clk, negedge rst_n) begin
    //     if(~rst_n) begin
    //         addr <= 'b0;
    //     end
    //     else begin
    //         if(i_vld) begin
    //             addr <= addr + 1;
    //         end
    //     end
    // end

    // logic   [WIDTH-1:0] addr_tmp;
    // genvar i;
    // generate
    //     for(i=0; i<WIDTH; i++) begin
    //         assign  addr_tmp[i] = addr[WIDTH-i-1];
    //     end
    // endgenerate
    // always_ff @(posedge clk) begin
    //     if(i_vld) begin
    //         mem[addr_tmp] <= i_data;
    //     end
    // end

endmodule