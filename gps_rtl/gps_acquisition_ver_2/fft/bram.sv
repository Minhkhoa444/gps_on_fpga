`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 8th January 2025 08:17:45 AM
// Design Name: Fast Fourier Transform
// Module Name: fft_bram
// Project Name: Software-defined Radio Global Positioning System FPGA-based Design
// Target Devices: UltraScale 96 v2.0
// Tool Versions: 
// Description: This design is used to instantiate a bram
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//`include "fft_pkg.sv"

import fft_pkg::*;

module bram #(
    parameter   SIZE = FFT_SIZE,                // parameter in pkg can not be redefined --> use a different name "SIZE"
    localparam  FFT_WIDTH = $clog2(SIZE),
    parameter   ADDR_WIDTH = FFT_WIDTH
)
(
    input   logic   clk,
    input   logic   rst_n,
    
    input   logic   [ADDR_WIDTH:0]       i_wraddr,
    input   logic   [ADDR_WIDTH:0]       i_rdaddr,

    input   logic                       i_wr_vld,
    input   logic                       i_rd_vld,
    `ifndef IFFT_BITREVERSE
        input   data_t                      i_data,
        output  data_t                      o_data,
    `else
        input   logic   signed  [15:0]      i_data,
        output  logic   signed  [15:0]      o_data,
    `endif
    output  logic                       o_vld
);

    `ifndef IFFT_BITREVERSE
        data_t  pingpong_mem    [0:SIZE*2-1];
    `else
        logic   signed  [15:0]  pingpong_mem    [0:SIZE*2-1];
    `endif

    always_ff @(posedge clk) begin
        if(i_wr_vld) begin
            pingpong_mem[i_wraddr] <= i_data;
        end
        o_data <= pingpong_mem[i_rdaddr];
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            o_vld <= 'b0;
        end
        else begin
            o_vld <= i_rd_vld;
        end
    end

endmodule