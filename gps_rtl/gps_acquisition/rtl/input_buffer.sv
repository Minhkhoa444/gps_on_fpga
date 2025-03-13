`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/11/2025 08:49:57 AM
// Design Name: 
// Module Name: input_buffer
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

import acquisition_pkg::*;

module input_buffer
(
    input   logic       clk,
    input   logic       rst_n,

    input   logic       i_vld,
    input   dat_gps_t   i_data,
    input   [11:0]      i_rd_addr,

    output  dat_gps_t   o_data,
    output  logic       o_full
);

    localparam MAX_CNT = 4096;      // maximum value of counter
    localparam DEPTH = 4096;        // store 2ms input to bram for further processing

    dat_gps_t   mem     [0:DEPTH-1];
    logic   [11:0]  wr_cnt;

    // Process write counter
    logic   [11:0]  wr_cnt_nxt;
    assign  wr_cnt_nxt = wr_cnt + 1'b1;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            wr_cnt <= 'b0;
        end
        else begin
            if(i_vld) begin
                wr_cnt <= wr_cnt_nxt;
            end
        end
    end

    always_ff @(posedge clk) begin
        if(i_vld) begin
            mem[wr_cnt] <= i_data;
        end
        o_data <= mem[i_rd_addr];
    end
    
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            o_full <= 'b0;
        end
        else begin
            if(&wr_cnt[11:0]) begin
                o_full <= 'b1;
            end
        end
    end

endmodule