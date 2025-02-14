// `timescale 1ns / 1ps
// //////////////////////////////////////////////////////////////////////////////////
// // Create Date: 10th January 2025 02:37:03 PM
// // Design Name: Fast Fourier Transform
// // Module Name: fft_laststage
// // Project Name: Software-defined Radio Global Positioning System FPGA-based Design
// // Target Devices: UltraScale 96 v2.0
// // Tool Versions: 
// // Description: This design is a submodule to implement the last stage due to its special characteristics. 
// //              We can compute this stage without using any multiplication so it and the prelast stage will 
// //              be designed separately from other stages.
// // 
// // Dependencies: 
// // 
// // Revision:
// // Revision 0.01 - File Created
// // Additional Comments:
// // 
// //////////////////////////////////////////////////////////////////////////////////

// import fft_pkg::*;

// module fft_laststage (
// // ######################## port declaration ########################
//     input   logic                       clk,
//     input   logic                       rst_n,

//     // interface with modport
//     input   logic                       i_vld,
//     input   data_t                      i_data,
//     // input   logic                       i_sync,

//     output  logic                       o_vld,
//     output  data_t                      o_data
//     // output  logic                       o_sync
// // ##################################################################
// );
//     // ----- internal signal declaration -----
//     // - Description:   + imem and omem are flops to store half first input and half second output, respectively (similar to other stages)
//     //                  + data_avail indicate there is available data ready to be used to compute the output together with the new input coming in
//     //                  + en_pipe_1 and en_pipe_2 is pipelined stages enable signals
//     //                  + vld is pipelined valid signal
//     data_t  imem;
//     data_t  omem;
//     logic   data_avail;
//     logic   en_pipe_1;
//     logic   en_pipe_2;
//     logic   vld;
//     logic   sync;
//     logic   [11:0]  counter;

//     // ----- process data_avail and vld in imem -----
//     // - Description:   + the last stage needs 2 inputs to compute a new pair of outputs (see the structure of final stage FFT to clarify this statement),
//     //                    so the working operation is to receive the first input, write it to a register to store it, then wait for the next cycle to receive
//     //                    the second input and compute a new pair of output.
//     //                  + data_avail is responsible for indicating whether the input is to be stored in the register and wait for the next input coming to compute
//     //                    the output or the input is the second input and can be used with the stored input in the register to compute output
//     always_ff @(posedge clk, negedge rst_n) begin
//         if(~rst_n) begin
//             data_avail <= 1'b0;
//             vld<=1'b0;
//         end
//         else begin
//             vld <= i_vld;
//             sync <= ((~(|counter[11:0])) & i_vld);

//             if(i_vld) begin
//                 data_avail <= ~data_avail;
//             end
//         end
//     end

//     // ----- process storing data in imem -----
//     // - Description:   + if data_avail is not asserted, it means there has not any data being stored in imem yet, so we can
//     //                    store the current data input to the register to wait for the next data coming to compute the output
//     assign  en_pipe_1 = i_vld & (~data_avail);
//     always_ff @(posedge clk) begin
//         if(en_pipe_1) begin
//             imem <= i_data;
//         end
//     end
    
//     // ----- process storing data in omem -----
//     // - Description:   + if data_avail is asserted, it means there has already been a data in register to be ready for computation,
//     //                    so we will not let the current input to be stored in imem. Instead, the current input will be used with the
//     //                    data being stored in imem to compute the output
//     //                  + the bottom part of the last stage is really simple, just take the subtraction between the first and second input
//     //                    (see the data_re_bottom and data_im_bottom signals)
//     //                  + the top part of the last stage is also simple, just take the addition between the first and second input
//     //                    (see the data_re_top and data_im_top signals)
    
//     // Compute bottom part and store in omem
//     assign  en_pipe_2 = i_vld & (data_avail);
//     `ifdef NON_SCALE
//         logic   signed  [D_WIDTH-1:0]   data_re_bottom;
//         logic   signed  [D_WIDTH-1:0]   data_im_bottom;
//     `else
//         logic   signed  [D_WIDTH:0]     data_re_bottom;
//         logic   signed  [D_WIDTH:0]     data_im_bottom;
//     `endif

//     assign  data_re_bottom = imem.data_re - i_data.data_re;
//     assign  data_im_bottom = imem.data_im - i_data.data_im;
//     always_ff @(posedge clk) begin
//         if(en_pipe_2) begin
//             `ifdef NON_SCALE
//                 // if non scale --> keep orignal result
//                 omem.data_re <= (data_re_bottom);
//                 omem.data_im <= (data_im_bottom);
//             `else
//                 // if scale --> right shift 1 to divide by 2
//                 omem.data_re <= (data_re_bottom >>> 1);
//                 omem.data_im <= (data_im_bottom >>> 1);
//             `endif
//         end
//     end

//     // Compute top part and assigning output
//     `ifdef NON_SCALE
//         logic   signed  [D_WIDTH-1:0]   data_re_top;
//         logic   signed  [D_WIDTH-1:0]   data_im_top;
//     `else
//         logic   signed  [D_WIDTH:0]     data_re_top;
//         logic   signed  [D_WIDTH:0]     data_im_top;
//     `endif

//     assign  data_re_top = imem.data_re + i_data.data_re;
//     assign  data_im_top = imem.data_im + i_data.data_im;
//     always_comb begin
//         if(data_avail) begin
//             if(i_vld) begin
//                 `ifdef NON_SCALE
//                     o_data.data_re = (data_re_top);
//                     o_data.data_im = (data_im_top);
//                 `else
//                     o_data.data_re = (data_re_top >>> 1);
//                     o_data.data_im = (data_im_top >>> 1);
//                 `endif
//             end
//             else begin
//                 o_data = imem;
//             end
//         end
//         else begin
//             o_data = omem;
//         end
//     end

//     // ----- counter process -----
//     always_ff @(posedge clk, negedge rst_n) begin
//         if(~rst_n) begin
//             counter <= 1'b0;
//         end
//         else begin
//             if(i_vld) begin
//                 counter <= counter + 1'b1;
//             end
//         end
//     end

//     // ----- valid signal assignment -----
//     assign o_vld = vld;
//     // assign o_sync = sync;

// endmodule


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 10th January 2025 02:37:03 PM
// Design Name: Fast Fourier Transform
// Module Name: fft_laststage
// Project Name: Software-defined Radio Global Positioning System FPGA-based Design
// Target Devices: UltraScale 96 v2.0
// Tool Versions: 
// Description: This design is a submodule to implement the last stage due to its special characteristics. 
//              We can compute this stage without using any multiplication so it and the prelast stage will 
//              be designed separately from other stages.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// import ifft_pkg::*;
import fft_pkg::*;

module ifft_laststage (
// ######################## port declaration ########################
    input   logic                       clk,
    input   logic                       rst_n,

    // interface with modport
    input   logic                       i_vld,
    input   data_t                      i_data,
    `ifdef ADDITION
    input   logic                       i_sync_rst,
    `endif
    // input   logic                       i_sync,

    output  logic                       o_vld,
    output  data_t                      o_data
    // output  logic                       o_sync
// ##################################################################
);
    // ----- internal signal declaration -----
    // - Description:   + imem and omem are flops to store half first input and half second output, respectively (similar to other stages)
    //                  + data_avail indicate there is available data ready to be used to compute the output together with the new input coming in
    //                  + en_pipe_1 and en_pipe_2 is pipelined stages enable signals
    //                  + vld is pipelined valid signal
    data_t  imem;
    data_t  omem;
    logic   data_avail;
    logic   en_pipe_1;
    logic   en_pipe_2;
    logic   vld_pipe_1;
    logic   vld_pipe_2;
    // logic   sync;
    // logic   [11:0]  counter;

    // ----- process data_avail and vld in imem -----
    // - Description:   + the last stage needs 2 inputs to compute a new pair of outputs (see the structure of final stage FFT to clarify this statement),
    //                    so the working operation is to receive the first input, write it to a register to store it, then wait for the next cycle to receive
    //                    the second input and compute a new pair of output.
    //                  + data_avail is responsible for indicating whether the input is to be stored in the register and wait for the next input coming to compute
    //                    the output or the input is the second input and can be used with the stored input in the register to compute output
    logic   data_avail_tmp;
    assign  data_avail_tmp = (i_vld) ? ~data_avail : data_avail;
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            data_avail <= 1'b0;
            vld_pipe_1 <= 1'b0;
            vld_pipe_2 <= 1'b0;
        end
        else begin
            if(i_sync_rst) begin
                vld_pipe_1 <= 'b0;
                vld_pipe_2 <= 'b0;
                data_avail <= 'b0;
            end
            else begin
                vld_pipe_1 <= i_vld;
                vld_pipe_2 <= vld_pipe_1;
                data_avail <= data_avail_tmp;
            end
            // sync <= ((~(|counter[11:0])) & i_vld);

            // if(i_vld) begin
            //     data_avail <= ~data_avail;
            // end
        end
    end

    // ----- process storing data in imem -----
    // - Description:   + if data_avail is not asserted, it means there has not any data being stored in imem yet, so we can
    //                    store the current data input to the register to wait for the next data coming to compute the output
    assign  en_pipe_1 = i_vld & (~data_avail);
    always_ff @(posedge clk) begin
        if(en_pipe_1) begin
            imem <= i_data;
        end
    end
    
    // ----- process storing data in omem -----
    // - Description:   + if data_avail is asserted, it means there has already been a data in register to be ready for computation,
    //                    so we will not let the current input to be stored in imem. Instead, the current input will be used with the
    //                    data being stored in imem to compute the output
    //                  + the bottom part of the last stage is really simple, just take the subtraction between the first and second input
    //                    (see the data_re_bottom and data_im_bottom signals)
    //                  + the top part of the last stage is also simple, just take the addition between the first and second input
    //                    (see the data_re_top and data_im_top signals)
    
    // Compute bottom part and store in omem
    assign  en_pipe_2 = i_vld & (data_avail);
    `ifdef NON_SCALE
        logic   signed  [D_WIDTH-1:0]   data_re_bottom;
        logic   signed  [D_WIDTH-1:0]   data_im_bottom;
    `else
        logic   signed  [D_WIDTH:0]     data_re_bottom;
        logic   signed  [D_WIDTH:0]     data_im_bottom;
    `endif

    assign  data_re_bottom = imem.data_re - i_data.data_re;
    assign  data_im_bottom = imem.data_im - i_data.data_im;
    always_ff @(posedge clk) begin
        if(en_pipe_2) begin
            `ifdef NON_SCALE
                // if non scale --> keep orignal result
                omem.data_re <= (data_re_bottom);
                omem.data_im <= (data_im_bottom);
            `else
                // if scale --> right shift 1 to divide by 2
                // omem.data_re <= (data_re_bottom >>> 1);
                // omem.data_im <= (data_im_bottom >>> 1);
                omem.data_re <= (data_re_bottom);
                omem.data_im <= (data_im_bottom);
            `endif
        end
    end

    // Compute top part and assigning output
    `ifdef NON_SCALE
        logic   signed  [D_WIDTH-1:0]   data_re_top;
        logic   signed  [D_WIDTH-1:0]   data_im_top;
    `else
        logic   signed  [D_WIDTH:0]     data_re_top;
        logic   signed  [D_WIDTH:0]     data_im_top;
    `endif

    assign  data_re_top = imem.data_re + i_data.data_re;
    assign  data_im_top = imem.data_im + i_data.data_im;
    // always_comb begin
    //     if(data_avail) begin
    //         if(i_vld) begin
    //             `ifdef NON_SCALE
    //                 o_data.data_re = (data_re_top);
    //                 o_data.data_im = (data_im_top);
    //             `else
    //                 o_data.data_re = (data_re_top >>> 1);
    //                 o_data.data_im = (data_im_top >>> 1);
    //             `endif
    //         end
    //         else begin
    //             o_data = imem;
    //         end
    //     end
    //     else begin
    //         o_data = omem;
    //     end
    // end
    always_ff @(posedge clk) begin
        if(data_avail) begin
            `ifdef NON_SCALE
                o_data.data_re <= (data_re_top);
                o_data.data_im <= (data_im_top);
            `else
                // o_data.data_re <= (data_re_top >>> 1);
                // o_data.data_im <= (data_im_top >>> 1);
                o_data.data_re <= (data_re_top);
                o_data.data_im <= (data_im_top);
            `endif
        end
        else begin
            o_data <= omem;
        end
    end

    // ----- counter process -----
    // always_ff @(posedge clk, negedge rst_n) begin
    //     if(~rst_n) begin
    //         counter <= 1'b0;
    //     end
    //     else begin
    //         if(i_vld) begin
    //             counter <= counter + 1'b1;
    //         end
    //     end
    // end

    // ----- valid signal assignment -----
    assign o_vld = vld_pipe_2;
    // assign o_sync = sync;

endmodule
