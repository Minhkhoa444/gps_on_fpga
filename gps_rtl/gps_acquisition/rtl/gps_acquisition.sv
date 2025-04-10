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

// import acquisition_pkg::*;
import fft_pkg::*;
//import ifft_pkg::*;
`define ADD

module gps_acquisition(
    input   logic                           clk,
    input   logic                           rst_n,

    // `ifdef WRAPPER_SV
    //     // input data from precomputed_ca
    //     input   logic   signed  [DAT_WIDTH-1:0] ca_o_data   [0:31],
    //     output  logic   [11:0]  precomputed_ca_rdaddr,
    // `endif

    // input data from sdr and output tready to sdr
    input   logic                           s_axis_tvalid,      // tvalid
    input   logic   signed  [15:0]          s_axis_tdata_i,     // gps_i
    input   logic   signed  [15:0]          s_axis_tdata_q,     // gps_q
    output  logic                           s_axis_tready,      // tready

    // input tready, output data from/to gps_dispatcher
    // input   logic                           m_axis_tready,   // tready from dispatcher
    output  logic                           m_axis_tvalid,      // tvalid to dispatcher
    `ifdef ADD
        output  logic   signed  [15:0]      m_axis_tdata,
    `else
        output  logic   signed  [15:0]      m_axis_tdata_im,    // imaginary part of ifft output    (corr result - imaginary)
        output  logic   signed  [15:0]      m_axis_tdata_re,    // real part of ifft output         (corr result - real)
    `endif
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
    logic   signed  [15:0]      mult_1_re_1_pipe_2;     // (ibuf_re) x (cord_o_cos) 
    logic   signed  [15:0]      mult_1_re_2_pipe_2;     // (ibuf_im) x (cord_o_sin)
    logic   signed  [15:0]      mult_1_im_1_pipe_2;     // (ibuf_re) x (cord_o_sin)
    logic   signed  [15:0]      mult_1_im_2_pipe_2;     // (ibuf_im) x (cord_o_cos)
    logic   signed  [15:0]      mult_1_re_pipe_3;       // (ibuf_re) x (cord_o_cos) - (ibuf_im) x (cord_o_sin)
    logic   signed  [15:0]      mult_1_im_pipe_3;       // (ibuf_re) x (cord_o_sin) + (ibuf_im) x (cord_o_cos)

    // ---------- post mult 1 ----------
    logic           post_mult_1_vld;        // input valid of fft
    data_t          post_mult_1_data;
    logic   [11:0]  post_mult_1_cnt_pipe_1;
    logic   [11:0]  post_mult_1_cnt_pipe_2;
    logic   [11:0]  post_mult_1_cnt_pipe_3;

    // ---------- fft (received signal) ----------
    logic           fft_rcv_i_vld;
    data_t          fft_rcv_i_data;
    `ifndef OPTIMIZE
        logic           fft_rcv_i_sync_rst;
    `endif
    logic           fft_rcv_o_vld;
    data_t          fft_rcv_o_data;
    logic   [11:0]  fft_rcv_br_wraddr;
    logic   [11:0]  fft_rcv_br_rdaddr;
    data_t          fft_rcv_br [0:4095];    // bram stores fft output
    data_t          fft_rcv_br_o_data;

    // ---------- precomputed_ca ----------
    // `ifndef WRAPPER_SV
        logic   signed  [DAT_WIDTH-1:0]   ca_o_data   [0:31];
    // `endif
    // ------------------------------------

    // ---------- fft (local ca code) ----------
    logic           fft_local_i_vld;
    logic           fft_local_i_vld_pipe_1;
    logic           fft_local_i_vld_pipe_1_tmp;
    data_t          fft_local_i_data;
    `ifndef OPTIMIZE
        logic           fft_local_i_sync_rst;
    `endif
    logic           fft_local_o_vld;
    data_t          fft_local_o_data;
    logic   [4:0]   fft_local_ca_id_pipe_1;
    logic   [4:0]   fft_local_ca_id_pipe_1_tmp;
    logic   [4:0]   fft_local_ca_id_pipe_1_nxt;
    logic   [4:0]   fft_local_ca_id_pipe_2;
    logic   [11:0]  fft_local_cnt_pipe_1;
    logic   [11:0]  fft_local_cnt_pipe_1_tmp;
    logic   [11:0]  fft_local_cnt_pipe_1_nxt;
    
    // ---------- pre mult 2 ----------
    logic           pre_mult_2_done;
    logic           pre_mult_2_done_nxt;
    logic   [11:0]  pre_mult_2_cnt;
    logic   [11:0]  pre_mult_2_cnt_tmp;
    logic   [11:0]  pre_mult_2_cnt_nxt;
    logic   [11:0]  nxt_pre_mult_2_cnt;
    logic   [4:0]   pre_mult_2_ca_id;
    logic   [4:0]   pre_mult_2_ca_id_tmp;
    logic   [4:0]   pre_mult_2_ca_id_nxt;
    
    // ---------- mult 2 ----------
    logic                                   mult_2_vld_pipe_1;
    logic   signed  [D_WIDTH*2-16:0]        mult_2_re_1_pipe_1;     // (fft_rcv_re) x (fft_local_re) 
    logic   signed  [D_WIDTH*2-16:0]        mult_2_re_2_pipe_1;     // (fft_rcv_im) x (-fft_local_im) -> minus for complex conjugate
    logic   signed  [D_WIDTH*2-16:0]        mult_2_im_1_pipe_1;     // (fft_rcv_re) x (-fft_local_im) -> minus for complex conjugate
    logic   signed  [D_WIDTH*2-16:0]        mult_2_im_2_pipe_1;     // (fft_rcv_im) x (fft_local_re)
    logic                                   mult_2_vld_pipe_2;
    logic   signed  [D_WIDTH-1:0]           mult_2_re_pipe_2;       // (fft_rcv_re) x (fft_local_re)  - (fft_rcv_im) x (-fft_local_im)
    logic   signed  [D_WIDTH-1:0]           mult_2_im_pipe_2;       // (fft_rcv_re) x (-fft_local_im) + (fft_rcv_im) x (fft_local_re)

    // ---------- post mult 2 ----------
    logic           post_mult_2_done_pipe_1;
    logic           post_mult_2_done_pipe_2;
    logic   [11:0]  post_mult_2_cnt_pipe_1;
    logic   [11:0]  post_mult_2_cnt_pipe_2;
    logic   [4:0]   post_mult_2_ca_id_pipe_1;
    logic   [4:0]   post_mult_2_ca_id_pipe_2;

    // ---------- ifft ----------
    logic           ifft_i_vld;
    data_t          ifft_i_data;
    `ifndef OPTIMIZE
        logic           ifft_i_sync_rst;
        logic           ifft_i_sync_rst_tmp;
    `endif
    logic           ifft_o_vld;
    data_t          ifft_o_data;
    // bitreverse_data_t          ifft_o_data;
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
    // assign  ibuf_i_rd_addr = {1'b0, pre_mult_1_cnt_pipe[11:0]};
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
            if(&post_mult_1_cnt_pipe_3[11:0]) begin    // when post_mult_1_cnt reaches 4095, there are enough data sent to fft_rcv => start the accumulator in the next cycle
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

    // logic flag_acc_start;
    // always_ff @(posedge clk) begin
    //     if(acc_start) begin
    //         flag_acc_start <= 'b1;
    //     end
    // end
//    ila_0 ila_0 (
//        .clk(clk), // input wire clk
    
    
//        .probe0(fft_rcv_i_vld) // input wire [0:0] probe0
//    );

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
    // assign  start_en_tmp = ((&cord_br_wraddr[11:0]) & (ibuf_o_full));
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
    `ifdef OPTIMIZE
        logic   fft_rcv_start_tmp;
        always_comb begin
            if((fft_local_cnt_pipe_1 == 4093) && (&fft_local_ca_id_pipe_1[4:0])) begin
                fft_rcv_start_tmp = 'b1;
            end
            else begin
                fft_rcv_start_tmp = 'b0;
            end
        end
    `endif
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            fft_rcv_start <= 'b0;
        end
        else begin
            if(~start_en) begin
                fft_rcv_start <= start_en_tmp;
            end
            else begin
                `ifdef OPTIMIZE
                    fft_rcv_start <= fft_rcv_start_tmp;
                `else
                    fft_rcv_start <= post_mult_2_done_pipe_2;
                `endif
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
        end
    end

    // Pipeline stage 2: compute multiplications
    // - 2 things to be noted when computing the multiplication between the received signal and the shifting values:
    //      1) The result has been 0 since pre_mult_1_cnt reached 4000 (96 sequence of 0 from 4000 to 4095).
    //      2) The sine result of the shifting value is sign-reversed when the toggle indicates the region of negative doppler shifts [-250Hz;-10kHz]
    logic   signed  [31:0]  mult_1_re_1_pipe_2_tmp;
    logic   signed  [15:0]  mult_1_re_1_pipe_2_shift;
    logic   signed  [31:0]  mult_1_re_2_pipe_2_tmp;
    logic   signed  [15:0]  mult_1_re_2_pipe_2_shift;
    logic   signed  [31:0]  mult_1_im_1_pipe_2_tmp;
    logic   signed  [15:0]  mult_1_im_1_pipe_2_shift;
    logic   signed  [31:0]  mult_1_im_2_pipe_2_tmp;
    logic   signed  [15:0]  mult_1_im_2_pipe_2_shift;
    always_comb begin       // this always_comb is used to process the 2nd note above
        if(toggle) begin    // when (toggle) -> reverse the sign of imaginary parts
            mult_1_re_1_pipe_2_tmp = ibuf_o_data.gps_i * cord_br_o.gps_i;
            mult_1_re_2_pipe_2_tmp = ibuf_o_data.gps_q * (cord_br_o.gps_q);
            mult_1_im_1_pipe_2_tmp = ibuf_o_data.gps_i * (cord_br_o.gps_q);
            mult_1_im_2_pipe_2_tmp = ibuf_o_data.gps_q * cord_br_o.gps_i;
        end
        else begin          // when (~toggle) -> keep the sign
            mult_1_re_1_pipe_2_tmp = ibuf_o_data.gps_i * cord_br_o.gps_i;
            mult_1_re_2_pipe_2_tmp = ibuf_o_data.gps_q * (-cord_br_o.gps_q);
            mult_1_im_1_pipe_2_tmp = ibuf_o_data.gps_i * (-cord_br_o.gps_q);
            mult_1_im_2_pipe_2_tmp = ibuf_o_data.gps_q * cord_br_o.gps_i;
        end
    end
    // Right shift 15 fractional bits after computing
    always_comb begin                                                   // this always_comb is used to process the 1st note above
        if(acc_i_doppler_id==40) begin                                  // if doppler shift is 0 -> take directly data from ibuf instead of multiplying it
            mult_1_re_1_pipe_2_shift = ibuf_o_data.gps_i;
            mult_1_re_2_pipe_2_shift = 'b0;
            mult_1_im_1_pipe_2_shift = ibuf_o_data.gps_q;
            mult_1_im_2_pipe_2_shift = 'b0;
        end
        else begin
            mult_1_re_1_pipe_2_shift = mult_1_re_1_pipe_2_tmp >>> 15;
            mult_1_re_2_pipe_2_shift = mult_1_re_2_pipe_2_tmp >>> 15;
            mult_1_im_1_pipe_2_shift = mult_1_im_1_pipe_2_tmp >>> 15;
            mult_1_im_2_pipe_2_shift = mult_1_im_2_pipe_2_tmp >>> 15;
        end
    end
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
    assign  post_mult_1_data.data_re = {{12{mult_1_re_pipe_3[15]}}, mult_1_re_pipe_3[15:0]};
    assign  post_mult_1_data.data_im = {{12{mult_1_im_pipe_3[15]}}, mult_1_im_pipe_3[15:0]};
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            post_mult_1_cnt_pipe_1 <= 'b0;
            post_mult_1_cnt_pipe_2 <= 'b0;
            post_mult_1_cnt_pipe_3 <= 'b0;            
        end
        else begin
            post_mult_1_cnt_pipe_1 <= pre_mult_1_cnt;
            // post_mult_1_cnt_pipe_1 <= pre_mult_1_cnt_pipe;
            post_mult_1_cnt_pipe_2 <= post_mult_1_cnt_pipe_1;
            post_mult_1_cnt_pipe_3 <= post_mult_1_cnt_pipe_2;
        end
    end
    // ---------------------------------
    
    
    // ---------- fft (received signal) ----------
    // - fft for received signal
    // - fft_rcv_i_vld is asserted by post_mult_1_vld
    // - fft_rcv_i_data is post_mult_1_data
    // - fft_rcv_i_sync is asserted whenever the post mult counter is staying at 0s
    // - fft_rcv_i_sync_rst is asserted to clear the whole fft and ready to run again when pre_mult_2_cnt reaches 4095 (pre_mult_2_done)
    fft_top fft_rcv (
        .clk        (clk),
        .rst_n      (rst_n),
        .i_vld      (fft_rcv_i_vld),
        .i_data     (fft_rcv_i_data),
        `ifndef OPTIMIZE
        .i_sync_rst (fft_rcv_i_sync_rst),
        `endif

        .o_vld      (fft_rcv_o_vld),
        .o_data     (fft_rcv_o_data)
    );
    assign  fft_rcv_i_vld = post_mult_1_vld;
    assign  fft_rcv_i_data = post_mult_1_data;
    `ifndef OPTIMIZE
    // `ifdef OPTIMIZE
    //     assign  fft_rcv_i_sync_rst = 'b0;
    // `else
        assign  fft_rcv_i_sync_rst = pre_mult_2_done;
    `endif

    // bram fft_rcv to store output of fft
    assign  fft_rcv_br_rdaddr = nxt_pre_mult_2_cnt;
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
        fft_rcv_br_o_data <= fft_rcv_br[fft_rcv_br_rdaddr];
    end
    // -------------------------------------------


    // ---------- precomputed_ca ----------
    // `ifndef WRAPPER_SV
        precomputed_ca ca (
            .clk(clk),
        
            .i_rdaddr(fft_local_cnt_pipe_1),
            .o_data(ca_o_data)
        );
    // `else
        // assign precomputed_ca_rdaddr = fft_local_cnt_pipe_1;
    // `endif
    // ------------------------------------


    // ---------- fft (local ca code) ----------
    // - fft for local ca code
    // - fft_local_i_vld is pipelined for 2 stages to synchronize data read from bram storing local ca code
    //      + Stage 1 is equal to mult_1_vld_pipe_2 and this local_i_vld_pipe_1 will be synchronized with mult_1_vld_pipe_3
    //        but we can not in fact assign directly the fft_local_i_vld = mult_1_vld_pipe_3 because mult_1_vld_pipe_3
    //        will stop being asserted after it completes 4096 data for the fft_rcv but we need to assert fft_local_i_vld for longer
    // - fft_local_i_data is the locally generated ca code, here we precomputed all 1023-chip ca code of 32 satellites, upsample to
    //   4000 chip then zero pad to 4096 chips with each chip's size is 17 bits (Q2.15) so in total we need to store 32(sat) x 4096(chip) x 17(Q2.15) = 62 BRAMs.
    //   To read data from precomputed ca bram, we need to use 2-stage pipelined counter. The pipe_1 counter is increased depending on mult_1_vld_pipe_2, which means it will be
    //   delayed 1 cycle in updating the increased value or simply it is synchronized with mult_1_vld_pipe_3, not pipe_2. In general, this operation means the data coming out
    //   of the bram will be delayed 1 cycle in comparison with the valid. This is because the data at index 0 is initially sent out without the need of increasing the value
    //   of counter. So it means if we synchronize the pipe_1 counter with mult_1_vld_pipe_2, the output corresponding to the first valid will be the output at index 1 not 0 and this is WRONG!
    // - fft_local_i_sync = (fft_local_cnt_pipe_2 == 0)
    // - fft_local_i_sync_rst is ON when the system runs to the last ca id (31) and the pre_mult_2 counter runs to the last value (4095), which means
    //          + fft_local_i_sync_rst = ((&ca_id[4:0]) & (&counter[11:0]))
    //          + updated: this ((&ca_id[4:0]) & (&counter[11:0])) is named as pre_mult_2_done
    fft_top fft_local(
        .clk        (clk),
        .rst_n      (rst_n),
        .i_vld      (fft_local_i_vld),
        .i_data     (fft_local_i_data),
        `ifndef OPTIMIZE
        .i_sync_rst (fft_local_i_sync_rst),
        `endif

        .o_vld      (fft_local_o_vld),
        .o_data     (fft_local_o_data)
    );
    // counter
    assign  fft_local_cnt_pipe_1_tmp = fft_local_cnt_pipe_1 + 1'b1;
    always_comb begin
        if(~(|fft_local_ca_id_pipe_1[4:0])) begin
            if(mult_1_vld_pipe_2) begin
                fft_local_cnt_pipe_1_nxt = fft_local_cnt_pipe_1_tmp;
            end
            else begin
                fft_local_cnt_pipe_1_nxt = 'b0;
            end
        end
        else begin
            fft_local_cnt_pipe_1_nxt = fft_local_cnt_pipe_1_tmp;
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            fft_local_cnt_pipe_1 <= 'b0;
        end
        else begin
            fft_local_cnt_pipe_1 <= fft_local_cnt_pipe_1_nxt;   // synchronized with mult_1_vld_pipe_3
        end
    end

    // ca id
    // - ca id: because we have 32 satellites so we need to decide which one will be read out
    //          + there are also 2 stages for ca id, the second is also updated every cycle by the first 
    //          + for the first pipelined ca id, it will be updated based on whether the fft_local_cnt_pipe_1 reaches 4095, because in the next cycle, when
    //            fft_local_cnt_pipe_1 returns back to 0, at the same time, the ca id is also updated to the new id
    assign  fft_local_ca_id_pipe_1_tmp = fft_local_ca_id_pipe_1 + 1'b1;
    always_comb begin
        if(&(fft_local_cnt_pipe_1[11:0])) begin
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
        if(~(|fft_local_ca_id_pipe_1)) begin
            if(~(|fft_local_cnt_pipe_1)) begin
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
        end
        else begin
            fft_local_i_vld_pipe_1 <= fft_local_i_vld_pipe_1_tmp;       // this local vld will be synchronized with the mult_1_vld_pipe_3 for first 4096 cycles then it will be ON
        end
    end
    assign  fft_local_i_vld = fft_local_i_vld_pipe_1;
    assign  fft_local_i_data.data_re = {{12{ca_o_data[fft_local_ca_id_pipe_2][DAT_WIDTH-1]}} ,ca_o_data[fft_local_ca_id_pipe_2]};
    assign  fft_local_i_data.data_im = {DAT_WIDTH{1'b0}};
    `ifndef OPTIMIZE
    // `ifdef OPTIMIZE
    //     assign  fft_local_i_sync_rst = 'b0;
    // `else
        assign  fft_local_i_sync_rst = pre_mult_2_done;
    `endif
    // -----------------------------------------

    // ---------- pre mult 2 ----------
    assign  pre_mult_2_cnt_tmp = pre_mult_2_cnt + 1'b1;
    always_comb begin
        if(fft_local_o_vld) begin
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

    always_ff @(posedge clk) begin
        nxt_pre_mult_2_cnt[0] <= pre_mult_2_cnt[0];
        nxt_pre_mult_2_cnt[11:1] <= pre_mult_2_cnt[11:1] + 1'b1;
    end

    assign  pre_mult_2_ca_id_tmp = pre_mult_2_ca_id + 1'b1;
    always_comb begin
        if(&pre_mult_2_cnt[11:0]) begin
            pre_mult_2_ca_id_nxt = pre_mult_2_ca_id_tmp;
        end
        else begin
            pre_mult_2_ca_id_nxt = pre_mult_2_ca_id;
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            pre_mult_2_ca_id <= 'b0;
        end
        else begin
            pre_mult_2_ca_id <= pre_mult_2_ca_id_nxt;
        end
    end

    // Process pre_mult_2_done
    // - pre_mult_2_done is asserted when the last output of the fft of the last satellite ca code is valid
    always_comb begin
        if((&pre_mult_2_cnt[11:0]) & (&pre_mult_2_ca_id[4:0])) begin        // NOTEEEEEEEEEEEE!?""%#$&*(^)@_@#%$
            pre_mult_2_done_nxt = 'b1;
        end
        else begin
            pre_mult_2_done_nxt = 'b0;
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            pre_mult_2_done <= 'b0;
        end
        else begin
            pre_mult_2_done <= pre_mult_2_done_nxt;
        end
    end
    // --------------------------------

    // ---------- mult 2 ----------
    // - mult 2: the stage when we compute the multiplication between the fft of received signal and the complex conjugate of the fft of the local generated ca code
    // - Because the fft of the received signal is only valid for the first 4096 cycles, which means we can only directly compute the multiplication between the output
    //   of the fft of the received signal and fft of the first ca code. For the multiplication between theFFT of ca code of satellite from sat 1 to sat 31, 
    //   we need to use the fft of the received signal stored in bram. This means that for the complex multiplication C = A x B, in which A is the fft of the received
    //   signal and B is the fft of the locally generated ca code:
    //          + For ca code id = 0, A is taken directly from fft_rcv. For ca code id != 0, A is taken from fft_br_rcv.
    //          + For any ca code id, B is taken directly from fft_local.
    // - valid will be pipelined for 2 stages due to 2 stages of complex multiplier. C = (A_re + A_im*j)(B_re + B_im*j) = (A_re*B_re - A_im*B_im) + j(A_re*B_im + A_im*B_re)
    //                                                                                                                        C_1    -    C_2            C_3    +    C_4
    //                                                                                                                    R     E     A     L      I   M   A   G   I   N   E
    //          + First stage:  Multiplication 
    //                                          C_1 = A_re*B_re
    //                                          C_2 = A_im*(-B_im)
    //                                          C_3 = A_re*(-B_im)
    //                                          C_4 = A_im*B_re
    //                          The minus sign is for complex conjugate. Originally, there are not the minus signs in the formula given above.
    //          + Second stage: Addition/Subtraction
    //                                          result_re = C_1 - C_2
    //                                          result_im = C_3 + C_4
    logic   mult_2_vld_pipe_3;
    logic   mult_2_vld_pipe_4;
    logic   mult_2_vld_pipe_5;
    logic   mult_2_vld_pipe_6;
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            mult_2_vld_pipe_1 <= 'b0;
            mult_2_vld_pipe_2 <= 'b0;
            mult_2_vld_pipe_3 <= 'b0;
            mult_2_vld_pipe_4 <= 'b0;
            mult_2_vld_pipe_5 <= 'b0;
            mult_2_vld_pipe_6 <= 'b0;
        end
        else begin
            mult_2_vld_pipe_1 <= fft_local_o_vld;
            mult_2_vld_pipe_2 <= mult_2_vld_pipe_1;
            mult_2_vld_pipe_3 <= mult_2_vld_pipe_2;
            mult_2_vld_pipe_4 <= mult_2_vld_pipe_3;
            mult_2_vld_pipe_5 <= mult_2_vld_pipe_4;
            mult_2_vld_pipe_6 <= mult_2_vld_pipe_5;
        end
    end
    logic   signed  [D_WIDTH*2-1:0]         mult_2_re_1_pipe_1_tmp;
    logic   signed  [D_WIDTH*2-16:0]        mult_2_re_1_pipe_1_shift;
    logic   signed  [D_WIDTH*2-1:0]         mult_2_re_2_pipe_1_tmp;
    logic   signed  [D_WIDTH*2-16:0]        mult_2_re_2_pipe_1_shift;
    logic   signed  [D_WIDTH*2-1:0]         mult_2_im_1_pipe_1_tmp;
    logic   signed  [D_WIDTH*2-16:0]        mult_2_im_1_pipe_1_shift;
    logic   signed  [D_WIDTH*2-1:0]         mult_2_im_2_pipe_1_tmp;
    logic   signed  [D_WIDTH*2-16:0]        mult_2_im_2_pipe_1_shift;
    data_t  fft_rcv_data_pipe_1;
    data_t  fft_local_data_pipe_1;
    always_ff @(posedge clk) begin
        fft_local_data_pipe_1.data_re <= fft_local_o_data.data_re;
        fft_local_data_pipe_1.data_im <= (-fft_local_o_data.data_im);

        if(~(|pre_mult_2_ca_id[4:0])) begin
            fft_rcv_data_pipe_1 <= fft_rcv_o_data;
        end
        else begin
            fft_rcv_data_pipe_1 <= fft_rcv_br_o_data;
        end
    end
    // assign  mult_2_re_1_pipe_1_tmp = fft_rcv_data_pipe_1.data_re * fft_local_data_pipe_1.data_re;         // A_re * B_re    --> C1
    // assign  mult_2_re_2_pipe_1_tmp = fft_rcv_data_pipe_1.data_im * (fft_local_data_pipe_1.data_im);      // A_im * (-B_im) --> C2
    // assign  mult_2_im_1_pipe_1_tmp = fft_rcv_data_pipe_1.data_re * (fft_local_data_pipe_1.data_im);      // A_re * (-B_im) --> C3
    // assign  mult_2_im_2_pipe_1_tmp = fft_rcv_data_pipe_1.data_im * fft_local_data_pipe_1.data_re;         // A_im * B_re    --> C4
    always_ff @(posedge clk) begin
        mult_2_re_1_pipe_1_tmp <= fft_rcv_data_pipe_1.data_re * fft_local_data_pipe_1.data_re;         // A_re * B_re    --> C1
        mult_2_re_2_pipe_1_tmp <= fft_rcv_data_pipe_1.data_im * (fft_local_data_pipe_1.data_im);      // A_im * (-B_im) --> C2
        mult_2_im_1_pipe_1_tmp <= fft_rcv_data_pipe_1.data_re * (fft_local_data_pipe_1.data_im);      // A_re * (-B_im) --> C3
        mult_2_im_2_pipe_1_tmp <= fft_rcv_data_pipe_1.data_im * fft_local_data_pipe_1.data_re;         // A_im * B_re    --> C4
    end
    // always_comb begin
    //     if(~(|pre_mult_2_ca_id[4:0])) begin   // if ca_code == 0, take A directly from fft_rcv (fft_rcv_o_data)   NOTE!!!!!!!!!^&#$^&$^&@#$
    //         mult_2_re_1_pipe_1_tmp = fft_rcv_o_data.data_re * fft_local_o_data.data_re;         // A_re * B_re    --> C1
    //         mult_2_re_2_pipe_1_tmp = fft_rcv_o_data.data_im * (-fft_local_o_data.data_im);      // A_im * (-B_im) --> C2
    //         mult_2_im_1_pipe_1_tmp = fft_rcv_o_data.data_re * (-fft_local_o_data.data_im);      // A_re * (-B_im) --> C3
    //         mult_2_im_2_pipe_1_tmp = fft_rcv_o_data.data_im * fft_local_o_data.data_re;         // A_im * B_re    --> C4
    //     end
    //     else begin                                  // else take A from bram (fft_rcv_br_o_data)
    //         mult_2_re_1_pipe_1_tmp = fft_rcv_br_o_data.data_re * fft_local_o_data.data_re;
    //         mult_2_re_2_pipe_1_tmp = fft_rcv_br_o_data.data_im * (-fft_local_o_data.data_im);
    //         mult_2_im_1_pipe_1_tmp = fft_rcv_br_o_data.data_re * (-fft_local_o_data.data_im);
    //         mult_2_im_2_pipe_1_tmp = fft_rcv_br_o_data.data_im * fft_local_o_data.data_re;
    //     end
    // end

    // scale down 15 fractional bits after multiplication
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
    logic   signed  [D_WIDTH*2-16:0]  mult_2_re_pipe_2_tmp;
    logic   signed  [D_WIDTH*2-16:0]  mult_2_im_pipe_2_tmp;
    // assign  mult_2_re_pipe_2_tmp = mult_2_re_1_pipe_1 - mult_2_re_2_pipe_1;
    // assign  mult_2_im_pipe_2_tmp = mult_2_im_1_pipe_1 + mult_2_im_2_pipe_1;
    always_ff @(posedge clk) begin
        mult_2_re_pipe_2_tmp <= mult_2_re_1_pipe_1 - mult_2_re_2_pipe_1;
        mult_2_im_pipe_2_tmp <= mult_2_im_1_pipe_1 + mult_2_im_2_pipe_1;
    end
    logic   signed  [D_WIDTH*2-28:0]  mult_2_re_pipe_2_shift;
    logic   signed  [D_WIDTH*2-28:0]  mult_2_im_pipe_2_shift;
    // assign  mult_2_re_pipe_2_shift = mult_2_re_pipe_2_tmp >>> 12;
    // assign  mult_2_im_pipe_2_shift = mult_2_im_pipe_2_tmp >>> 12;
    // assign  mult_2_re_pipe_2_shift = mult_2_re_pipe_2_tmp >>> 6;
    // assign  mult_2_im_pipe_2_shift = mult_2_im_pipe_2_tmp >>> 6;
    always_ff @(posedge clk) begin
        mult_2_re_pipe_2_shift <= mult_2_re_pipe_2_tmp >>> 6;
        mult_2_im_pipe_2_shift <= mult_2_im_pipe_2_tmp >>> 6;
    end
    always_ff @(posedge clk) begin
        mult_2_re_pipe_2 <= (mult_2_re_pipe_2_shift[D_WIDTH-1:0]);
        mult_2_im_pipe_2 <= (mult_2_im_pipe_2_shift[D_WIDTH-1:0]);
    end
    // ----------------------------

    // ---------- post mult 2 ----------
    // post mult 2 done
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            post_mult_2_done_pipe_1 <= 'b0;
            post_mult_2_done_pipe_2 <= 'b0;
        end
        else begin
            post_mult_2_done_pipe_1 <= pre_mult_2_done;
            post_mult_2_done_pipe_2 <= post_mult_2_done_pipe_1;
        end
    end

    // post mult 2 cnt
    always_ff @(posedge clk) begin
        post_mult_2_cnt_pipe_1 <= pre_mult_2_cnt;                         // NOTEEEEEEEEEEEE!?""%#$&*(^)@_@#%$
        post_mult_2_cnt_pipe_2 <= post_mult_2_cnt_pipe_1;
    end

    // post mult 2 ca id
    always_ff @(posedge clk) begin
        post_mult_2_ca_id_pipe_1 <= fft_local_ca_id_pipe_2;
        post_mult_2_ca_id_pipe_2 <= post_mult_2_ca_id_pipe_1;
    end
    // ---------------------------------

    // ---------- ifft ----------
    // - ifft for the result of the multiplication between the fft of the received ca code and the fft of the locally generated ca code
    // - ifft_i_vld is assigned by the valid pipelined stage 2 of the multiplication 2
    // - ifft_i_data is assigned be the result of the multiplication
    // - ifft_i_sync is assigned by the first value of the counter (value 0 or ~|(counter))
    // - ifft_i_sync_rst is assigned by the last value of the post_ifft_counter and the last value of the post_ifft_ca_id
    ifft_top ifft(
        .clk        (clk),
        .rst_n      (rst_n),
        .i_vld      (ifft_i_vld),
        .i_data     (ifft_i_data),
        `ifndef OPTIMIZE
        .i_sync_rst (ifft_i_sync_rst),
        `endif

        .o_vld      (ifft_o_vld),
        .o_data     (ifft_o_data)
    );
    // assign  ifft_i_vld = mult_2_vld_pipe_2;
    assign  ifft_i_vld = mult_2_vld_pipe_6;
    assign  ifft_i_data = '{mult_2_re_pipe_2, mult_2_im_pipe_2};
    `ifndef OPTIMIZE
    // `ifdef OPTIMIZE
    //     assign  ifft_i_sync_rst_tmp = 'b0;
    // `else
        assign  ifft_i_sync_rst_tmp = (&post_ifft_cnt[11:0]) & (&post_ifft_ca_id[4:0]);
        always_ff @(posedge clk, negedge rst_n) begin
            if(~rst_n) begin
                ifft_i_sync_rst <= 'b0;
            end
            else begin
                ifft_i_sync_rst <= ifft_i_sync_rst_tmp;
            end
        end
    `endif
    // --------------------------


    // ---------- post ifft ----------
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

    `ifdef ADD
        // logic   signed  [15:0]   result;
        logic   signed  [D_WIDTH-1:0]   result;
        logic   o_vld_pipe_1;
        logic   o_vld_pipe_2;
        logic   o_vld_pipe_3;
        logic   signed  [14:0]  o_d_shift_pipe_1;
        logic   [11:0]  o_position_pipe_1;
        logic   [4:0]   o_ca_id_pipe_1;
        logic   signed  [14:0]  o_d_shift_pipe_2;
        logic   [11:0]  o_position_pipe_2;
        logic   [4:0]   o_ca_id_pipe_2;
        logic   signed  [14:0]  o_d_shift_pipe_3;
        logic   [11:0]  o_position_pipe_3;
        logic   [4:0]   o_ca_id_pipe_3;
        // logic   [15:0]  o_data_re_pipe;
        // logic   [15:0]  o_data_im_pipe;
        data_t  o_data_pipe_1;
        logic   [55:0]  o_data_re_pipe_1;
        logic   [55:0]  o_data_im_pipe_1;
        logic   [27:0]  o_data_re_pipe_2;
        logic   [27:0]  o_data_im_pipe_2;
        always_ff @(posedge clk, negedge rst_n) begin
            if(~rst_n) begin
                o_vld_pipe_1 <= 'b0;
                o_vld_pipe_2 <= 'b0;
                o_vld_pipe_3 <= 'b0;
                m_axis_tvalid <= 'b0;
            end
            else begin
                o_vld_pipe_1 <= ifft_o_vld;
                o_vld_pipe_2 <= o_vld_pipe_1;
                o_vld_pipe_3 <= o_vld_pipe_2;
                m_axis_tvalid <= o_vld_pipe_3;
            end
        end

        always_ff @(posedge clk) begin
            o_ca_id_pipe_1      <= post_ifft_ca_id;
            o_d_shift_pipe_1    <= doppler_shift;
            o_position_pipe_1   <= post_ifft_cnt;

            o_ca_id_pipe_2      <= o_ca_id_pipe_1;
            o_d_shift_pipe_2    <= o_d_shift_pipe_1;
            o_position_pipe_2   <= o_position_pipe_1;

            o_ca_id_pipe_3      <= o_ca_id_pipe_2;
            o_d_shift_pipe_3    <= o_d_shift_pipe_2;
            o_position_pipe_3   <= o_position_pipe_2;

            m_axis_tprn_id      <= o_ca_id_pipe_3;
            m_axis_td_shift     <= o_d_shift_pipe_3;
            m_axis_tposition    <= o_position_pipe_3;
        end

        always_ff @(posedge clk) begin
            o_data_pipe_1 <= ifft_o_data;

            o_data_re_pipe_1 <= (o_data_pipe_1.data_re * o_data_pipe_1.data_re);
            o_data_im_pipe_1 <= (o_data_pipe_1.data_im * o_data_pipe_1.data_im);

            o_data_re_pipe_2 <= (o_data_re_pipe_1 >>> 15);
            o_data_im_pipe_2 <= (o_data_im_pipe_1 >>> 15);
        end

        // always_ff @(posedge clk) begin
        //     o_data_re_pipe <= (ifft_o_data.data_re * ifft_o_data.data_re) >>> 15;
        //     o_data_im_pipe <= (ifft_o_data.data_im * ifft_o_data.data_im) >>> 15;
        // end

        // assign  result = {16{o_data_re_pipe + o_data_im_pipe}};
        assign  result = {28{o_data_re_pipe_2 + o_data_im_pipe_2}};

        always_ff @(posedge clk) begin
            // m_axis_tdata <= result;
            m_axis_tdata <= result[15:0];
        end
    `else
        assign  m_axis_tvalid = ifft_o_vld;
        // assign  m_axis_tdata_re = ifft_o_data.data_re;
        // assign  m_axis_tdata_im = ifft_o_data.data_im;
        assign  m_axis_tdata_re = ifft_o_data.data_re[15:0];
        assign  m_axis_tdata_im = ifft_o_data.data_im[15:0];
        assign  m_axis_tprn_id = post_ifft_ca_id;
        assign  m_axis_td_shift = doppler_shift;
        assign  m_axis_tposition = post_ifft_cnt;
    `endif
    // ---------------------------------------

endmodule