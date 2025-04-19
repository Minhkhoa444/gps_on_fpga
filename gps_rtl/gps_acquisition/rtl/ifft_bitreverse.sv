`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/16/2025 08:36:18 PM
// Design Name: 
// Module Name: ifft_bitreverse
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

// import ifft_pkg::*;
import fft_pkg::*;

module ifft_bitreverse
#(
    parameter SIZE = FFT_SIZE,
    localparam WIDTH = $clog2(SIZE)
    // parameter BITREVERSE_D_WIDTH = D_WIDTH
)
(
    input   logic       clk,
    input   logic       rst_n,

    `ifndef OPTIMIZE
    input   logic       i_sync_rst,
    `endif
    
    input   logic       i_vld,
    `ifdef IFFT_VERIFICATION
        input   ifft_data_t      i_data,
    `else
        input   logic   signed  [15:0]  i_data,
    `endif

    output  logic       o_vld,
    // output  bitreverse_data_t      o_data
    `ifdef IFFT_VERIFICATION
        output  ifft_data_t      o_data
    `else
        output  logic   signed  [15:0]  o_data
    `endif
);

    // bitreverse_data_t  pingpong_mem    [0:SIZE*2-1];
    `ifdef IFFT_VERIFICATION
        ifft_data_t  pingpong_mem    [0:SIZE*2-1];
    `else
        logic   signed  [15:0]  pingpong_mem    [0:SIZE*2-1];
    `endif

    logic   [WIDTH:0]   wraddr;
    logic   [WIDTH:0]   wraddr_nxt;
    logic   [WIDTH:0]   rdaddr;

    logic   start;
    logic   start_tmp;
    logic   start_en;
    assign  start_en = &(wraddr[WIDTH-1:0]);
    assign  start_tmp = (start_en) ? i_vld : start;
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            start <= 1'b0;
        end
        else begin
            `ifndef OPTIMIZE
                if(i_sync_rst) begin
                    start <= 'b0;
                end
                else begin
                    start <= start_tmp;
                end
            `else
                start <= start_tmp;
            `endif
        end
    end

    logic   en;
    assign  en = (i_vld | start);
    logic   [WIDTH:0]   wraddr_tmp;
    assign  wraddr_tmp = (en) ? wraddr + 1'b1 : wraddr;
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            wraddr <= 'b0;
            wraddr_nxt <= 'b0;
        end
        else begin
            `ifndef OPTIMIZE
                if(i_sync_rst) begin
                    wraddr <= 'b0;
                    wraddr_nxt <= 'b0;
                end
                else begin
                    wraddr <= wraddr_tmp;
                    wraddr_nxt[0] <= wraddr[0];
                    wraddr_nxt[WIDTH:1] <= wraddr[WIDTH:1] + 1'b1;
                end
            `else
                wraddr <= wraddr_tmp;
                wraddr_nxt[0] <= wraddr[0];
                wraddr_nxt[WIDTH:1] <= wraddr[WIDTH:1] + 1'b1;
            `endif
        end
    end

	genvar	i;
	generate 
        for(i=0; i<WIDTH; i=i+1)
        begin
            assign rdaddr[i] = wraddr_nxt[WIDTH-1-i];
        end 
    endgenerate
    assign  rdaddr[WIDTH] = ~wraddr_nxt[WIDTH];

    always_ff @(posedge clk) begin
        if(en) begin
            // pingpong_mem[wraddr].data_re <= i_data.data_re[15:0];
            // pingpong_mem[wraddr].data_im <= i_data.data_im[15:0];
            pingpong_mem[wraddr] <= i_data;
        end
        o_data <= pingpong_mem[rdaddr];
    end

    assign o_vld = start;

endmodule