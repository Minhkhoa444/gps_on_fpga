`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// University: Ho Chi Minh City University of Technology
// Engineer: Vu Nam Binh
// 
// Create Date: 7th January 2025 06:55:17 PM
// Design Name: Fast Fourier Transform
// Module Name: fft_top
// Project Name: Software-defined Radio Global Positioning System FPGA-based Design
// Target Devices: UltraScale 96 v2.0
// Tool Versions: 
// Description: FFT is the heart of GPS Acquisition stage and this module is designed to be responsible for FFT implementation
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: This design is based on the design of pipelined FFT from ZipCPU. I get the idea from this source and try
//                      to reimplement it for easier use later on.
// 
//////////////////////////////////////////////////////////////////////////////////

import fft_pkg::*;

module fft_top #(
    localparam  NUM_STG = $clog2(FFT_SIZE)
)(
    input   logic   clk,
    input   logic   rst_n,

    input   logic   i_vld,
    input   data_t  i_data,

    `ifdef ADDITION
    input   logic   i_sync_rst,
    `endif

    output  logic   o_vld,
    output  data_t  o_data
);

    logic   signed  [(TW_D_WIDTH)*2-1:0] twiddle_factor  [0:FFT_SIZE/2-1];    // only need the number of twiddle factors equal to 1/2 of N-point FFT 
    
    fft_twiddle_q215 twiddle_q215 (
        .twiddle_factor(twiddle_factor)
    );

// ######################### twiddle factor #########################
    // twiddle factor declaration (for each stage)
    logic   [TW_D_WIDTH*2-1:0]     tf_stg_1    [0:FFT_SIZE/2-1];
    logic   [TW_D_WIDTH*2-1:0]     tf_stg_2    [0:FFT_SIZE/4-1];
    logic   [TW_D_WIDTH*2-1:0]     tf_stg_3    [0:FFT_SIZE/8-1];
    logic   [TW_D_WIDTH*2-1:0]     tf_stg_4    [0:FFT_SIZE/16-1];
    logic   [TW_D_WIDTH*2-1:0]     tf_stg_5    [0:FFT_SIZE/32-1];
    logic   [TW_D_WIDTH*2-1:0]     tf_stg_6    [0:FFT_SIZE/64-1];
    logic   [TW_D_WIDTH*2-1:0]     tf_stg_7    [0:FFT_SIZE/128-1];
    logic   [TW_D_WIDTH*2-1:0]     tf_stg_8    [0:FFT_SIZE/256-1];
    logic   [TW_D_WIDTH*2-1:0]     tf_stg_9    [0:FFT_SIZE/512-1];
    logic   [TW_D_WIDTH*2-1:0]     tf_stg_10   [0:FFT_SIZE/1024-1];

    genvar  i;

    // ----- stage 1: 2048 twiddle factors -----
    generate
        for(i=0; i<2048; i++) begin
            assign tf_stg_1[i] = twiddle_factor[i];
        end
    endgenerate

    // ----- stage 2: 1024 twiddle factors -----
    generate
        for(i=0; i<1024; i++) begin
            assign tf_stg_2[i] = twiddle_factor[i*2];
        end
    endgenerate

    // ----- stage 3: 512 twiddle factors -----
    generate
        for(i=0; i<512; i++) begin
            assign tf_stg_3[i] = twiddle_factor[i*4];
        end
    endgenerate

    // ----- stage 4: 256 twiddle factors -----
    generate
        for(i=0; i<256; i++) begin
            assign tf_stg_4[i] = twiddle_factor[i*8];
        end
    endgenerate

    // ----- stage 5: 128 twiddle factors -----
    generate
        for(i=0; i<128; i++) begin
            assign tf_stg_5[i] = twiddle_factor[i*16];
        end
    endgenerate

    // ----- stage 6: 64 twiddle factors -----
    generate
        for(i=0; i<64; i++) begin
            assign tf_stg_6[i] = twiddle_factor[i*32];
        end
    endgenerate

    // ----- stage 7: 32 twiddle factors -----
    generate
        for(i=0; i<32; i++) begin
            assign tf_stg_7[i] = twiddle_factor[i*64];
        end
    endgenerate

    // ----- stage 8: 16 twiddle factors -----
    generate
        for(i=0; i<16; i++) begin
            assign tf_stg_8[i] = twiddle_factor[i*128];
        end
    endgenerate

    // ----- stage 9: 8 twiddle factors -----
    generate
        for(i=0; i<8; i++) begin
            assign tf_stg_9[i] = twiddle_factor[i*256];
        end
    endgenerate

    // ----- stage 10: 4 twiddle factors -----
    generate
        for(i=0; i<4; i++) begin
            assign tf_stg_10[i] = twiddle_factor[i*512];
        end
    endgenerate
// ##################################################################



// ##################### fft_stage instantiation ####################
    // ----- fft stage 1 2048 points -----
    logic   o_vld_stg_1;
    data_t  o_data_stg_1;
    fft_stage #(.SIZE(4096)) fft_stg_1 (
        .clk(clk),
        .rst_n(rst_n),
        .twiddle_factor(tf_stg_1),
        .i_vld(i_vld),
        .i_data(i_data),
        `ifdef ADDITION
        .i_sync_rst(i_sync_rst),        
        `endif
        .o_vld(o_vld_stg_1),
        .o_data(o_data_stg_1)
    );

    // ----- fft stage 2 1024 points -----
    logic   o_vld_stg_2;
    data_t  o_data_stg_2;
    fft_stage #(.SIZE(2048)) fft_stg_2 (
        .clk(clk),
        .rst_n(rst_n),
        .twiddle_factor(tf_stg_2),
        .i_vld(o_vld_stg_1),
        .i_data(o_data_stg_1),
        `ifdef ADDITION
        .i_sync_rst(i_sync_rst),        
        `endif
        .o_vld(o_vld_stg_2),
        .o_data(o_data_stg_2)
    );

    // ----- fft stage 3 512 points -----
    logic   o_vld_stg_3;
    data_t  o_data_stg_3;
    fft_stage #(.SIZE(1024)) fft_stg_3 (
        .clk(clk),
        .rst_n(rst_n),
        .twiddle_factor(tf_stg_3),
        .i_vld(o_vld_stg_2),
        .i_data(o_data_stg_2),
        `ifdef ADDITION
        .i_sync_rst(i_sync_rst),        
        `endif
        .o_vld(o_vld_stg_3),
        .o_data(o_data_stg_3)
    );        

    // ----- fft stage 4 256 points -----
    logic   o_vld_stg_4;
    data_t  o_data_stg_4;
    fft_stage #(.SIZE(512)) fft_stg_4 (
        .clk(clk),
        .rst_n(rst_n),
        .twiddle_factor(tf_stg_4),
        .i_vld(o_vld_stg_3),
        .i_data(o_data_stg_3),
        `ifdef ADDITION
        .i_sync_rst(i_sync_rst),        
        `endif
        .o_vld(o_vld_stg_4),
        .o_data(o_data_stg_4)
    );

    // ----- fft stage 5 128 points -----
    logic   o_vld_stg_5;
    data_t  o_data_stg_5;
    fft_stage #(.SIZE(256)) fft_stg_5 (
        .clk(clk),
        .rst_n(rst_n),
        .twiddle_factor(tf_stg_5),
        .i_vld(o_vld_stg_4),
        .i_data(o_data_stg_4),
        `ifdef ADDITION
        .i_sync_rst(i_sync_rst),        
        `endif
        .o_vld(o_vld_stg_5),
        .o_data(o_data_stg_5)
    );

    // ----- fft stage 6 64 points -----
    logic   o_vld_stg_6;
    data_t  o_data_stg_6;
    fft_stage #(.SIZE(128)) fft_stg_6 (
        .clk(clk),
        .rst_n(rst_n),
        .twiddle_factor(tf_stg_6),
        .i_vld(o_vld_stg_5),
        .i_data(o_data_stg_5),
        `ifdef ADDITION
        .i_sync_rst(i_sync_rst),        
        `endif
        .o_vld(o_vld_stg_6),
        .o_data(o_data_stg_6)
    );     

    // ----- fft stage 7 32 points -----
    logic   o_vld_stg_7;
    data_t  o_data_stg_7;
    fft_stage #(.SIZE(64)) fft_stg_7 (
        .clk(clk),
        .rst_n(rst_n),
        .twiddle_factor(tf_stg_7),
        .i_vld(o_vld_stg_6),
        .i_data(o_data_stg_6),
        `ifdef ADDITION
        .i_sync_rst(i_sync_rst),        
        `endif
        .o_vld(o_vld_stg_7),
        .o_data(o_data_stg_7)
    );       

    // ----- fft stage 8 16 points -----
    logic   o_vld_stg_8;
    data_t  o_data_stg_8;
    fft_stage #(.SIZE(32)) fft_stg_8 (
        .clk(clk),
        .rst_n(rst_n),
        .twiddle_factor(tf_stg_8),
        .i_vld(o_vld_stg_7),
        .i_data(o_data_stg_7),
        `ifdef ADDITION
        .i_sync_rst(i_sync_rst),        
        `endif
        .o_vld(o_vld_stg_8),
        .o_data(o_data_stg_8)
    );        

    // ----- fft stage 9 8 points -----
    logic   o_vld_stg_9;
    data_t  o_data_stg_9;
    fft_stage #(.SIZE(16)) fft_stg_9 (
        .clk(clk),
        .rst_n(rst_n),
        .twiddle_factor(tf_stg_9),
        .i_vld(o_vld_stg_8),
        .i_data(o_data_stg_8),
        `ifdef ADDITION
        .i_sync_rst(i_sync_rst),        
        `endif
        .o_vld(o_vld_stg_9),
        .o_data(o_data_stg_9)
    );        

    // ----- fft stage 10 4 points -----
    logic   o_vld_stg_10;
    data_t  o_data_stg_10;
    fft_stage #(.SIZE(8)) fft_stg_10 (
        .clk(clk),
        .rst_n(rst_n),
        .twiddle_factor(tf_stg_10),
        .i_vld(o_vld_stg_9),
        .i_data(o_data_stg_9),
        `ifdef ADDITION
        .i_sync_rst(i_sync_rst),        
        `endif
        .o_vld(o_vld_stg_10),
        .o_data(o_data_stg_10)
    );    

    // ----- fft stage 11 2 points -----
    logic   o_vld_stg_11;
    data_t  o_data_stg_11;
    fft_prelaststage fft_stg_11 (
        .clk(clk),
        .rst_n(rst_n),
        .i_vld(o_vld_stg_10),
        .i_data(o_data_stg_10),
        `ifdef ADDITION
        .i_sync_rst(i_sync_rst),        
        `endif
        .o_vld(o_vld_stg_11),
        .o_data(o_data_stg_11)
    );

    // ----- fft last stage -----
    logic   o_vld_stg_12;
    data_t  o_data_stg_12;
    fft_laststage fft_stg_12 (
        .clk(clk),
        .rst_n(rst_n),
        .i_vld(o_vld_stg_11),
        .i_data(o_data_stg_11),
        `ifdef ADDITION
        .i_sync_rst(i_sync_rst),        
        `endif
        .o_vld(o_vld_stg_12),
        .o_data(o_data_stg_12)
    );
// ##################################################################

    fft_bitreverse bitreverse (
        .clk(clk),
        .rst_n(rst_n),
        `ifdef ADDITION
        .i_sync_rst(i_sync_rst),        
        `endif
        .i_vld(o_vld_stg_12),
        .i_data(o_data_stg_12),
        .o_vld(o_vld),
        .o_data(o_data)
    );

endmodule