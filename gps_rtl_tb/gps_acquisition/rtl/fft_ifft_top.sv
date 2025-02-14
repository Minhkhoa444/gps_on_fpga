`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/07/2025 09:24:21 PM
// Design Name: 
// Module Name: fft_ifft_top
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

module fft_ifft_top #(
    localparam  NUM_STG = $clog2(FFT_SIZE)
)(
    input   logic   clk,
    input   logic   rst_n,

    input   logic   i_vld,
    input   data_t  i_data,
    input   logic   i_sync,

    output  logic   o_vld,
    output  data_t  o_data,
    output  logic   o_sync
);

    fft_ifft_in     fft_i;
    fft_ifft_in     ifft_i;
    fft_ifft_out    fft_o;
    fft_ifft_out    ifft_o;

    // #################### FFT CORE ####################
        fft_top fft(
            .clk    (clk),
            .rst_n  (rst_n),
            .i_vld  (fft_i.i_vld),
            .i_data (fft_i.i_data),
            .i_sync (fft_i.i_sync),
            .o_vld  (fft_o.o_vld),
            .o_data (fft_o.o_data),
            .o_sync (fft_o.o_sync)
        );
        
        assign fft_i = '{i_vld, i_data, i_sync};
    // ##################################################

    // #################### IFFT CORE ####################
        ifft_top ifft(
            .clk    (clk),
            .rst_n  (rst_n),
            .i_vld  (ifft_i.i_vld),
            .i_data (ifft_i.i_data),
            .i_sync (ifft_i.i_sync),
            .o_vld  (ifft_o.o_vld),
            .o_data (ifft_o.o_data),
            .o_sync (ifft_o.o_sync)
        );

        assign ifft_i = '{fft_o.o_vld, fft_o.o_data, fft_o.o_sync};
    // ###################################################

    assign o_vld = ifft_o.o_vld;
    assign o_data = ifft_o.o_data;
    assign o_sync = ifft_o.o_sync;

endmodule
