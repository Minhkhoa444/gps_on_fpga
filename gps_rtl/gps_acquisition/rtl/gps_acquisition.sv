`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/10/2025 07:07:41 PM
// Design Name: 
// Module Name: gps_acquisition
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
import fft_pkg::*;
//import ifft_pkg::*;

module gps_acquisition(
    input   logic                           clk,
    input   logic                           rst_n,

    // input data from sdr and output tready to sdr
    input   logic                           s_axis_tvalid,      // tvalid
    input   logic   signed  [15:0]          s_axis_tdata_i,     // gps_i
    input   logic   signed  [15:0]          s_axis_tdata_q,     // gps_q
    output  logic                           s_axis_tready,      // tready

    // input tready, output data from/to gps_dispatcher
    input   logic                           m_axis_tready,      // tready from dispatcher
    output  logic                           m_axis_tvalid,      // tvalid to dispatcher
    output  logic   signed  [16:0]          m_axis_tdata_im,    // imaginary part of ifft output    (corr result - imaginary)
    output  logic   signed  [16:0]          m_axis_tdata_re,    // real part of ifft output         (corr result - real)
    output  logic           [4:0]           m_axis_tprn_id,     // prn id
    output  logic   signed  [14:0]          m_axis_td_shift,    // doppler shift
    output  logic           [11:0]          m_axis_tposition    // code phase delay (just simply the position of the current ifft output
                                                                // from this position, we can compute the code phase delay)
                                                                // formula: (position/4096) * 1023
);

    // ############### Signal Declaration ###############
    // ---------- input buffer ----------
    dat_gps_t       ibuf_i_data;
    logic   [12:0]  ibuf_i_rd_addr;             // ff
    logic   [12:0]  ibuf_i_rd_addr_tmp;
    logic   [12:0]  ibuf_i_rd_addr_nxt;
    logic           ibuf_i_rd_en;
    
    logic           ibuf_o_vld;
    logic           ibuf_o_start;
    dat_gps_t       ibuf_o_data;
    logic           ibuf_o_full;

    // ---------- accumulator ----------
    logic   [5:0]   acc_i_doppler_id;           // ff
    logic   [5:0]   acc_i_doppler_id_nxt;
    logic   [5:0]   acc_i_doppler_id_tmp;
    logic   [5:0]   acc_i_doppler_id_add;
    logic   [5:0]   acc_i_doppler_id_sub;
    logic           toggle;                     // to choose between positive/negative values of sine output from cordic, 0 for posi and 1 for nega
    logic           toggle_tmp;
    logic           acc_start;
    logic           acc_start_tmp;
    logic           acc_o_vld;
    logic   [34:0]  acc_o_angle;

    // ---------- cordic ----------
    logic   signed  [15:0]  cord_o_cos;
    logic   signed  [15:0]  cord_o_sin;
    logic                   cord_o_vld;
    logic   [11:0]          cord_br_wraddr;
    logic   [11:0]          cord_br_rdaddr;
    dat_gps_t               cord_br [0:3999];       // bram stores cordic output
    dat_gps_t               cord_br_o;

    // ---------- pre mult 1 ----------
    logic           fft_rcv_start;          // flag to start computing input for the fft of the received signal
    logic   [11:0]  pre_mult_1_cnt;
    logic   [11:0]  pre_mult_1_cnt_nxt;
    logic   [11:0]  pre_mult_1_cnt_tmp;
    // logic           pre_mult_1_vld;

    // ---------- mult 1 ----------
    logic                       mult_1_vld_pipe_1;      // pipeline vld 1 stage to synchronize with data out from bram ibuf
    logic                       mult_1_vld_pipe_2;
    logic   signed   [15:0]     mult_1_re_1_pipe_2;     // (ibuf_re) x (cord_o_cos) 
    logic   signed   [15:0]     mult_1_re_2_pipe_2;     // (ibuf_im) x (cord_o_sin)
    logic   signed   [15:0]     mult_1_im_1_pipe_2;     // (ibuf_re) x (cord_o_sin)
    logic   signed   [15:0]     mult_1_im_2_pipe_2;     // (ibuf_im) x (cord_o_cos)
    logic                       mult_1_vld_pipe_3;
    logic   signed  [15:0]      mult_1_re_pipe_3;       // (ibuf_re) x (cord_o_cos) - (ibuf_im) x (cord_o_sin)
    logic   signed  [15:0]      mult_1_im_pipe_3;       // (ibuf_re) x (cord_o_sin) + (ibuf_im) x (cord_o_cos)

    // ---------- post mult 1 ----------
    logic           post_mult_1_vld;        // input valid of fft
    // logic   [16:0]  post_mult_1_re;         // input real of fft
    // logic   [16:0]  post_mult_1_im;         // input imaginary of fft
    data_t          post_mult_1_data;
    logic   [11:0]  post_mult_1_cnt;
    logic   [11:0]  post_mult_1_cnt_nxt;
    logic   [11:0]  post_mult_1_cnt_tmp;

    // ---------- fft (received signal) ----------
    logic           fft_rcv_i_vld;
    data_t          fft_rcv_i_data;
    logic           fft_rcv_i_sync;
    logic           fft_rcv_i_sync_rst;
    logic           fft_rcv_o_vld;
    data_t          fft_rcv_o_data;
    logic           fft_rcv_o_sync;
    logic   [11:0]  fft_rcv_br_wraddr;
    logic   [11:0]  fft_rcv_br_rdaddr;
    data_t          fft_rcv_br [0:4095];       // bram stores fft output
    data_t          fft_rcv_br_o;

    // ---------- precomputed_ca ----------
    logic   signed  [D_WIDTH-1:0]   ca_o_data   [0:31];
    // logic           [11:0]          ca_i_rdaddr;
    // ------------------------------------

    // ---------- fft (local ca code) ----------
    logic           fft_local_i_vld;
    logic           fft_local_i_vld_pipe_1;
    logic           fft_local_i_vld_pipe_1_tmp;
    logic           fft_local_i_vld_pipe_2;
    data_t          fft_local_i_data;
    logic           fft_local_i_sync;
    logic           fft_local_i_sync_rst;
    logic           fft_local_o_vld;
    data_t          fft_local_o_data;
    logic           fft_local_o_sync;
    logic   [4:0]   fft_local_ca_id_pipe_1;
    logic   [4:0]   fft_local_ca_id_pipe_1_tmp;
    logic   [4:0]   fft_local_ca_id_pipe_1_nxt;
    logic   [4:0]   fft_local_ca_id_pipe_2;
    logic   [11:0]  fft_local_cnt_pipe_1;
    logic   [11:0]  fft_local_cnt_pipe_1_tmp;
    logic   [11:0]  fft_local_cnt_pipe_1_nxt;
    logic   [11:0]  fft_local_cnt_pipe_2;

    // ---------- pre mult 2 ----------
    logic   [11:0]  pre_mult_2_cnt;
    logic   [11:0]  pre_mult_2_cnt_tmp;
    logic   [11:0]  pre_mult_2_cnt_nxt;

    // ---------- mult 2 ----------
    logic                   mult_2_vld_pipe_1;
    logic   signed  [16:0]  mult_2_re_1_pipe_1;     // (fft_rcv_re) x (fft_local_re) 
    logic   signed  [16:0]  mult_2_re_2_pipe_1;     // (fft_rcv_im) x (-fft_local_im) -> minus for complex conjugate
    logic   signed  [16:0]  mult_2_im_1_pipe_1;     // (fft_rcv_re) x (-fft_local_im) - > minus for complex conjugate
    logic   signed  [16:0]  mult_2_im_2_pipe_1;     // (fft_rcv_im) x (fft_local_re)
    logic                   mult_2_vld_pipe_2;
    logic   signed  [16:0]  mult_2_re_pipe_2;       // (fft_rcv_re) x (fft_local_re)  - (fft_rcv_im) x (-fft_local_im)
    logic   signed  [16:0]  mult_2_im_pipe_2;       // (fft_rcv_re) x (-fft_local_im) + (fft_rcv_im) x (fft_local_re)

    // ---------- post mult 2 ----------
    logic           post_mult_2_done;
    logic           post_mult_2_done_tmp;
    logic   [11:0]  post_mult_2_cnt;
    logic   [11:0]  post_mult_2_cnt_tmp;
    logic   [11:0]  post_mult_2_cnt_nxt;
    logic   [4:0]   post_mult_2_ca_id;
    logic   [4:0]   post_mult_2_ca_id_tmp;
    logic   [4:0]   post_mult_2_ca_id_nxt;

    // ---------- ifft ----------
    logic           ifft_i_vld;
    data_t          ifft_i_data;
    logic           ifft_i_sync;
    logic           ifft_i_sync_rst;
    logic           ifft_i_sync_rst_tmp;
    // logic           ifft_i_sync_rst_nxt;
    logic           ifft_o_vld;
    data_t          ifft_o_data;
    logic           ifft_o_sync;
    logic   [4:0]   post_ifft_ca_id;
    logic   [4:0]   post_ifft_ca_id_tmp;
    logic   [4:0]   post_ifft_ca_id_nxt;
    logic   [11:0]  post_ifft_cnt;
    logic   [11:0]  post_ifft_cnt_tmp;
    logic   [11:0]  post_ifft_cnt_nxt;
    // ##################################################



    // ---------- input buffer instantiation ----------
    input_buffer    ibuf (
        .clk(clk),
        .rst_n(rst_n),
        
        .i_vld(s_axis_tvalid & s_axis_tready),
        .i_data(ibuf_i_data),
        .i_rd_addr(ibuf_i_rd_addr),         // read address (pre_mult_1_cnt)
        .i_rd_en(ibuf_i_rd_en),             // 
    
        .o_vld(ibuf_o_vld),                 // HIEN TAI CHUA CAN DEN
        .o_start(ibuf_o_start),             // enough_data
        .o_data(ibuf_o_data),
        .o_full(ibuf_o_full)
    );
    assign  ibuf_i_data = '{s_axis_tdata_i, s_axis_tdata_q};
    always_comb begin
        if(~(|pre_mult_1_cnt[11:0])) begin
            ibuf_i_rd_en = fft_rcv_start;
        end
        else begin
            ibuf_i_rd_en = 1'b1;
        end
    end

    assign ibuf_i_rd_addr_tmp = ibuf_i_rd_addr + 1'b1;
    always_comb begin
        if(~(|pre_mult_1_cnt[11:0])) begin
            ibuf_i_rd_addr_nxt = 'b0;
        end
        else begin
            if(ibuf_i_rd_addr_tmp > 3999) begin
                ibuf_i_rd_addr_nxt = 'b0;
            end
            else begin
                ibuf_i_rd_addr_nxt = ibuf_i_rd_addr_tmp;
            end
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            ibuf_i_rd_addr <= 'b0;
        end
        else begin
            ibuf_i_rd_addr <= ibuf_i_rd_addr_nxt;
        end
    end
    // ------------------------------------------------



    // ---------- accumulator instantiation ----------
    accumulator acc (
        .clk(clk),
        .rst_n(rst_n),
        .i_start(acc_start),
        // .i_flag,
        // .i_new(),                       // i_new = ~(&ibuf_i_rd_addr[11:0])
        .i_doppler_id(acc_i_doppler_id),                  // doppler id: 0 ---> 40 corresponding to f = +10kHz ---> 0Hz
    
        .o_vld(acc_o_vld),
        .o_angle(acc_o_angle)
    );

    // compute i_doppler_id
    assign acc_i_doppler_id_add = acc_i_doppler_id + 1'b1;
    assign acc_i_doppler_id_sub = acc_i_doppler_id - 1'b1;
    always_comb begin
        if(toggle) begin    // from -250Hz -> -10kHz
            if(&acc_i_doppler_id_sub[5:0]) begin    // after acc_i_doppler_id reaches 0, it minus 1 will create -1 (all bits 1) -> AND to detect this
                toggle_tmp = ~toggle;
                acc_i_doppler_id_tmp = 6'b000000;
            end
            else begin
                toggle_tmp = toggle;
                acc_i_doppler_id_tmp = acc_i_doppler_id_sub;
            end
        end
        else begin  // from 10kHz -> 0Hz
            if(acc_i_doppler_id_add > 40) begin
                acc_i_doppler_id_tmp = 6'b100111;   // 39 -> id of 250Hz
                toggle_tmp = ~toggle;
            end
            else begin
                toggle_tmp = toggle;
                acc_i_doppler_id_tmp = acc_i_doppler_id_add;
            end
        end
    end

    always_comb begin
        if(acc_start_tmp) begin
            acc_i_doppler_id_nxt = acc_i_doppler_id_tmp;
        end
        else begin
            acc_i_doppler_id_nxt = acc_i_doppler_id;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            acc_i_doppler_id <= 'b0;
            toggle <= 'b0;
        end
        else begin
            toggle <= toggle_tmp;
            acc_i_doppler_id <= acc_i_doppler_id_nxt;
        end
    end

    // acc_start assignment
    always_comb begin
        if(acc_start) begin
            acc_start_tmp = 'b0;
        end
        else begin
            if(post_mult_1_cnt==3999) begin
                acc_start_tmp = 'b1;
            end
            else begin
                acc_start_tmp = 'b0;
            end
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin        // when reset, it means the system started running again --> start computing the doppler shift from early
            acc_start <= 'b1;
        end
        else begin
            acc_start <= acc_start_tmp;
        end
    end
    // --------------------------------------------------------


    // ---------- cordic instantiation ----------
    cordic  cord(
        .clk(clk),
        .rst_n(rst_n),
        .i_vld(acc_o_vld),
        .i_angle(acc_o_angle),
        .o_cosine(cord_o_cos),
        .o_sine(cord_o_sin),
        .o_vld(cord_o_vld)
    );
    assign cord_br_rdaddr = ibuf_i_rd_addr;
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            cord_br_wraddr <= 'b0;
        end
        else begin
            if(cord_o_vld) begin
                cord_br_wraddr <= cord_br_wraddr + 1'b1;
            end
        end
    end
    always_ff @(posedge clk) begin
        if(cord_o_vld) begin
            cord_br[cord_br_wraddr] <= '{cord_o_cos, cord_o_sin};
        end
        cord_br_o <= cord_br[cord_br_rdaddr];
    end
    // ------------------------------------------



    // ---------- pre mult 1 ----------
    always_comb begin
        if(~ibuf_o_start) begin
            fft_rcv_start = ibuf_o_start;
        end
        else begin
            fft_rcv_start = post_mult_2_done;
        end
    end
    assign  pre_mult_1_cnt_tmp = pre_mult_1_cnt + 1'b1;
    always_comb begin
        if(~(|pre_mult_1_cnt[11:0])) begin      // if cnt_pre_mult == 0, wait for flag fft_rcv_start
            if(fft_rcv_start) begin             // if the flag is set, then start increasing the value
                pre_mult_1_cnt_nxt = pre_mult_1_cnt_tmp;
                // pre_mult_1_vld = 'b1;
            end
            else begin                          // else stay at 0
                pre_mult_1_cnt_nxt = 'b0;
                // pre_mult_1_vld = 'b0;
            end
        end
        else begin                              // if the value of pre_mult_1_cnt is not 0 -> keep increasing the value until it reaches 3999
            if(pre_mult_1_cnt_tmp > 3999) begin
                pre_mult_1_cnt_nxt = 'b0;
                // pre_mult_1_vld = 'b0;
            end
            else begin
                // pre_mult_1_vld = 'b1;
                pre_mult_1_cnt_nxt = pre_mult_1_cnt;
            end
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            pre_mult_1_cnt <= 'b0;
        end
        else begin
            pre_mult_1_cnt <= pre_mult_1_cnt_nxt;
        end
    end
    // --------------------------------


    // ---------- mult 1 ----------
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            mult_1_vld_pipe_1 <= 'b0;
            mult_1_vld_pipe_2 <= 'b0;
            mult_1_vld_pipe_3 <= 'b0;
        end
        else begin
            mult_1_vld_pipe_1 <= fft_rcv_start;
            mult_1_vld_pipe_2 <= mult_1_vld_pipe_1;
            mult_1_vld_pipe_3 <= mult_1_vld_pipe_2;
        end
    end

    // Pipeline stage 2: compute multiplications
    logic   signed  [31:0]  mult_1_re_1_pipe_2_tmp;
    logic   signed  [15:0]  mult_1_re_1_pipe_2_shift;
    logic   signed  [31:0]  mult_1_re_2_pipe_2_tmp;
    logic   signed  [15:0]  mult_1_re_2_pipe_2_shift;
    logic   signed  [31:0]  mult_1_im_1_pipe_2_tmp;
    logic   signed  [15:0]  mult_1_im_1_pipe_2_shift;
    logic   signed  [31:0]  mult_1_im_2_pipe_2_tmp;
    logic   signed  [15:0]  mult_1_im_2_pipe_2_shift;
    always_comb begin
        if(toggle) begin
            mult_1_re_1_pipe_2_tmp = ibuf_o_data.gps_i * cord_br_o.gps_i;
            mult_1_re_2_pipe_2_tmp = ibuf_o_data.gps_q * (-cord_br_o.gps_q);
            mult_1_im_1_pipe_2_tmp = ibuf_o_data.gps_i * (-cord_br_o.gps_q);
            mult_1_im_2_pipe_2_tmp = ibuf_o_data.gps_q * cord_br_o.gps_i;
        end
        else begin
            mult_1_re_1_pipe_2_tmp = ibuf_o_data.gps_i * cord_br_o.gps_i;
            mult_1_re_2_pipe_2_tmp = ibuf_o_data.gps_q * cord_br_o.gps_q;
            mult_1_im_1_pipe_2_tmp = ibuf_o_data.gps_i * cord_br_o.gps_q;
            mult_1_im_2_pipe_2_tmp = ibuf_o_data.gps_q * cord_br_o.gps_i;
        end
    end
    assign  mult_1_re_1_pipe_2_shift = mult_1_re_1_pipe_2_tmp >>> 15;
    assign  mult_1_re_2_pipe_2_shift = mult_1_re_2_pipe_2_tmp >>> 15;
    assign  mult_1_im_1_pipe_2_shift = mult_1_im_1_pipe_2_tmp >>> 15;
    assign  mult_1_im_2_pipe_2_shift = mult_1_im_2_pipe_2_tmp >>> 15;
    always_ff @(posedge clk) begin
        mult_1_re_1_pipe_2 <= mult_1_re_1_pipe_2_shift;
        mult_1_re_2_pipe_2 <= mult_1_re_2_pipe_2_shift;
        mult_1_im_1_pipe_2 <= mult_1_im_1_pipe_2_shift;
        mult_1_im_2_pipe_2 <= mult_1_im_2_pipe_2_shift;
    end

    // Pipeline stage 3: compute additions/subtractions
    logic   signed  [15:0]  mult_1_re_pipe_3_tmp;
    logic   signed  [15:0]  mult_1_im_pipe_3_tmp;
    assign  mult_1_re_pipe_3_tmp = mult_1_re_1_pipe_2 - mult_1_re_2_pipe_2;
    assign  mult_1_im_pipe_3_tmp = mult_1_im_1_pipe_2 + mult_1_im_2_pipe_2;
    always_ff @(posedge clk) begin
        mult_1_re_pipe_3 <= mult_1_re_pipe_3_tmp;
        mult_1_im_pipe_3 <= mult_1_im_pipe_3_tmp;
    end
    // ----------------------------


    // ---------- post mult 1 ----------
    assign  post_mult_1_vld = mult_1_vld_pipe_3;
    assign  post_mult_1_data.data_re = {mult_1_re_pipe_3[15], mult_1_re_pipe_3[15:0]};
    assign  post_mult_1_data.data_im = {mult_1_im_pipe_3[15], mult_1_im_pipe_3[15:0]};
    assign  post_mult_1_cnt_tmp = post_mult_1_cnt + 1'b1;
    always_comb begin
        if(post_mult_1_vld) begin
            if(post_mult_1_cnt_tmp > 3999) begin
                post_mult_1_cnt_nxt = 'b0;
            end
            else begin
                post_mult_1_cnt_nxt = post_mult_1_cnt_tmp;
            end
        end
        else begin
            post_mult_1_cnt_nxt = 'b0;
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            post_mult_1_cnt <= 'b0;
        end
        else begin
            post_mult_1_cnt <= post_mult_1_cnt_nxt;
        end
    end
    // ---------------------------------


    // ---------- fft (received signal) ----------
    fft_top fft_rcv (
        .clk        (clk),
        .rst_n      (rst_n),
        .i_vld      (fft_rcv_i_vld),
        .i_data     (fft_rcv_i_data),
        .i_sync     (fft_rcv_i_sync),
        .i_sync_rst (fft_rcv_i_sync_rst),
        .o_vld      (fft_rcv_o_vld),
        .o_data     (fft_rcv_o_data),
        .o_sync     (fft_rcv_o_sync)
    );
    assign  fft_rcv_i_vld = post_mult_1_vld;
    assign  fft_rcv_i_data = post_mult_1_data;
    assign  fft_rcv_i_sync = (fft_rcv_i_vld & ~post_mult_1_cnt[11]);
    assign  fft_rcv_i_sync_rst = post_mult_2_done;
    assign  fft_rcv_br_rdaddr = pre_mult_2_cnt;
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            fft_rcv_br_wraddr <= 'b0;
        end
        else begin
            if(fft_rcv_o_vld) begin
                fft_rcv_br_wraddr <= fft_rcv_br_wraddr + 1'b1;
            end
        end
    end
    always_ff @(posedge clk) begin
        if(fft_rcv_o_vld) begin
            fft_rcv_br[fft_rcv_br_wraddr] <= fft_rcv_o_data;
        end
        fft_rcv_br_o <= fft_rcv_br[fft_rcv_br_rdaddr];
    end
    // -------------------------------------------


    // ---------- precomputed_ca ----------
    precomputed_ca ca (
        .clk(clk),
        .rst_n(rst_n),
    
        .i_rdaddr(fft_local_cnt_pipe_1),
        .o_data(ca_o_data)
    );
    // ------------------------------------


    // ---------- fft (local ca code) ----------
    fft_top fft_local(
        .clk        (clk),
        .rst_n      (rst_n),
        .i_vld      (fft_local_i_vld),
        .i_data     (fft_local_i_data),
        .i_sync     (fft_local_i_sync),
        .i_sync_rst (fft_local_i_sync_rst),
        .o_vld      (fft_local_o_vld),
        .o_data     (fft_local_o_data),
        .o_sync     (fft_local_o_sync)
    );
    // counter
    assign  fft_local_cnt_pipe_1_tmp = fft_local_cnt_pipe_1 + 1'b1;
    always_comb begin
        if(mult_1_vld_pipe_2) begin
            fft_local_cnt_pipe_1_nxt = fft_local_cnt_pipe_1_tmp;
        end
        else begin
            fft_local_cnt_pipe_1_nxt = 'b0;
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            fft_local_cnt_pipe_1 <= 'b0;
        end
        else begin
            fft_local_cnt_pipe_1 <= fft_local_cnt_pipe_1_nxt;
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            fft_local_cnt_pipe_2 <= 'b0;
        end
        else begin
            fft_local_cnt_pipe_2 <= fft_local_cnt_pipe_1;
        end
    end
    // ca id
    assign fft_local_ca_id_pipe_1_tmp = fft_local_ca_id_pipe_1 + 1'b1;
    always_comb begin
        if(&(fft_local_cnt_pipe_2[11:0])) begin
            fft_local_ca_id_pipe_1_nxt = fft_local_ca_id_pipe_1_tmp;
        end
        else begin
            fft_local_ca_id_pipe_1_nxt = fft_local_ca_id_pipe_1;
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            fft_local_ca_id_pipe_1 <= 'b0;
            fft_local_ca_id_pipe_2 <= 'b0;
        end
        else begin
            fft_local_ca_id_pipe_1 <= fft_local_ca_id_pipe_1_nxt;
            fft_local_ca_id_pipe_2 <= fft_local_ca_id_pipe_1;
        end
    end

    // fft_local_i_vld
    always_comb begin
        if(fft_local_ca_id_pipe_1 == 0) begin
            if(fft_local_cnt_pipe_1 == 0) begin
                fft_local_i_vld_pipe_1_tmp = mult_1_vld_pipe_2;
            end
            else begin
                fft_local_i_vld_pipe_1_tmp = 1'b1;
            end
        end
        else begin
            fft_local_i_vld_pipe_1_tmp = 1'b1;
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            fft_local_i_vld_pipe_1 <= 'b0;
            fft_local_i_vld_pipe_2 <= 'b0;
        end
        else begin
            fft_local_i_vld_pipe_1 <= fft_local_i_vld_pipe_1_tmp;
            fft_local_i_vld_pipe_2 <= fft_local_i_vld_pipe_1;
        end
    end
    assign  fft_local_i_vld = fft_local_i_vld_pipe_2;
    assign  fft_local_i_data = ca_o_data[fft_local_ca_id_pipe_2];
    assign  fft_local_i_sync = ~(|fft_local_cnt_pipe_2[11:0]);
    assign  fft_local_i_sync_rst = post_mult_2_done;
    // -----------------------------------------

    // ---------- pre mult 2 ----------
    assign  pre_mult_2_cnt_tmp = pre_mult_2_cnt + 1'b1;
    always_comb begin
        if(fft_local_ca_id_pipe_1 != 0) begin
            pre_mult_2_cnt_nxt = pre_mult_2_cnt_tmp;
        end
        else begin
            pre_mult_2_cnt_nxt = 'b0;
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            pre_mult_2_cnt <= 'b0;
        end
        else begin
            pre_mult_2_cnt <= pre_mult_2_cnt_nxt;
        end
    end
    // --------------------------------

    // ---------- mult 2 ----------
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            mult_2_vld_pipe_1 <= 'b0;
            mult_2_vld_pipe_2 <= 'b0;
        end
        else begin
            mult_2_vld_pipe_1 <= fft_local_o_vld;
            mult_2_vld_pipe_2 <= mult_2_vld_pipe_1;
        end
    end
    logic   signed  [33:0]  mult_2_re_1_pipe_1_tmp;
    logic   signed  [16:0]  mult_2_re_1_pipe_1_shift;
    logic   signed  [33:0]  mult_2_re_2_pipe_1_tmp;
    logic   signed  [16:0]  mult_2_re_2_pipe_1_shift;
    logic   signed  [33:0]  mult_2_im_1_pipe_1_tmp;
    logic   signed  [16:0]  mult_2_im_1_pipe_1_shift;
    logic   signed  [33:0]  mult_2_im_2_pipe_1_tmp;
    logic   signed  [16:0]  mult_2_im_2_pipe_1_shift;
    always_comb begin
        if(~(|fft_local_ca_id_pipe_2[4:0])) begin   // if ca_code == 0
            mult_2_re_1_pipe_1_tmp = fft_rcv_o_data.data_re * fft_local_o_data.data_re;
            mult_2_re_2_pipe_1_tmp = fft_rcv_o_data.data_im * (-fft_local_o_data.data_im);
            mult_2_im_1_pipe_1_tmp = fft_rcv_o_data.data_re * (-fft_local_o_data.data_im);
            mult_2_im_2_pipe_1_tmp = fft_rcv_o_data.data_im * fft_local_o_data.data_re;
        end
        else begin
            mult_2_re_1_pipe_1_tmp = fft_rcv_br_o.data_re * fft_local_o_data.data_re;
            mult_2_re_2_pipe_1_tmp = fft_rcv_br_o.data_im * (-fft_local_o_data.data_im);
            mult_2_im_1_pipe_1_tmp = fft_rcv_br_o.data_re * (-fft_local_o_data.data_im);
            mult_2_im_2_pipe_1_tmp = fft_rcv_br_o.data_im * fft_local_o_data.data_re;
        end
    end
    assign  mult_2_re_1_pipe_1_shift = mult_2_re_1_pipe_1_tmp >>> 15;
    assign  mult_2_re_2_pipe_1_shift = mult_2_re_2_pipe_1_tmp >>> 15;
    assign  mult_2_im_1_pipe_1_shift = mult_2_im_1_pipe_1_tmp >>> 15;
    assign  mult_2_im_2_pipe_1_shift = mult_2_im_2_pipe_1_tmp >>> 15;
    always_ff @(posedge clk) begin
        mult_2_re_1_pipe_1 <= mult_2_re_1_pipe_1_shift;
        mult_2_re_2_pipe_1 <= mult_2_re_2_pipe_1_shift;
        mult_2_im_1_pipe_1 <= mult_2_im_1_pipe_1_shift;
        mult_2_im_2_pipe_1 <= mult_2_im_2_pipe_1_shift;
    end

    // Pipeline stage 3: compute additions/subtractions
    logic   signed  [15:0]  mult_2_re_pipe_2_tmp;
    logic   signed  [15:0]  mult_2_im_pipe_2_tmp;
    assign  mult_2_re_pipe_2_tmp = mult_2_re_1_pipe_1 - mult_2_re_2_pipe_1;
    assign  mult_2_im_pipe_2_tmp = mult_2_im_1_pipe_1 + mult_2_im_2_pipe_1;
    always_ff @(posedge clk) begin
        mult_2_re_pipe_2 <= mult_2_re_pipe_2_tmp;
        mult_2_im_pipe_2 <= mult_2_im_pipe_2_tmp;
    end
    // ----------------------------

    // ---------- post mult 2 ----------
    // post mult 2 done
    always_comb begin
        if(&post_mult_2_ca_id[4:0]) begin
            if(&post_mult_2_cnt[11:0]) begin
                post_mult_2_done_tmp = 'b1;
            end
            else begin
                post_mult_2_done_tmp = 'b0;
            end
        end
        else begin
            post_mult_2_done_tmp = 'b0;
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            post_mult_2_done <= 'b1;
        end
        else begin
            post_mult_2_done <= post_mult_2_done_tmp;
        end
    end
    // post mult 2 cnt
    assign  post_mult_2_cnt_tmp = post_mult_2_cnt + 1'b1;
    always_comb begin
        if(mult_2_vld_pipe_2) begin
            post_mult_2_cnt_nxt = post_mult_2_cnt_tmp;
        end
        else begin
            post_mult_2_cnt_nxt = post_mult_2_cnt;
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            post_mult_2_cnt <= 'b0;
        end
        else begin
            post_mult_2_cnt <= post_mult_2_cnt_nxt;
        end
    end
    // post mult 2 ca id
    assign  post_mult_2_ca_id_tmp = post_mult_2_ca_id + 1'b1;
    always_comb begin
        if(&post_mult_2_cnt[11:0]) begin
            post_mult_2_ca_id_nxt = post_mult_2_ca_id_tmp;
        end
        else begin
            post_mult_2_ca_id_nxt = post_mult_2_ca_id;
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            post_mult_2_ca_id <= 'b0;
        end
        else begin
            post_mult_2_ca_id <= post_mult_2_ca_id_nxt;
        end
    end
    // ---------------------------------

    // ---------- ifft ----------
    ifft_top ifft(
        .clk        (clk),
        .rst_n      (rst_n),
        .i_vld      (ifft_i_vld),
        .i_data     (ifft_i_data),
        .i_sync     (ifft_i_sync),
        .i_sync_rst (ifft_i_sync_rst),
        .o_vld      (ifft_o_vld),
        .o_data     (ifft_o_data),
        .o_sync     (ifft_o_sync)
    );
    assign  ifft_i_vld = mult_2_vld_pipe_2;
    assign  ifft_i_data = '{mult_2_re_pipe_2, mult_2_im_pipe_2};
    assign  ifft_i_sync = ~(|post_mult_2_cnt[11:0]);
    assign  ifft_i_sync_rst_tmp = (&post_mult_2_cnt[11:0]) & (&post_mult_2_ca_id[4:0]);
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            ifft_i_sync_rst <= 'b0;
        end
        else begin
            ifft_i_sync_rst <= ifft_i_sync_rst_tmp;
        end
    end
    // --------------------------


    // ---------- post ifft ----------
    // post ifft ca id
    assign  post_ifft_ca_id_tmp = post_ifft_ca_id + 1'b1;
    always_comb begin
        if(ifft_o_vld) begin
            post_ifft_ca_id_nxt = post_ifft_ca_id_tmp;
        end
        else begin
            post_ifft_ca_id_nxt = post_ifft_ca_id;
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            post_ifft_ca_id <= 'b0;
        end
        else begin
            post_ifft_ca_id <= post_ifft_ca_id_nxt;
        end
    end

    // post ifft cnt
    assign  post_ifft_cnt_tmp = post_ifft_cnt + 1'b1;
    always_comb begin
        if(ifft_o_vld) begin
            post_ifft_cnt_nxt = post_ifft_cnt_tmp;
        end
        else begin
            post_ifft_cnt_nxt = post_ifft_cnt;
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            post_ifft_cnt <= 'b0;
        end
        else begin
            post_ifft_cnt <= post_ifft_cnt_nxt;
        end
    end
    // -------------------------------

    // ---------- output assignment ----------
    logic   signed  [14:0]  doppler_shift_tmp;
    logic   signed  [14:0]  doppler_shift_nxt;
    logic   signed  [14:0]  doppler_shift;
    assign  doppler_shift_tmp = doppler_shift - 15'b000000011111010;    // minus for 250Hz each time
    always_comb begin
        if(&post_ifft_cnt[11:0]) begin
            doppler_shift_nxt = doppler_shift_tmp;
        end
        else begin
            doppler_shift_nxt = doppler_shift;
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            doppler_shift <= 15'b010011100010000;       // init +10kHz
        end
        else begin
            doppler_shift <= doppler_shift_nxt;
        end
    end
    assign  s_axis_tready = (~ibuf_o_full);
    assign  m_axis_tvalid = ifft_o_vld;
    assign  m_axis_tdata_re = ifft_o_data.data_re;
    assign  m_axis_tdata_im = ifft_o_data.data_im;
    assign  m_axis_tprn_id = post_ifft_ca_id;
    assign  m_axis_td_shift = doppler_shift;
    assign  m_axis_tposition = post_ifft_cnt;
    // ---------------------------------------

endmodule
