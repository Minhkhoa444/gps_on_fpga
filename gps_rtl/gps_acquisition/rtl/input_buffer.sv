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
    input   [12:0]      i_rd_addr,
    input               i_rd_en,

    output  logic       o_vld,
    output  logic       o_start,
    output  dat_gps_t   o_data,
    output  logic       o_full
);

    localparam MAX_CNT = 3999;      // maximum value of counter
    localparam DEPTH = 8000;        // store 2ms input to bram for further processing

    dat_gps_t   mem     [0:DEPTH-1];
    logic   [12:0]  wr_cnt;
    // logic   [1:0]   ready;          // "ready" indicates the corresponding memory part is ready to receive new data or not

    // Process write counter
    logic   [12:0]  wr_cnt_nxt;
    logic   [12:0]  wr_cnt_nxt_tmp;
    assign  wr_cnt_nxt_tmp = wr_cnt + 1'b1;
    always_comb begin
        if(wr_cnt_nxt_tmp[12]) begin
            if(wr_cnt_nxt_tmp > 7999) begin
                wr_cnt_nxt = 13'b0000000000000;
            end
            else begin
                wr_cnt_nxt = wr_cnt_nxt_tmp;
            end
        end
        else begin
            if(wr_cnt_nxt_tmp > 3999) begin
                wr_cnt_nxt = 13'b1000000000000;
            end
            else begin
                wr_cnt_nxt = wr_cnt_nxt_tmp;
            end
        end
    end
    // always_comb begin
    //     if(wr_cnt_nxt_tmp > 7999) begin
    //         wr_cnt_nxt = 13'b0000000000000;
    //     end
    //     else if (wr_cnt_nxt_tmp > 3999 && wr_cnt_nxt_tmp < 4096) begin
    //         wr_cnt_nxt = 13'b1000000000000;
    //     end
    //     else begin
    //         wr_cnt_nxt = wr_cnt_nxt_tmp;
    //     end
    // end

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
            o_vld <= 'b0;
        end
        else begin
            o_vld <= i_rd_en;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            o_start <= 'b0;
        end
        else begin
            if(wr_cnt == MAX_CNT && i_vld) begin
                o_start <= 1'b1;
            end
            else begin
                o_start <= 'b0;
            end
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            o_full <= 'b0;
        end
        else begin
            if(wr_cnt == 3999) begin
                o_full <= 'b1;
            end
        end
    end

endmodule