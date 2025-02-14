`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/11/2025 08:57:55 AM
// Design Name: 
// Module Name: input_buffer_pkg
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


package acquisition_pkg;
    parameter   DAT_WIDTH = 16;

    typedef struct packed {
        logic   signed  [DAT_WIDTH-1:0] gps_i;
        logic   signed  [DAT_WIDTH-1:0] gps_q;
    } dat_gps_t;
endpackage
