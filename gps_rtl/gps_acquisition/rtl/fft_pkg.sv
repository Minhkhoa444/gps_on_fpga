// Very first version:  + Data is in Q15.30 binary representation throughout all stages of the system
//                      + To run this very first version (already tested), uncomment NON_SCALE and Q15_30
//                      + This version does not support bit-reverse the output so please uncomment also VERIFICATION to see the reordered data in a bram

// If you choose to scale the output, uncomment NON_SCALE and the output at each stage will be right shifted 1 before being sent out
// but this may not be so precise, until now it is acceptable with Q15.30 binary representation but with lower bit representation, this
// will not ensure

// - To test Q2.14 NON_SCALE (data will not be shifted, the final output will be the raw data, not scaled yet!):
//   + Uncomment NON_SCALE and Q214 (input data is represented as Q14.14: 16 bits for Q2.14 original data, 12 more guard bits for overflow handling)
//   + Comment other macros
//
// - To test Q2.14 SCALE (the result after each stage will be right shifted for 1 bit, the final result will approximate the NON_SCALE version divided by 2^12)
//   + Only uncomment Q214 (input data is represented as Q3.14: 16 bits for original data, 1 more guard bit for overflow handling)
//   + Comment other macros
//
// - To test Q15.30 NON_SCALE: uncomment NON_SCALE and Q1530 (this Q1530 is the original version so just keep it here for memory, not be used in future. 
//   It has a very high precision but bad in resource consumption - DSP48)
//
// - To test Q15.30 SCALE: uncomment Q1530 only (this Q1530 is the original version so just keep it here for memory, not be used in future. 
//   It has a very high precision but bad in resource consumption - DSP48)
//
// - This design does not include bit-reverse in the result. I only created a bram and store the output data in its correct order to
//   easily keep track and debug. Therefore, if you want to make the Verification easier, uncomment VERIFICATION to infer a BRAM storing
//   in-order output data inside the top module. If you uncomment this, the design will not be affected. This is for verification purpose only!


`define NON_SCALE
`define Q215
`define ADDITION
`define OPTIMIZE
`define WRAPPER_SV
// `define IFFT_VERIFICATION
// `define SOFT_MULT

package fft_pkg;
    parameter FFT_SIZE = 4096;
    parameter   DAT_WIDTH = 16;

    `ifdef Q215
        `ifdef  NON_SCALE
            parameter D_WIDTH = 28;
        `else
            parameter D_WIDTH = 17;
        `endif
        parameter IFFT_D_WIDTH = 28;
        parameter FRAC_BIT = 15;
        parameter TW_D_WIDTH = 16;
    `endif

    typedef struct packed {
        logic   signed  [D_WIDTH-1:0]   data_re;
        logic   signed  [D_WIDTH-1:0]   data_im;
    } data_t;

    typedef struct packed {
        logic   signed  [IFFT_D_WIDTH-1:0]   data_re;
        logic   signed  [IFFT_D_WIDTH-1:0]   data_im;
    } ifft_data_t;

    typedef struct packed {
        logic   signed  [15:0]   data_re;
        logic   signed  [15:0]   data_im;
    } bitreverse_data_t;

    typedef struct packed {
        logic   signed  [D_WIDTH-1:0]   max_diff_current;
        logic           [11:0]          max_diff_id;
    } rec_diff;

    typedef struct packed {
        logic   signed  [D_WIDTH-1:0]   max_diff_all;
        logic   signed  [D_WIDTH-1:0]   max_diff_all_id;
        logic           [4:0]           max_diff_all_sat;
    } rec_max_diff;

    typedef struct packed {
        logic   signed  [DAT_WIDTH-1:0] gps_i;
        logic   signed  [DAT_WIDTH-1:0] gps_q;
    } dat_gps_t;
endpackage

interface fft_data_if #(parameter D_WIDTH = 32);
    typedef struct packed {
        logic   signed  [D_WIDTH-1:0]   data_re;
        logic   signed  [D_WIDTH-1:0]   data_im;
    } data_t;
endinterface
