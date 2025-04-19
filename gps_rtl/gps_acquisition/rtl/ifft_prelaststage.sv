`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 11th January 2025 08:36:18 AM
// Design Name: Fast Fourier Transform
// Module Name: ifft_prelaststage
// Project Name: Software-defined Radio Global Positioning System FPGA-based Design
// Target Devices: UltraScale 96 v2.0
// Tool Versions: 
// Description: This design is a submodule to implement the stage right before the last stage due to its special characteristics.
//              We can compute this stage without using any multiplication so it and the last stage will be designed separately 
//              from other stages.
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

module ifft_prelaststage(
// ######################## port declaration ########################
    input   logic                       clk,
    input   logic                       rst_n,

    // interface with modport
    input   logic                       i_vld,
    input   ifft_data_t                      i_data,

    `ifndef OPTIMIZE
    input   logic                       i_sync_rst,
    `endif
    
    output  logic                       o_vld,
    output  ifft_data_t                      o_data
// ##################################################################
);

    ifft_data_t  i_mem_pipe  [0:1];          // 2 entry bram input
    ifft_data_t  o_mem_pipe  [0:1];          // 2 entry bram output
    logic   [1:0]       addr;           // addr to read/write data

    logic   vld_pipe_1;                 // pipelined vld
    logic   vld_pipe_2;                 // pipelined vld
    logic   vld_pipe_3;                 // pipelined vld

    // ----- vld processing -----
    always_ff @(posedge clk, negedge rst_n) begin 
        if(~rst_n) begin
            vld_pipe_1 <= 'b0;
            vld_pipe_2 <= 'b0;
            vld_pipe_3 <= 'b0;
        end
        else begin
            `ifndef OPTIMIZE
                if(i_sync_rst) begin
                    vld_pipe_1 <= 'b0;
                    vld_pipe_2 <= 'b0;
                    vld_pipe_3 <= 'b0;
                end
                else begin
                    vld_pipe_1 <= i_vld;
                    vld_pipe_2 <= vld_pipe_1;
                    vld_pipe_3 <= vld_pipe_2;
                end
            `else
                vld_pipe_1 <= i_vld;
                vld_pipe_2 <= vld_pipe_1;
                vld_pipe_3 <= vld_pipe_2;
            `endif
        end
    end

    // ----- addr process -----
    logic   [1:0]   addr_tmp;
    assign  addr_tmp = (i_vld) ? addr + 1'b1 : addr;
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            addr <= 'b0;
        end
        else begin
            `ifndef OPTIMIZE
                if(i_sync_rst) begin
                    addr <= 'b0;
                end
                else begin
                    addr <= addr_tmp;
                end
            `else
                addr <= addr_tmp;
            `endif
        end
    end

    // ----- mem pipe pipeline stage 1 -----
    always_ff @(posedge clk) begin
        if(i_vld) begin
            i_mem_pipe[0] <= i_data;
        end
    end

    // ----- mem pipe pipeline stage 2 -----
    always_ff @(posedge clk) begin
        if(i_vld) begin
            i_mem_pipe[1] <= i_mem_pipe[0];
        end
    end

    // ----- operation -----
    ifft_data_t  o_mem_pipe_tmp;
    // `ifdef NON_SCALE
        logic   signed  [IFFT_D_WIDTH-1:0]   re_addr0;
        logic   signed  [IFFT_D_WIDTH-1:0]   re_addr1;
        logic   signed  [IFFT_D_WIDTH-1:0]   im_addr0;
        logic   signed  [IFFT_D_WIDTH-1:0]   im_addr1;
    // `else
    //     logic   signed  [IFFT_D_WIDTH:0]     re_addr0;
    //     logic   signed  [IFFT_D_WIDTH:0]     re_addr1;
    //     logic   signed  [IFFT_D_WIDTH:0]     im_addr0;
    //     logic   signed  [IFFT_D_WIDTH:0]     im_addr1;
    // `endif

    // 	y[2].r = x[0].r - x[2].r
    // 	y[2].i = x[0].i - x[2].i
    assign  re_addr0 = i_mem_pipe[1].data_re - i_data.data_re;
    assign  im_addr0 = i_mem_pipe[1].data_im - i_data.data_im;

    // 	y[3].r = - (x[1].i - x[3].i)
    // 	y[3].i =   (x[1].r - x[3].r)
    assign  re_addr1 = i_data.data_im - i_mem_pipe[1].data_im;
    assign  im_addr1 = i_mem_pipe[1].data_re - i_data.data_re;
    always_comb begin   // calculate temp output
        if(addr[0]) begin
            // `ifdef NON_SCALE
                o_mem_pipe_tmp.data_re = (re_addr1);
                o_mem_pipe_tmp.data_im = (im_addr1);
            // `else
            //     o_mem_pipe_tmp.data_re = (re_addr1);
            //     o_mem_pipe_tmp.data_im = (im_addr1);
            // `endif
        end
        else begin
            // `ifdef NON_SCALE
                o_mem_pipe_tmp.data_re = (re_addr0);
                o_mem_pipe_tmp.data_im = (im_addr0);
            // `else
            //     o_mem_pipe_tmp.data_re = (re_addr0);
            //     o_mem_pipe_tmp.data_im = (im_addr0);
            // `endif
        end
    end

    always_ff @(posedge clk) begin
        o_mem_pipe[0] <= o_mem_pipe_tmp;
    end

    always_ff @(posedge clk) begin
        o_mem_pipe[1] <= o_mem_pipe[0];
    end

    // `ifdef NON_SCALE
        logic   signed  [IFFT_D_WIDTH-1:0]   add_re;
        logic   signed  [IFFT_D_WIDTH-1:0]   add_im;
    // `else
    //     logic   signed  [IFFT_D_WIDTH:0]     add_re;
    //     logic   signed  [IFFT_D_WIDTH:0]     add_im;
    // `endif

    // compute output
    assign  add_re = i_mem_pipe[1].data_re + i_data.data_re;
    assign  add_im = i_mem_pipe[1].data_im + i_data.data_im;

    always_ff @(posedge clk) begin
        if(~addr[1]) begin   // case 1: data out from mem (bot part)
            o_data <= (o_mem_pipe[1] >>> 1);
            o_data <= {(o_mem_pipe[1].data_re>>>1), (o_mem_pipe[1].data_im>>>1)};
        end
        else begin          // case 2: data out directly (top part)
            // `ifdef NON_SCALE
                o_data.data_re <= (add_re>>>1);
                o_data.data_im <= (add_im>>>1);
            // `else
            //     o_data.data_re <= (add_re);
            //     o_data.data_im <= (add_im);
            // `endif
        end
    end

    // assign o_vld
    assign o_vld = vld_pipe_3;

endmodule
