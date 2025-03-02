`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// University: Ho Chi Minh City University of Technology
// Engineer: Vu Nam Binh
// 
// Create Date: 8th January 2025 08:17:45 AM
// Design Name: Fast Fourier Transform
// Module Name: ifft_stage
// Project Name: Software-defined Radio Global Positioning System FPGA-based Design
// Target Devices: UltraScale 96 v2.0
// Tool Versions: 
// Description: This design is a submodule to implement a stage of a N-point FFT design (not include the prelast and last stages)
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// ---------------------- Port utilization ----------------------
// clk:             - Clock signal
// rst_n:           - Asynchronous reset signal
// i_sync:          - Synchronous signal indicates the first input of ifft (neccessary for memory management)
// twiddle_factor:  - Neccessary twiddle factors for the current stage (not all stages need all twiddle factors so based on SIZE, 
//                  the corresponding numbers of twiddle factor will be passed to the FFT core)
// i_vld:           - Valid signal indicates a valid incoming data (i_vld and i_sync will be ON at the same time only when that is the
//                  first input signal of a sequence of 4096 inputs)
// i_data:          - Input data includes 2 parts (real and imaginary packaged in a typedef struct data_t, check more on ifft_pkg.sv)
// o_sync:          - Similar to i_sync but this is for output
// o_vld:           - Similar to o_vld but this is for output
// o_data:          - Similar to i_data but this is for output
// ---------------------------------------------------------------
//
// --------------------- Working Operation -----------------------
// - At each stage, we do not need to wait for all 4096 input data to start processing the ifft. Instead, we only need to wait for
// a half amount of data input of the size of each stage. For example, the first stage will compute 2048 input pairs. The special
// thing is here: the index 0 together with index 2048 will create 2 outputs (just search for the butterfly in ifft and see the
// characteristics of ifft), and index 1 with 2049, index 2 with 2059, so on. Therefore, we need to store only first 2048 data inputs
// to the first stage. Then since 2049th input, we read data in order data of index 0, 1, 2, 3, ..., 2047 stored in the bram to
// compute the output.
// - The second important thing is that at each stage, when there are enough inputs to be used, 2 outputs can be produced at the
// same time (see butterfly concept on GG): 1 output is just simply do the addition between the stored data in bram and the current
// incoming data, while the other is computed by do the subtraction then multiply by the twiddle factors (we call the first output
// the top part while the second output the bottom part).
// - The interesting thing is if you look at the structure of the ifft algorithm with butterfly, you can observe that the next stage
// can start with each part separately. This means that the top part can be used as a whole complete sequence of input data for the
// next stage without care about the bottom part. For example, when you compute the output of the first stage, you have 2 parts:
// 2048 ouput top part and 2048 output bottom part. Right now, look at the DIF FFT design anywhere you find on the GG (recommend
// 8-point FFT figures: https://www.researchgate.net/publication/299520102/figure/fig8/AS:667881138315270@1536246680870/point-radix-2-DIF-FFT.png), 
// do you notice that the top and bottom parts are connected to 2 2nd stage designs? That's what I mean, after you compute the
// top part of output you can start immediately the 2nd stage.
// - Based on the working operation above, here is the step-by-step operation (take example for the first stage, data comes 1-by-1
// every cycle, not all at one!!!)
// * Step 1: - Store input data index 0th to 2047th (2048 input data) into a bram called "imem"
// * Step 2: - Since input data index 2048th to 4095th, every cycle take the input data with the element in order in imem to compute
//           2 OUTPUTS (top and bottom parts)
// * Step 3: - Only send out 1 output at a time --> sending only the top part, while storing the bottom part to a bram called "omem"
// * Step 4: - After sending enough 2048 output top part, simultaneously the bram omem also stores enough 2048 output bottom part.
//           Therefore, start sending out 2048 bottom output part
// NOTE: You do not need to worry about the conflict at step 4. At this step, step 1 also starts working to store new 2048 input of the
// next 4096 input sequence you want to calculate. As a result, the new data for the new sequence can not be calculated in this time
// since there are not enough new data to calculate. This means, there will not be any new data at step 4, so you do not need to worry
// about the conflict of sending new data or the stored bottom part data in the omem bram. New data does not exist at this step!!!
// ---------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////

import fft_pkg::*;

module ifft_stage #(
    parameter   SIZE = FFT_SIZE                     // parameter in pkg can not be redefined --> use a different name "SIZE"
    // parameter   BITSHIFT = 0
)
(
// ######################## port declaration ########################
    input   logic                       clk,
    input   logic                       rst_n,
    
    input   logic   [TW_D_WIDTH*2-1:0]     twiddle_factor      [0:SIZE/2-1],

    // interface with modport
    input   logic                       i_vld,
    input   data_t                      i_data,

    `ifdef ADDITION
    input   logic                       i_sync_rst,
    `endif
    
    output  logic                       o_vld,
    output  data_t                      o_data
// ##################################################################
);

    localparam  FFT_WIDTH = $clog2(SIZE);
    logic   o_sync;
// ################## internal signal declarations ##################
    // ----- counter for read and write into mem -----
    // use 1 extra bit for further processes (use to distinguish between writing or reading data from bram)
    logic   [FFT_WIDTH-1:0] imem_addr;          // - address to write/read data to/from bram imem 
    logic   [FFT_WIDTH-1:0] omem_addr;          // - address to write/read data to/from bram omem
    logic   [FFT_WIDTH-1:0] nxt_omem_addr;      // - two steps ahead... :D the bottom part is stored in the bram and data can not be read out in 1 cycle, so we need to 
                                                // read data out two steps ahead to synchronize the output

    // ----- valid for mem -----
    logic   imem_en;                            // - when to enable writing to imem bram
    logic   omem_en;                            // - when to enable writing to omem bram

    // ----- data in bram -----
    data_t  omem_i_data;                        // - data in omem bram

    // ----- data out from bram -----
    data_t  o_imem;                             // - data out from imem
    data_t  omem;                               // - data out from omem

    // ----- temporary variables -----
    logic   [FFT_WIDTH-1:0] imem_addr_tmp;      // - just a temp variable for precalculate imem_addr register

    // ----- data for multiplication -----
    // Pipeline stage 1
    data_t                  mult_pipe_1;        // pipelined stage 1: delay 1 cycle the i_data to wait for data from bram
    logic                   vld_pipe_1;         // pipelined valid signal
    logic   [FFT_WIDTH-2:0] address_pipe_1;     // pipelined address to use as index to retrieve the corresponding twiddle factor
    logic                   ib_sync_pipe_1;     // pipelined sync signal for o_sync

    // Pipeline stage 2
    logic   signed  [D_WIDTH-1:0]   mult_pipe_2_re_add; // pipelined stage 2: computing addition/subtraction and store real/imaginary in separate parts
    logic   signed  [D_WIDTH-1:0]   mult_pipe_2_re_sub;
    logic   signed  [D_WIDTH-1:0]   mult_pipe_2_im_add;
    logic   signed  [D_WIDTH-1:0]   mult_pipe_2_im_sub;
    logic                   vld_pipe_2;                     // similar to stage 1
    logic   [FFT_WIDTH-2:0] address_pipe_2;                 // similar to stage 1
    logic                   ib_sync_pipe_2;                 // similar to stage 1

    // Pipeline stage 3: multiply for twiddle factor (bottom part)
    logic   signed  [D_WIDTH-1:0]   mult_pipe_3_re_0;       // Wr x (x0r - x1r)
    logic   signed  [D_WIDTH-1:0]   mult_pipe_3_re_1;       // Wi x (x0i - x1i)
    logic   signed  [D_WIDTH-1:0]   mult_pipe_3_im_0;       // Wr x (x0i - x1i)
    logic   signed  [D_WIDTH-1:0]   mult_pipe_3_im_1;       // Wi x (x0r - x1r)
    logic   signed  [D_WIDTH-1:0]   mult_pipe_3_re_add;     // delayed version of mult_pipe_2_re_add for synchronization (top part)
    logic   signed  [D_WIDTH-1:0]   mult_pipe_3_im_add;     // delayed version of mult_pipe_2_im_add for synchronization (top part)    

    logic                           vld_pipe_3;             // similar to stage 1
    logic                           ib_sync_pipe_3;         // similar to stage 1

    // Pipeline stage 4: do subtraction between the mult_pipe_3_re and mult_pipe_3_im (bottom part)
    logic   signed  [D_WIDTH-1:0]   mult_pipe_4_re_0;       // x0r + x1r
    logic   signed  [D_WIDTH-1:0]   mult_pipe_4_re_1;       // Wr x (x0r - x1r) - Wi x (x0i - x1i)
    logic   signed  [D_WIDTH-1:0]   mult_pipe_4_im_0;       // x0i + x1i
    logic   signed  [D_WIDTH-1:0]   mult_pipe_4_im_1;       // Wr x (x0i - x1i) - Wi x (x0r - x1r)
    logic                           vld_pipe_4;             // similar to stage 1
    logic                           ib_sync_pipe_4;         // similar to stage 1

    // ----- Other uses -----
    logic   sync_on;                                        // used to control valid
    logic   iaddr_en;
    logic   b_started_tmp;                                  // used to control increasing value of address
    logic   omem_addr_en;
    logic   en_pipe_1;
    logic   ib_sync_tmp;
    logic   signed  [D_WIDTH-1:0]   re_tmp_0;
    logic   signed  [D_WIDTH-1:0]   re_tmp_1;
    logic   signed  [D_WIDTH-1:0]   im_tmp_0;
    logic   signed  [D_WIDTH-1:0]   im_tmp_1;
    logic   signed  [TW_D_WIDTH-1:0]   twiddle_re_tmp;
    logic   signed  [TW_D_WIDTH-1:0]   twiddle_im_tmp;
    logic   signed  [2*D_WIDTH-1:0] mult_re_0_ori;
    logic   signed  [D_WIDTH-1:0]   mult_re_0_shift;
    logic   signed  [2*D_WIDTH-1:0] mult_re_1_ori;
    logic   signed  [D_WIDTH-1:0]   mult_re_1_shift;
    logic   signed  [2*D_WIDTH-1:0] mult_im_0_ori;
    logic   signed  [D_WIDTH-1:0]   mult_im_0_shift;
    logic   signed  [2*D_WIDTH-1:0] mult_im_1_ori;
    logic   signed  [D_WIDTH-1:0]   mult_im_1_shift;
    `ifdef NON_SCALE
        logic   signed  [D_WIDTH-1:0]   test_sub;
        logic   signed  [D_WIDTH-1:0]   test_add;
    `else
        logic   signed  [D_WIDTH:0]     test_sub;
        logic   signed  [D_WIDTH:0]     test_add;
    `endif
    data_t  data_pipe_4;
    logic   sync_on_tmp;                            
    logic   vld_bram;                                       // valid bram indicates when output from omem bram is valid
// ##################################################################



// ####################### bram instantiation #######################
    // whenever the extra MSB bit of addr is 0 --> store data into bram
    // ----- imem bram -----
    // - Description:   + imem bram used for storing the first half input data
    //                  + the MSB bit of imem_addr will decide when to write data in or read data out
    //                  + data will be written in when MSB is 0 and simultaneously i_vld is asserted (check imem_en signal right below)
    assign  imem_en = i_vld & (~imem_addr[FFT_WIDTH-1]);

    ifft_bram #(.SIZE(SIZE)) i_mem (
        .clk        (clk),
        .i_wraddr   (imem_addr[FFT_WIDTH-2:0]),     // dont take the MSB bit because it is for management purpose only
        .i_rdaddr   (imem_addr[FFT_WIDTH-2:0]),     // dont take the MSB bit because it is for management purpose only
        
        .i_data     (i_data),
        .i_en       (imem_en),

        .o_data     (o_imem)
    );

    // ----- omem bram -----
    // - Description:   + omem bram used for storing the second half output data (the bottom part)
    //                  + data will be written to omem whenver the ifft stage produces a new pair of output
    // whenever producing valid outputs --> write the bottom part to bram omem --> enable when valid is asserted
    assign  omem_en = vld_pipe_4;
    
    // store the bottom part of output to bram
    assign  omem_i_data.data_re = mult_pipe_4_re_1;
    assign  omem_i_data.data_im = mult_pipe_4_im_1;

    ifft_bram #(.SIZE(SIZE)) o_mem (
        .clk        (clk),
        .i_wraddr   (omem_addr[FFT_WIDTH-2:0]),
        .i_rdaddr   (nxt_omem_addr[FFT_WIDTH-2:0]),
        
        .i_data     (omem_i_data),
        .i_en       (omem_en),

        .o_data     (omem)
    );
// ##################################################################



// ######################## process counters ########################
    // ----- Process imem_addr -----
    // - Description:   + process increasing the value of imem_addr
    //                  + imem address increases when there is a data coming in
    assign  iaddr_en = i_vld;
    assign  imem_addr_tmp = (iaddr_en) ? (imem_addr + 1'b1) : (imem_addr);
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            imem_addr <= {FFT_WIDTH{1'b0}};
        end
        else begin
            if(i_sync_rst) begin
                imem_addr <= 'b0;
            end
            else begin
                imem_addr <= imem_addr_tmp; 
            end
        end
    end

    // ----- Process omem_addr -----
    // - Description:   + process increasing the value of omem_addr
    //                  + omem address increases when the ifft stage produces a new pair of output
    //                    or there is an available output ready to be sent out from omem bram
    assign  omem_addr_en = ib_sync_pipe_4 || (b_started_tmp);
    assign  b_started_tmp = sync_on_tmp;
    logic   [FFT_WIDTH-1:0] omem_addr_tmp;
    assign  omem_addr_tmp = (omem_addr_en) ? omem_addr + 1'b1 : omem_addr;
    logic   o_sync_tmp;
    assign  o_sync_tmp = (~omem_addr[FFT_WIDTH-1]) ? ib_sync_pipe_3 : 1'b0;
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            omem_addr <= {FFT_WIDTH{1'b0}};
            o_sync <= 1'b0;
        end
        else begin
            if(i_sync_rst) begin
                o_sync <= 'b0;
                omem_addr <= 'b0;
            end
            else begin
                o_sync <= o_sync_tmp;
                omem_addr <= omem_addr_tmp;
            end
        end
    end
// ##################################################################



// ####################### Output computation #######################
    // - Description:   After collecting the first half input data, computing the output with 4 pipelined stages
    //                  + Stage 1: delay the input (since input index 2048 to 4095) by 1 cycle to wait for valid data out from bram 
    //                             (remember bram needs 1 cycle to send out valid data)
    //                  + Stage 2: compute addition and subtraction between 2 complex numbers (the input index 2048 and the stored data index 0 in bram imem)
    //                             resulting in 4 signals (real and imaginary parts for addition and subtraction)
    //                  + Stage 3: compute multiplication with twiddle factors
    //                  + Stage 4: compute addition and subtraction (see below for more detailed information, I've commented already the formula)
    // Cycle 0: i_vld asserts --> data out from bram is valid at cycle 1. Therefore, we delay the data in 1 cycle to wait (pipelined stage 1)
    // Cycle 1: data out from bram is valid --> take the delayed version of i_data from prev cycle to do the addition/subtraction (pipelined stage 2)
    // Cycle 2: multiply the result of operations in previous cycle with the twiddle factors and delay the addition for 1 cycle for synchronization (pipelined stage 3)
    // Cycle 3: the result is latched out

    // ----- Pipelined stage 1: delay the i_data for 1 cycle to wait for imem -----
    assign  en_pipe_1 = i_vld & (imem_addr[FFT_WIDTH-1]);   // enable starting pipelined stage 1
    assign  ib_sync_tmp = (i_vld & (imem_addr[FFT_WIDTH-1] & (~(|imem_addr[FFT_WIDTH-2:0]))));  // if (i_vld && (imem_addr == 1<<(FFT_WIDTH-1)))
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            vld_pipe_1 <= 1'b0;
            ib_sync_pipe_1 <= 1'b0;
        end
        else begin
            if(i_sync_rst) begin
                vld_pipe_1 <= 'b0;
                ib_sync_pipe_1 <= 'b0;
            end
            else begin
                vld_pipe_1 <= en_pipe_1;
                ib_sync_pipe_1 <= ib_sync_tmp;
            end

            if(en_pipe_1) begin
                mult_pipe_1 <= i_data;
                address_pipe_1 <= imem_addr[FFT_WIDTH-2:0];
            end
        end
    end

    // ----- Pipelined stage 2: compute the addition/subtraction of bram_mem and delayed version of i_data -----
    assign  re_tmp_0 = o_imem.data_re;
    assign  re_tmp_1 = mult_pipe_1.data_re;

    assign  im_tmp_0 = o_imem.data_im;
    assign  im_tmp_1 = mult_pipe_1.data_im;

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            vld_pipe_2 <= 1'b0;
            ib_sync_pipe_2 <= 1'b0;
        end
        else begin
            if(i_sync_rst) begin
                vld_pipe_2 <= 'b0;
                ib_sync_pipe_2 <= 'b0;
            end
            else begin
                vld_pipe_2 <= vld_pipe_1;
                ib_sync_pipe_2 <= ib_sync_pipe_1;
            end

            // ----- x0r + x1r -----
            mult_pipe_2_re_add <= re_tmp_0 + re_tmp_1;
            // ----- x0r - x1r -----
            mult_pipe_2_re_sub <= re_tmp_0 - re_tmp_1;
            // ----- x0i + x1i -----
            mult_pipe_2_im_add <= im_tmp_0 + im_tmp_1;
            // ----- x0i - x1i -----
            mult_pipe_2_im_sub <= im_tmp_0 - im_tmp_1;
        
            address_pipe_2 <= address_pipe_1;
        end
    end

    // ----- Pipelined stage 3: compute the multiplication of twiddle factor for bottom part -----
    assign  twiddle_re_tmp = (twiddle_factor[address_pipe_2][TW_D_WIDTH*2-1:TW_D_WIDTH]);
    assign  twiddle_im_tmp = (twiddle_factor[address_pipe_2][TW_D_WIDTH-1:0]);


    // ----- Wr x (x0r - x1r) -----
    assign  mult_re_0_ori = twiddle_re_tmp * mult_pipe_2_re_sub;
    assign  mult_re_0_shift = mult_re_0_ori >>> FRAC_BIT;

    // ----- Wr x (x0i - x1i) -----
    assign  mult_re_1_ori = twiddle_re_tmp * mult_pipe_2_im_sub;
    assign  mult_re_1_shift = mult_re_1_ori >>> FRAC_BIT;

    // ----- Wi x (x0i - x1i) -----
    assign  mult_im_0_ori = twiddle_im_tmp * mult_pipe_2_im_sub;
    assign  mult_im_0_shift = mult_im_0_ori >>> FRAC_BIT;

    // ----- Wi x (x0r - x1r) -----
    assign  mult_im_1_ori = twiddle_im_tmp * mult_pipe_2_re_sub;
    assign  mult_im_1_shift = mult_im_1_ori >>> FRAC_BIT;

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            vld_pipe_3 <= 1'b0;
            ib_sync_pipe_3 <= 1'b0;
        end
        else begin
            if(i_sync_rst) begin
                vld_pipe_3          <= 'b0;
                ib_sync_pipe_3      <= 'b0;
            end
            else begin
                vld_pipe_3          <= vld_pipe_2;
                ib_sync_pipe_3      <= ib_sync_pipe_2;
            end

            // ----- Wr x (x0r - x1r) -----
            mult_pipe_3_re_0    <= mult_re_0_shift;

            // ----- Wr x (x0i - x1i) -----
            mult_pipe_3_re_1    <= mult_re_1_shift;
    
            // ----- Wi x (x0i - x1i) -----
            mult_pipe_3_im_0    <= mult_im_0_shift;

            // ----- Wi x (x0r - x1r) -----
            mult_pipe_3_im_1    <= mult_im_1_shift;
    
            mult_pipe_3_re_add  <= mult_pipe_2_re_add;
            mult_pipe_3_im_add  <= mult_pipe_2_im_add;
        end
    end

    // ----- Pipelined stage 4: compute the subtraction/addition for output -----
    assign  test_sub = (mult_pipe_3_re_0 - mult_pipe_3_im_0);
    assign  test_add = (mult_pipe_3_re_1 + mult_pipe_3_im_1);

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            vld_pipe_4 <= 1'b0;
            ib_sync_pipe_4 <= 1'b0;
        end
        else begin
            if(i_sync_rst) begin
                vld_pipe_4 <= 'b0;
                ib_sync_pipe_4 <= 'b0;
            end
            else begin
                vld_pipe_4 <= vld_pipe_3;
                ib_sync_pipe_4 <= ib_sync_pipe_3;
            end

            `ifdef NON_SCALE
                // ----- y0r <= x0r + x1r -----
                mult_pipe_4_re_0 <= (mult_pipe_3_re_add >>> 1);
        
                // ----- yoi <= x0i + x1i -----
                mult_pipe_4_im_0 <= (mult_pipe_3_im_add >>> 1);
        
                // ----- y1r <= Wr x (x0r - x1r) - Wi x (x0i - x1i) -----
                mult_pipe_4_re_1 <= (test_sub >>> 1);
        
                // ----- y0r <= Wr x (x0i - x1i) - Wi x (x0r - x1r) -----
                mult_pipe_4_im_1 <= (test_add >>> 1);
            `else
                // ----- y0r <= x0r + x1r -----
                mult_pipe_4_re_0 <= (mult_pipe_3_re_add);
        
                // ----- yoi <= x0i + x1i -----
                mult_pipe_4_im_0 <= (mult_pipe_3_im_add);
        
                // ----- y1r <= Wr x (x0r - x1r) - Wi x (x0i - x1i) -----
                mult_pipe_4_re_1 <= (test_sub);
        
                // ----- y0r <= Wr x (x0i - x1i) - Wi x (x0r - x1r) -----
                mult_pipe_4_im_1 <= (test_add);
            `endif
        end
    end

    // ----- assign temporary o_data -----
    assign  data_pipe_4.data_re = mult_pipe_4_re_0;
    assign  data_pipe_4.data_im = mult_pipe_4_im_0;

    // ----- two steps ahead -----
    always_ff @(posedge clk) begin
        nxt_omem_addr[0] <= omem_addr[0];
        nxt_omem_addr[FFT_WIDTH-1:1] <= omem_addr[FFT_WIDTH-1:1] + 1'b1;
    end

    // ----- process sync on -----
    assign  sync_on_tmp = (sync_on) ? o_vld : o_sync;
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            sync_on <= 1'b0;
        end
        else begin
            if(i_sync_rst) begin
                sync_on <= 'b0;
            end
            else begin
                sync_on <= sync_on_tmp;
            end
        end
    end

    // process vld_bram, o_vld and o_data
    assign  vld_bram = (sync_on ? ~vld_pipe_4 : 1'b0);
    assign  o_vld = (omem_addr[FFT_WIDTH-1]) ? vld_bram : vld_pipe_4;   // when the MSB of omem_addr turns to 1 -> use output from bram omem, else use directly from the computed results
    assign  o_data = (omem_addr[FFT_WIDTH-1]) ? omem : data_pipe_4;

// ##################################################################
endmodule