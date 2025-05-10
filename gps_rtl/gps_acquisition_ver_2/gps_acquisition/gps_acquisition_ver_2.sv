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

import fft_pkg::*;
`define ADD
// `define TESTING

module gps_acquisition(
    input   logic                           clk,
    input   logic                           rst_n,

    // input data from sdr and output tready to sdr
    input   logic                           s_axis_tvalid,      // tvalid
    input   logic   signed  [15:0]          s_axis_tdata_i,     // gps_i
    input   logic   signed  [15:0]          s_axis_tdata_q,     // gps_q
    output  logic                           s_axis_tready,      // tready

    // input tready, output data from/to gps_dispatcher
    output  logic                           m_axis_tvalid,      // tvalid to dispatcher
    output  logic   signed  [15:0]          m_axis_tdata,
    output  logic           [4:0]           m_axis_tprn_id,     // prn id
    output  logic   signed  [14:0]          m_axis_td_shift,    // doppler shift
    output  logic           [11:0]          m_axis_tposition    // code phase delay (just simply the position of the current ifft output
                                                                // from this position, we can compute the code phase delay)
                                                                // formula: (position/4096) * 1023
);

    // ############### Signal Declaration ###############
    // ---------- input buffer ----------
    dat_gps_t       ibuf_i_data;
    logic   [11:0]  ibuf_i_rd_addr;             
    dat_gps_t       ibuf_o_data;
    logic           ibuf_o_full;

    // ---------- accumulator ----------
    logic   [5:0]   acc_i_doppler_id;           
    logic   [5:0]   acc_i_doppler_id_nxt;
    logic   [5:0]   acc_i_doppler_id_tmp;
    logic   [5:0]   acc_i_doppler_id_add;
    logic   [5:0]   acc_i_doppler_id_sub;
    logic           toggle;                         // to choose between positive/negative values of sine output from cordic, 0 for posi and 1 for nega
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
    logic   [11:0]          cord_br_wraddr_tmp;
    logic   [11:0]          cord_br_wraddr_nxt;
    logic   [11:0]          cord_br_rdaddr;
    dat_gps_t               cord_br [0:4095];       // bram stores cordic output
    dat_gps_t               cord_br_o;

    // ---------- pre mult 1 ----------
    logic           fft_rcv_start;          // flag to start computing input for the fft of the received signal
    logic   [11:0]  pre_mult_1_cnt;
    logic   [11:0]  pre_mult_1_cnt_nxt;
    logic   [11:0]  pre_mult_1_cnt_tmp;

    // ---------- mult 1 ----------
    logic                       mult_1_vld_pipe_1;      // pipeline vld 1 stage to synchronize with data out from bram ibuf
    logic                       mult_1_vld_pipe_2;
    logic                       mult_1_vld_pipe_3;
    logic                       mult_1_vld_pipe_4;
    logic                       mult_1_vld_pipe_5;
    logic   signed  [15:0]      mult_1_re_pipe_2    [0:1];
    logic   signed  [15:0]      mult_1_im_pipe_2    [0:1];
    logic   signed  [15:0]      mult_1_re_pipe_3;       // (ibuf_re) x (cord_o_cos) - (ibuf_im) x (cord_o_sin)
    logic   signed  [15:0]      mult_1_im_pipe_3;       // (ibuf_re) x (cord_o_sin) + (ibuf_im) x (cord_o_cos)

    // ---------- post mult 1 ----------
    logic           post_mult_1_vld;        // input valid of fft
    data_t          post_mult_1_data;

    // ---------- precomputed_ca ----------
    logic   signed  [DAT_WIDTH-1:0]   ca_o_data   [0:31];
    // ------------------------------------

    // ---------- fft (local ca code) ----------
    fsm_state_t     pre_fft_current_state;
    logic   [11:0]  pre_fft_counter;
    logic   [11:0]  pre_fft_nxt_counter;
    logic   [4:0]   pre_fft_prn;
    logic           fft_i_vld;
    logic           fft_o_vld;
    data_t          fft_i_data;
    data_t          fft_o_data;
    logic           fft_rcv_vld;
    logic           fft_local_vld;
    logic   [4:0]   post_fft_prn;
    logic   [11:0]  post_fft_counter;
    fsm_state_t     post_fft_current_state;
    logic   [6:0]   post_fft_doppler;
    
    // ---------- mult 2 ----------
    logic   signed  [IFFT_D_WIDTH*2-16:0]   mult_2_re_pipe_1    [0:1];
    logic   signed  [IFFT_D_WIDTH*2-16:0]   mult_2_im_pipe_1    [0:1];
    logic   signed  [IFFT_D_WIDTH-1:0]      mult_2_re_pipe_2;       // (fft_rcv_re) x (fft_local_re)  - (fft_rcv_im) x (-fft_local_im)
    logic   signed  [IFFT_D_WIDTH-1:0]      mult_2_im_pipe_2;       // (fft_rcv_re) x (-fft_local_im) + (fft_rcv_im) x (fft_local_re)

    // ---------- ifft ----------
    logic           ifft_i_vld;
    ifft_data_t     ifft_i_data;
    logic           ifft_o_vld;
    logic   signed  [15:0]  ifft_o_data;
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

        .o_data(ibuf_o_data),
        .o_full(ibuf_o_full)
    );
    assign  ibuf_i_data = '{s_axis_tdata_i, s_axis_tdata_q};
    assign  ibuf_i_rd_addr = {pre_mult_1_cnt[11:0]};
    // ------------------------------------------------



    // ---------- accumulator instantiation ----------
    // - Accumulator to increase/decrease the angle sent to cordic depending on the dopper shift id
    // - acc_start is asserted only in 1 cycle to "power on" the accumulator and then the accumulator will automatically compute all shifting 
    // values for that doppler shift. This signal is asserted when
    //      + At the beginning, whenever rst_n is asserted
    //      + Then, whenever the post_mult_1_cnt is 4095 acc_start will be asserted, which means the accumulator will start working again
    //        to compute the shifting values of the next doppler shift whenever the amount of data is sent to the fft_rcv is enough (4096 data)
    // - acc_i_doppler_id is the dopper id passed to accumulator. There are 81 doppler shifts from -10kHz to +10kHz with step 250Hz 
    // but we only need 41 doppler shift ids together with 1 bit toggle to indicate whether the doppler shift is in positive region 
    // [+10kHz -> 0Hz] or negative region [-250Hz -> -10kHz]. This signal changes its value when
    //      + Initilized with 0 when receive rst_n
    //      + acc_start_tmp is asserted. Using acc_start_tmp to synchronize with the acc_start signal, if using the acc_start signal, instead, the
    //        value of the acc_i_doppler_id can not be updated on time --> Wrong behavior
    // - o_vld and o_angle directly goes to the i_vld of the cordic module
    accumulator acc (
        .clk(clk),
        .rst_n(rst_n),
        .i_start(acc_start),
        .i_doppler_id(acc_i_doppler_id),                  // doppler id: 0 ---> 40 corresponding to f = +10kHz ---> 0Hz
    
        .o_vld(acc_o_vld),
        .o_angle(acc_o_angle)
    );

    // compute i_doppler_id (using add or sub depending on the toggle as mentioned above)
    assign  acc_i_doppler_id_add = acc_i_doppler_id + 1'b1;
    assign  acc_i_doppler_id_sub = acc_i_doppler_id - 1'b1;
    always_comb begin
        if(toggle) begin
            acc_i_doppler_id_tmp = acc_i_doppler_id_sub;
            toggle_tmp = toggle;
        end
        else begin
            if(acc_i_doppler_id_add > 40) begin     // when the doppler_id reaches 41 --> go back to 40 similarly to the doppler shift is 0Hz then go back to -250Hz (250Hz has id of 39)
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
        if(acc_start_tmp) begin                     // using acc_start_tmp as the condition to synchronize the acc_i_doppler_id with the acc_start signal
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
        if(acc_start) begin                     // acc_start is only allowed to be asserted in 1 cycle
            acc_start_tmp = 'b0;
        end
        else begin
            if(&pre_fft_counter[11:0] && (pre_fft_current_state == FFT_RCV)) begin    // when post_mult_1_cnt reaches 4095, there are enough data sent to fft_rcv => start the accumulator in the next cycle
                acc_start_tmp = 'b1;
            end
            else begin
                acc_start_tmp = 'b0;            // else still keep 0
            end
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin                        // when reset, it means the system started running again --> start computing the doppler shift from early
            acc_start <= 'b1;
        end
        else begin
            acc_start <= acc_start_tmp;
        end
    end
    // --------------------------------------------------------


    // ---------- cordic instantiation ----------
    // - CORDIC algorithm used for computing cosine and sine functions of input angle
    cordic  cord(
        .clk(clk),
        .rst_n(rst_n),
        .i_vld(acc_o_vld),
        .i_angle(acc_o_angle),
        .o_cosine(cord_o_cos),
        .o_sine(cord_o_sin),
        .o_vld(cord_o_vld)
    );

    // bram for cordic
    // - As mentioned, whenever the accumulator is allowed to start, it will operate until it reaches 4096 output angles continuously. And these output angles are
    //   sent to the cordic module continuously also. Therefore, we need a BRAM to store the output.
    // - cord_br_rdaddr is the read address and it
    assign  cord_br_rdaddr = pre_mult_1_cnt;
    assign  cord_br_wraddr_tmp = cord_br_wraddr + 1'b1;
    always_comb begin
        if(cord_o_vld) begin
            cord_br_wraddr_nxt = cord_br_wraddr_tmp;
        end
        else begin
            cord_br_wraddr_nxt = cord_br_wraddr;
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            cord_br_wraddr <= 'b0;
        end
        else begin
            cord_br_wraddr <= cord_br_wraddr_nxt;
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
    // process fft_rcv_start
    // - fft_rcv_start is asserted when:
    //      + at the beginning, after asserting rst_n, fft_rcv_start depends on whether the brams of shifting values and the input buffer are full or not
    //      + then, fft_rcv_start will depend on the post_mult_2_done, which depends on post_mult_2_ca_id and post_mult_2_cnt
    //      + signal start_en is used to indicate whether the fft_rcv_start depends on full of bram of shifting values or on post_mult_2_cnt
    //      + post_mult_2_done is asserted whenever the ca id is 31 (5'b11111) and the counter reaches 4095(12'b11...1), it means
    //        the counter and ca id in the next cycle will be back to 0
    logic   start_en;
    logic   start_en_tmp;
    logic   cord_done;
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            cord_done <= 'b0;
        end
        else begin
            if(&cord_br_wraddr[11:0]) begin
                cord_done <= 'b1;
            end
        end
    end
    
    assign  start_en_tmp = (cord_done & ibuf_o_full);
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            start_en <= 'b0;
        end
        else begin
            if(~start_en) begin
                start_en <= start_en_tmp;
            end
        end
    end
    
    logic   fft_rcv_start_tmp;
    always_comb begin
        if((pre_fft_counter == 4090) && (&pre_fft_prn[4:0])) begin
            fft_rcv_start_tmp = 'b1;
        end
        else begin
            fft_rcv_start_tmp = 'b0;
        end
        // if((fft_local_cnt_pipe_1 == 4091) && (&fft_local_ca_id_pipe_1[4:0])) begin
        //     fft_rcv_start_tmp = 'b1;
        // end
        // else begin
        //     fft_rcv_start_tmp = 'b0;
        // end
    end
        
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            fft_rcv_start <= 'b0;
        end
        else begin
            if(~start_en) begin
                fft_rcv_start <= start_en_tmp;
            end
            else begin
                fft_rcv_start <= fft_rcv_start_tmp;
            end
        end
    end
    
    // process pre_mult_1_cnt
    assign  pre_mult_1_cnt_tmp = pre_mult_1_cnt + 1'b1;
    always_comb begin
        if(~(|pre_mult_1_cnt[11:0])) begin      // if cnt_pre_mult == 0, wait for flag fft_rcv_start
            if(fft_rcv_start) begin
                pre_mult_1_cnt_nxt = pre_mult_1_cnt_tmp;
            end
            else begin
                pre_mult_1_cnt_nxt = 'b0;
            end
        end
        else begin                              // if the value of pre_mult_1_cnt is not 0 -> keep increasing the value until it reaches 4095
            pre_mult_1_cnt_nxt = pre_mult_1_cnt_tmp;
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
    logic   [11:0]  pre_mult_1_cnt_pipe;
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            pre_mult_1_cnt_pipe <= 'b0;
        end
        else begin
            pre_mult_1_cnt_pipe <= pre_mult_1_cnt;
        end
    end
    // --------------------------------


    // ---------- mult 1 ----------
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            mult_1_vld_pipe_1 <= 'b0;
            mult_1_vld_pipe_2 <= 'b0;
            mult_1_vld_pipe_3 <= 'b0;
            mult_1_vld_pipe_4 <= 'b0;
            mult_1_vld_pipe_5 <= 'b0;
        end
        else begin
            if(~mult_1_vld_pipe_1) begin
                mult_1_vld_pipe_1 <= fft_rcv_start;
            end
            else begin
                mult_1_vld_pipe_1 <= ~(&pre_mult_1_cnt_pipe[11:0]);
            end
            mult_1_vld_pipe_2 <= mult_1_vld_pipe_1;
            mult_1_vld_pipe_3 <= mult_1_vld_pipe_2;
            mult_1_vld_pipe_4 <= mult_1_vld_pipe_3;
            mult_1_vld_pipe_5 <= mult_1_vld_pipe_4;
        end
    end

    // Pipeline stage 2: compute multiplications
    // - 2 things to be noted when computing the multiplication between the received signal and the shifting values:
    //      1) The result has been 0 since pre_mult_1_cnt reached 4000 (96 sequence of 0 from 4000 to 4095).
    //      2) The sine result of the shifting value is sign-reversed when the toggle indicates the region of negative doppler shifts [-250Hz;-10kHz]
    logic   signed  [31:0]  mult_1_re_pipe_2_tmp    [0:1];
    logic   signed  [15:0]  mult_1_re_pipe_2_shift  [0:1];
    logic   signed  [31:0]  mult_1_im_pipe_2_tmp    [0:1];
    logic   signed  [15:0]  mult_1_im_pipe_2_shift  [0:1];
    
    always_ff @(posedge clk) begin       // this always_comb is used to process the 2nd note above
        if(toggle) begin    // when (toggle) -> reverse the sign of imaginary parts
            mult_1_re_pipe_2_tmp[0] <= ibuf_o_data.gps_i * cord_br_o.gps_i;
            mult_1_re_pipe_2_tmp[1] <= ibuf_o_data.gps_q * (cord_br_o.gps_q);
            mult_1_im_pipe_2_tmp[0] <= ibuf_o_data.gps_i * (cord_br_o.gps_q);
            mult_1_im_pipe_2_tmp[1] <= ibuf_o_data.gps_q * cord_br_o.gps_i;
        end
        else begin          // when (~toggle) -> keep the sign
            mult_1_re_pipe_2_tmp[0] <= ibuf_o_data.gps_i * cord_br_o.gps_i;
            mult_1_re_pipe_2_tmp[1] <= ibuf_o_data.gps_q * (-cord_br_o.gps_q);
            mult_1_im_pipe_2_tmp[0] <= ibuf_o_data.gps_i * (-cord_br_o.gps_q);
            mult_1_im_pipe_2_tmp[1] <= ibuf_o_data.gps_q * cord_br_o.gps_i;
        end
    end

    dat_gps_t   data_temp_doppler_0hz;
    always_ff @(posedge clk) begin
        data_temp_doppler_0hz <= ibuf_o_data;
    end
    always_ff @(posedge clk) begin                                                   // this always_comb is used to process the 1st note above
        if(acc_i_doppler_id==40) begin                                  // if doppler shift is 0 -> take directly data from ibuf instead of multiplying it
            mult_1_re_pipe_2_shift[0] <= data_temp_doppler_0hz.gps_i;
            mult_1_re_pipe_2_shift[1] <= 'b0;
            mult_1_im_pipe_2_shift[0] <= data_temp_doppler_0hz.gps_q;
            mult_1_im_pipe_2_shift[1] <= 'b0;
        end
        else begin
            mult_1_re_pipe_2_shift[0] <= mult_1_re_pipe_2_tmp[0] >>> 15;
            mult_1_re_pipe_2_shift[1] <= mult_1_re_pipe_2_tmp[1] >>> 15;
            mult_1_im_pipe_2_shift[0] <= mult_1_im_pipe_2_tmp[0] >>> 15;
            mult_1_im_pipe_2_shift[1] <= mult_1_im_pipe_2_tmp[1] >>> 15;
        end
    end

    always_ff @(posedge clk) begin
        mult_1_re_pipe_2[0] <= mult_1_re_pipe_2_shift[0];
        mult_1_re_pipe_2[1] <= mult_1_re_pipe_2_shift[1];
        mult_1_im_pipe_2[0] <= mult_1_im_pipe_2_shift[0];
        mult_1_im_pipe_2[1] <= mult_1_im_pipe_2_shift[1];
    end

    // Pipeline stage 3: compute additions/subtractions
    logic   signed  [15:0]  mult_1_re_pipe_3_tmp;
    logic   signed  [15:0]  mult_1_im_pipe_3_tmp;
    assign  mult_1_re_pipe_3_tmp = mult_1_re_pipe_2[0] - mult_1_re_pipe_2[1];
    assign  mult_1_im_pipe_3_tmp = mult_1_im_pipe_2[0] + mult_1_im_pipe_2[1];
    always_ff @(posedge clk) begin
        mult_1_re_pipe_3 <= mult_1_re_pipe_3_tmp;
        mult_1_im_pipe_3 <= mult_1_im_pipe_3_tmp;
    end
    // ----------------------------


    // ---------- post mult 1 ----------
    assign  post_mult_1_vld = mult_1_vld_pipe_5;
    `ifdef NON_SCALE
        assign  post_mult_1_data.data_re = {{12{mult_1_re_pipe_3[15]}}, mult_1_re_pipe_3[15:0]};
        assign  post_mult_1_data.data_im = {{12{mult_1_im_pipe_3[15]}}, mult_1_im_pipe_3[15:0]};
    `else
        assign  post_mult_1_data.data_re = {mult_1_re_pipe_3[15], mult_1_re_pipe_3[15:0]};
        assign  post_mult_1_data.data_im = {mult_1_im_pipe_3[15], mult_1_im_pipe_3[15:0]};
    `endif
    // ---------------------------------
    
    // ---------- PRE FFT FSM ----------
    fsm pre_fft_fsm(
        .clk(clk),
        .rst_n(rst_n),
        
        .counter(pre_fft_counter),
        .prn(pre_fft_prn),
        
        .current_state(pre_fft_current_state)
    );
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            pre_fft_counter <= 'b0;
            pre_fft_prn <= 'b0;
        end
        else begin
            if(fft_i_vld) begin
                pre_fft_counter <= pre_fft_counter + 'b1;
            end

            if((&pre_fft_counter[11:0]) && (pre_fft_current_state == FFT_LOCAL)) begin
                pre_fft_prn <= pre_fft_prn + 'b1;
            end
        end
    end
    always_ff @(posedge clk) begin
        pre_fft_nxt_counter[0] <= pre_fft_counter[0];
        pre_fft_nxt_counter[11:1] <= pre_fft_counter[11:1] + 1'b1;
    end
    // ---------------------------------

    // ---------- FFT ----------
    fft_top fft(
        .clk        (clk),
        .rst_n      (rst_n),
        .i_vld      (fft_i_vld),
        .i_data     (fft_i_data),
        .last_data  (fft_last_data),

        .o_vld      (fft_o_vld),
        .o_data     (fft_o_data)
    );

    assign  fft_rcv_vld = post_mult_1_vld;
    assign  fft_local_vld = (pre_fft_current_state == FFT_LOCAL);

    assign  fft_i_vld = fft_rcv_vld | fft_local_vld;
    always_comb begin
        if(pre_fft_current_state == FFT_RCV) begin
            fft_i_data = post_mult_1_data;
        end
        else begin
            `ifdef NON_SCALE
                fft_i_data.data_re = {{12{ca_o_data[pre_fft_prn][DAT_WIDTH-1]}},ca_o_data[pre_fft_prn]};
                fft_i_data.data_im = {D_WIDTH{1'b0}};
            `else
                fft_i_data.data_re = {ca_o_data[pre_fft_prn][DAT_WIDTH-1],ca_o_data[pre_fft_prn]};
                fft_i_data.data_im = {D_WIDTH{1'b0}};
            `endif
        end
    end

    assign  fft_last_data = ((post_fft_doppler == 80) && (&post_fft_prn[4:0]));
    // -------------------------

    // ---------- POST FFT FSM ----------
    fsm post_fft_fsm(
        .clk(clk),
        .rst_n(rst_n),
        
        .counter(post_fft_counter),
        .prn(post_fft_prn),
        
        .current_state(post_fft_current_state)
    );
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            post_fft_prn <= 'b0;
            post_fft_counter <= 'b0;
            post_fft_doppler <= 'b0;
        end
        else begin
            if(fft_o_vld) begin
                post_fft_counter <= post_fft_counter + 'b1;
            end

            if((&post_fft_counter[11:0]) && (post_fft_current_state == FFT_LOCAL)) begin
                post_fft_prn <= post_fft_prn + 'b1;
            end

            if((&post_fft_counter[11:0]) && (post_fft_current_state == FFT_LOCAL) && (&post_fft_prn[4:0])) begin
                post_fft_doppler <= post_fft_doppler + 'b1;
            end
        end
    end
    // ----------------------------------

    // ---------- BRAM (store fft of received signals) ----------
    logic   [11:0]  fft_rcv_bram_rdaddr;
    logic   [11:0]  fft_rcv_bram_wraddr;
    logic   fft_rcv_bram_rd_vld;
    logic   fft_rcv_bram_wr_vld;
    logic   fft_rcv_bram_o_vld;
    data_t  fft_rcv_bram_o_data;
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            fft_rcv_bram_rdaddr <= 'b0;
            fft_rcv_bram_wraddr <= 'b0;
        end
        else begin
            if(fft_o_vld) begin
                if(post_fft_current_state == FFT_RCV) begin
                    fft_rcv_bram_wraddr <= fft_rcv_bram_wraddr + 'b1;
                end
                else begin
                    fft_rcv_bram_rdaddr <= fft_rcv_bram_rdaddr + 'b1;
                end
            end
        end
    end
    always_comb begin
        if(post_fft_current_state == FFT_RCV) begin
            fft_rcv_bram_wr_vld = fft_o_vld;
        end
        else begin
            fft_rcv_bram_wr_vld = 'b0;
        end
    end
    assign  fft_rcv_bram_rd_vld = (post_fft_current_state == FFT_LOCAL);
    bram    #(
        .ADDR_WIDTH(11)
    ) bram_fft_rcv(
        .clk(clk),
        .rst_n(rst_n),
        
        .i_wraddr(fft_rcv_bram_wraddr),
        .i_rdaddr(fft_rcv_bram_rdaddr),
    
        .i_wr_vld(fft_rcv_bram_wr_vld),
        .i_rd_vld(fft_rcv_bram_rd_vld),
        .i_data(fft_o_data),

        .o_vld(fft_rcv_bram_o_vld),
        .o_data(fft_rcv_bram_o_data)
    );
    // ----------------------------------------------------------

    // ---------- MULT 2 ----------
    // `ifdef NON_SCALE
        data_t  fft_local_o_data;
    // `else

    // `endif
    logic   [5:0]   mult_2_vld;
    always_ff @(posedge clk) begin
        if(post_fft_current_state == FFT_LOCAL && fft_o_vld) begin
            // `ifdef NON_SCALE
                fft_local_o_data.data_re <= fft_o_data.data_re;
                fft_local_o_data.data_im <= (-fft_o_data.data_im);
            // `else
            //     fft_local_o_data.data_re <= fft_o_data.data_re <<< 12;
            //     fft_local_o_data.data_im <= -(fft_o_data.data_im <<< 12);
            // `endif
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            mult_2_vld[0] <= 'b0;
            mult_2_vld[1] <= 'b0;
            mult_2_vld[2] <= 'b0;
            mult_2_vld[3] <= 'b0;
            mult_2_vld[4] <= 'b0;
            mult_2_vld[5] <= 'b0;
        end
        else begin
            if(post_fft_current_state == FFT_LOCAL) begin
                mult_2_vld[0] <= fft_o_vld;
            end
            else begin
                mult_2_vld[0] <= 'b0;
            end

            mult_2_vld[1] <= mult_2_vld[0];
            mult_2_vld[2] <= mult_2_vld[1];
            mult_2_vld[3] <= mult_2_vld[2];
            mult_2_vld[4] <= mult_2_vld[3];
            mult_2_vld[5] <= mult_2_vld[4];
        end
    end
    logic   signed  [IFFT_D_WIDTH*2-1:0]    mult_2_re_pipe_1_tmp    [0:1];
    logic   signed  [IFFT_D_WIDTH*2-1:0]    mult_2_im_pipe_1_tmp    [0:1];
    logic   signed  [IFFT_D_WIDTH*2-16:0]   mult_2_re_pipe_1_shift  [0:1];
    logic   signed  [IFFT_D_WIDTH*2-16:0]   mult_2_im_pipe_1_shift  [0:1];

    always_ff @(posedge clk) begin
        `ifdef NON_SCALE
            mult_2_re_pipe_1_tmp[0] <= (fft_rcv_bram_o_data.data_re) * fft_local_o_data.data_re;
            mult_2_re_pipe_1_tmp[1] <= fft_rcv_bram_o_data.data_im * fft_local_o_data.data_im;
            mult_2_im_pipe_1_tmp[0] <= (fft_rcv_bram_o_data.data_re) * fft_local_o_data.data_im;
            mult_2_im_pipe_1_tmp[1] <= fft_rcv_bram_o_data.data_im * fft_local_o_data.data_re;
        `else
            mult_2_re_pipe_1_tmp[0] <= (fft_rcv_bram_o_data.data_re<<<12) * (fft_local_o_data.data_re<<<12);
            mult_2_re_pipe_1_tmp[1] <= (fft_rcv_bram_o_data.data_im<<<12) * (fft_local_o_data.data_im<<<12);
            mult_2_im_pipe_1_tmp[0] <= (fft_rcv_bram_o_data.data_re<<<12) * (fft_local_o_data.data_im<<<12);
            mult_2_im_pipe_1_tmp[1] <= (fft_rcv_bram_o_data.data_im<<<12) * (fft_local_o_data.data_re<<<12);
        `endif
    end
    `ifndef NON_SCALE
        logic   [3:0]   o_rounding_vld_mult_2;
        logic   [IFFT_D_WIDTH*2-FRAC_BIT-1:0]   o_rounding_data_mult_2[0:3];
        convergent_rounding #(.IWIDTH(IFFT_D_WIDTH*2), .OWIDTH(IFFT_D_WIDTH*2-FRAC_BIT)) round_mult_1_0 (
            .clk(clk),
            .rst_n(rst_n),

            .i_vld(mult_2_vld[1]),
            .i_data(mult_2_re_pipe_1_tmp[0]),

            .o_vld(o_rounding_vld_mult_2[0]),
            .o_data(o_rounding_data_mult_2[3])
        );
        convergent_rounding #(.IWIDTH(IFFT_D_WIDTH*2), .OWIDTH(IFFT_D_WIDTH*2-FRAC_BIT)) round_mult_1_1 (
            .clk(clk),
            .rst_n(rst_n),

            .i_vld(mult_2_vld[1]),
            .i_data(mult_2_re_pipe_1_tmp[1]),

            .o_vld(o_rounding_vld_mult_2[1]),
            .o_data(o_rounding_data_mult_2[2])
        );
        convergent_rounding #(.IWIDTH(IFFT_D_WIDTH*2), .OWIDTH(IFFT_D_WIDTH*2-FRAC_BIT)) round_mult_1_2 (
            .clk(clk),
            .rst_n(rst_n),

            .i_vld(mult_2_vld[1]),
            .i_data(mult_2_im_pipe_1_tmp[0]),

            .o_vld(o_rounding_vld_mult_2[2]),
            .o_data(o_rounding_data_mult_2[1])
        );
        convergent_rounding #(.IWIDTH(IFFT_D_WIDTH*2), .OWIDTH(IFFT_D_WIDTH*2-FRAC_BIT)) round_mult_1_3 (
            .clk(clk),
            .rst_n(rst_n),

            .i_vld(mult_2_vld[1]),
            .i_data(mult_2_im_pipe_1_tmp[1]),

            .o_vld(o_rounding_vld_mult_2[3]),
            .o_data(o_rounding_data_mult_2[0])
        );
        assign  mult_2_re_pipe_1[0] = o_rounding_data_mult_2[3];
        assign  mult_2_re_pipe_1[1] = o_rounding_data_mult_2[2];
        assign  mult_2_im_pipe_1[0] = o_rounding_data_mult_2[1];
        assign  mult_2_im_pipe_1[1] = o_rounding_data_mult_2[0];
    `else
        assign  mult_2_re_pipe_1_shift[0] = mult_2_re_pipe_1_tmp[0] >>> 15;
        assign  mult_2_re_pipe_1_shift[1] = mult_2_re_pipe_1_tmp[1] >>> 15;
        assign  mult_2_im_pipe_1_shift[0] = mult_2_im_pipe_1_tmp[0] >>> 15;
        assign  mult_2_im_pipe_1_shift[1] = mult_2_im_pipe_1_tmp[1] >>> 15;
        always_ff @(posedge clk) begin
            mult_2_re_pipe_1[0] <= mult_2_re_pipe_1_shift[0];
            mult_2_re_pipe_1[1] <= mult_2_re_pipe_1_shift[1];
            mult_2_im_pipe_1[0] <= mult_2_im_pipe_1_shift[0];
            mult_2_im_pipe_1[1] <= mult_2_im_pipe_1_shift[1];
        end
    `endif

    logic   signed  [IFFT_D_WIDTH*2-16:0]   mult_2_re_pipe_2_tmp;
    logic   signed  [IFFT_D_WIDTH*2-16:0]   mult_2_im_pipe_2_tmp;
    always_ff @(posedge clk) begin
        mult_2_re_pipe_2_tmp <= mult_2_re_pipe_1[0] - mult_2_re_pipe_1[1];
        mult_2_im_pipe_2_tmp <= mult_2_im_pipe_1[0] + mult_2_im_pipe_1[1];
    end
    logic   signed  [IFFT_D_WIDTH*2-28:0]  mult_2_re_pipe_2_shift;
    logic   signed  [IFFT_D_WIDTH*2-28:0]  mult_2_im_pipe_2_shift;
    always_ff @(posedge clk) begin
        mult_2_re_pipe_2_shift <= mult_2_re_pipe_2_tmp >>> 6;
        mult_2_im_pipe_2_shift <= mult_2_im_pipe_2_tmp >>> 6;
    end
    always_ff @(posedge clk) begin
        mult_2_re_pipe_2 <= (mult_2_re_pipe_2_shift[IFFT_D_WIDTH-1:0]);
        mult_2_im_pipe_2 <= (mult_2_im_pipe_2_shift[IFFT_D_WIDTH-1:0]);
    end
    // ----------------------------

    // ---------- BITREVERSE FFT ----------
    logic   bitreverse_o_vld;
    ifft_data_t bitreverse_o_data;
    bitreverse bitreverse(
        .clk(clk),
        .rst_n(rst_n),

        .i_vld(mult_2_vld[5]),
        .i_data('{mult_2_re_pipe_2, mult_2_im_pipe_2}),

        .o_vld(bitreverse_o_vld),
        .o_data(bitreverse_o_data)
    );
    // ------------------------------------



    // ---------- IFFT ----------
    logic   ifft_last_data;
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            ifft_last_data <= 'b0;
        end
        else begin
            // if((m_axis_tprn_id == 30) && (&m_axis_tposition[11:0]) && (m_axis_td_shift == 5500)) begin
            if((m_axis_tprn_id == 30) && (&m_axis_tposition[11:0]) && (m_axis_td_shift == -10000)) begin
                ifft_last_data <= 'b1;
            end
        end
    end
    ifft_top ifft(
        .clk        (clk),
        .rst_n      (rst_n),

        .i_vld      (bitreverse_o_vld),
        .i_data     (bitreverse_o_data),
        .last_data  (ifft_last_data),

        .o_vld      (ifft_o_vld),
        .o_data     (ifft_o_data)
    );
    // --------------------------
    
    // ---------- POST IFFT ----------
    // post ifft ca id
    // - when the counter reaches 4095 -> increase the ca id by 1
    assign  post_ifft_ca_id_tmp = post_ifft_ca_id + 1'b1;
    always_comb begin
        if(&post_ifft_cnt[11:0]) begin
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
    // - when receiving the valid from ifft, increase the counter by 1
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
    // process doppler shift
    // - doppler shift runs in order from +10kHz to -10kHz with step 250Hz, so the doppler shift will be intialized the value of 10kHz, which is 15'b010011100010000
    // - every time the post_ifft_2_ca_id reaches 31 and the post_ifft_2_cnt reaches 4095 -> minus 250Hz from the current doppler shift to have a new doppler shift value
    logic   signed  [14:0]  doppler_shift_tmp;
    logic   signed  [14:0]  doppler_shift_nxt;
    logic   signed  [14:0]  doppler_shift;
    assign  doppler_shift_tmp = doppler_shift - 15'b000000011111010;    // minus for 250Hz each time
    always_comb begin
        if((&post_ifft_cnt[11:0]) & (&post_ifft_ca_id[4:0])) begin
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
    assign  m_axis_tdata = ifft_o_data;
    assign  m_axis_tprn_id = post_ifft_ca_id;
    assign  m_axis_td_shift = doppler_shift;
    assign  m_axis_tposition = post_ifft_cnt;
    // ---------------------------------------

    // ---------- precomputed_ca ----------
    precomputed_ca ca (
        .clk(clk),
    
        .i_rdaddr(pre_fft_nxt_counter),
        .o_data(ca_o_data)
    );
    // ------------------------------------
endmodule