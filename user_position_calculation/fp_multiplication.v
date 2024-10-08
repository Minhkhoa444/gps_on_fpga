`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2024 01:39:50 PM
// Design Name: 
// Module Name: fp_multiplication
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

// pipeline multiplication
module fp_multiplication # (
    parameter       WIIA = 15,
    parameter       WIFA = 16,
    parameter       WIIB = 15,
    parameter       WIFB = 16,
    parameter       WOI  = 15,
    parameter       WOF  = 16,
    parameter       ROUND = 1
)(
    input                                   clk,
    input                                   rst_n,
    input           [WIIA+WIFA-1 : 0]       ina,
    input           [WIIB+WIFB-1 : 0]       inb,
    output          [WOI+WOF-1 : 0]         out,
    output                                  overflow
    );

    localparam      WRI = WIIA + WIIB;
    localparam      WRF = WIFA + WIFB;

    reg             [WOI+WOF-1 : 0]         out;
    reg                                     overflow;

    wire            [WOI+WOF-1 : 0]         outc;
    wire                                    overflowc;

    reg signed      [WRI+WRF-1 : 0]         res;

    wire signed [WRI+WRF-1 : 0] res_tmp;
    assign res_tmp = $signed(ina) * $signed(inb);
    always @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            res <= 0;
        end 
        else begin
            res <= res_tmp;
        end
    end

    bit_width_conversion #(
        .WII        (WRI),
        .WIF        (WRF),
        .WOI        (WOI),
        .WOF        (WOF),
        .ROUND      (ROUND)
    ) bit_res (
        .in         (res),
        .out        (outc),
        .overflow   (overflowc)
    );

    always @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            out <= 0;
            overflow <= 0;
        end else begin
            out <= outc;
            overflow <= overflowc;
        end
    end

endmodule
