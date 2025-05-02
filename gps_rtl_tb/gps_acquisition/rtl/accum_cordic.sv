`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/13/2025 06:49:33 PM
// Design Name: 
// Module Name: accum_cordic
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


module accum_cordic(
    input   logic                   clk,
    input   logic                   rst_n,

    input   logic                   i_start,
    input   logic   [5:0]           i_doppler_id,
    
    output  logic                   o_vld,
    output  logic   signed  [15:0]  o_cosine,
    output  logic   signed  [15:0]  o_sine
);

    logic               acc_i_start;
    logic   [5:0]       acc_i_doppler_id;
    logic               acc_o_vld;
    logic   [34:0]      acc_o_angle;

    logic               cordic_i_vld;
    logic   [34:0]      cordic_i_angle;
    logic   [15:0]      cordic_o_cosine;
    logic   [15:0]      cordic_o_sine;
    logic               cordic_o_vld;

    accumulator accum(
        .clk(clk),
        .rst_n(rst_n),

        .i_start(acc_i_start),
        .i_doppler_id(acc_i_doppler_id),

        .o_vld(acc_o_vld),
        .o_angle(acc_o_angle)
    );
    assign  acc_i_start = i_start;
    assign  acc_i_doppler_id = i_doppler_id;

    cordic accum_cordic(
        .clk(clk),
        .rst_n(rst_n),

        .i_vld(cordic_i_vld),
        .i_angle(cordic_i_angle),

        .o_cosine(cordic_o_cosine),
        .o_sine(cordic_o_sine),
        .o_vld(cordic_o_vld)
    );
    assign  cordic_i_vld = acc_o_vld;
    assign  cordic_i_angle = acc_o_angle;

    assign  o_cosine = cordic_o_cosine;
    assign  o_sine = cordic_o_sine;
    assign  o_vld = cordic_o_vld;

endmodule
