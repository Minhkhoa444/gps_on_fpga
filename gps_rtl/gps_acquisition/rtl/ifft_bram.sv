`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 8th January 2025 08:17:45 AM
// Design Name: Fast Fourier Transform
// Module Name: ifft_bram
// Project Name: Software-defined Radio Global Positioning System FPGA-based Design
// Target Devices: UltraScale 96 v2.0
// Tool Versions: 
// Description: This design is used to instantiate a bram
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//`include "ifft_pkg.sv"

// import ifft_pkg::*;
import fft_pkg::*;

module ifft_bram #(
    parameter   SIZE = FFT_SIZE,                // parameter in pkg can not be redefined --> use a different name "SIZE"
    localparam  FFT_WIDTH = $clog2(SIZE)
)
(
    input   logic   clk,
    
    input   logic   [FFT_WIDTH-2:0]     i_wraddr,
    input   logic   [FFT_WIDTH-2:0]     i_rdaddr,

    input   logic                       i_en,
    input   data_t                      i_data,
    output  data_t                      o_data
);

    data_t  mem     [0:(SIZE/2)-1];

    always_ff @(posedge clk) begin
        if(i_en) begin
            mem[i_wraddr] <= i_data;
        end
        o_data <= mem[i_rdaddr];
    end

endmodule