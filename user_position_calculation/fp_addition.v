`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2024 01:39:50 PM
// Design Name: 
// Module Name: fp_addition
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


module fp_addition #(
    parameter WIIA  = 15,
    parameter WIFA  = 16,
    parameter WIIB  = 15,
    parameter WIFB  = 16,
    parameter WOI   = 15,
    parameter WOF   = 16,
    parameter ROUND = 1
)(
    input   [WIIA+WIFA-1:0]     ina,
    input   [WIIB+WIFB-1:0]     inb,
    output  [WOI+WOF-1:0]       out,
    output                      overflow
    );

    localparam WII = WIIA>WIIB ? WIIA : WIIB;
    localparam WIF = WIFA>WIFB ? WIFA : WIFB;
    localparam WRI = WII + 1;
    localparam WRF = WIF;

    wire [WII+WIF-1:0] inaz, inbz;

    wire signed [WRI+WRF-1:0] res;
    assign res = $signed(inaz) + $signed(inbz);

    bit_width_conversion #(
        .WII        (WIIA),
        .WIF        (WIFA),
        .WOI        (WII),
        .WOF        (WIF),
        .ROUND      (0)
    ) bit_A (
        .in         (ina),
        .out        (inaz),
        .overflow   ()
    );

    bit_width_conversion #(
        .WII        (WIIB),
        .WIF        (WIFB),
        .WOI        (WII),
        .WOF        (WIF),
        .ROUND      (0)
    ) bit_B (
        .in         (inb),
        .out        (inbz),
        .overflow   ()
    )

    bit_width_conversion #(
        .WII        (WRI),
        .WIF        (WRF),
        .WOI        (WOI),
        .WOF        (WOF),
        .ROUND      (ROUND)
    ) bit_out (
        .in         (res),
        .out        (out),
        .overflow   (overflow)
    );
endmodule
