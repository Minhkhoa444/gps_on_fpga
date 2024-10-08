`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/06/2024 08:48:54 PM
// Design Name: 
// Module Name: UserPositionCalculation
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


module upc #(
    parameter               INT_WIDTH       =       16,
    parameter               FRAC_WIDTH      =       16,
)(
    // ================================================= INPUT =================================================

    // clock and reset signals
    input                                               clk,
    input                                               rst_n,

    // AXI4-Stream handshake signals
    input                                               rf_axis_tvalid_i,       // Input from RF
    input                                               rf_axis_tlast_i,        // Input from RF
    input                                               rf_axis_tready_i,       // Input from uart

    // 1st Satellite's Coordinate and distance to receiver
    input       [INT_WIDTH + FRAC_WIDTH]                rf_axis_sat1x_i,
    input       [INT_WIDTH + FRAC_WIDTH]                rf_axis_sat1y_i,
    input       [INT_WIDTH + FRAC_WIDTH]                rf_axis_sat1z_i,
    input       [INT_WIDTH + FRAC_WIDTH]                rf_axis_sat1d_i,

    // 2nd Satellite's Coordinate and distance to receiver
    input       [INT_WIDTH + FRAC_WIDTH]            rf_axis_sat2x_i,
    input       [INT_WIDTH + FRAC_WIDTH]            rf_axis_sat2y_i,
    input       [INT_WIDTH + FRAC_WIDTH]            rf_axis_sat2z_i,
    input       [INT_WIDTH + FRAC_WIDTH]            rf_axis_sat2d_i,

    // 3rd Satellite's Coordinate and distance to receiver
    input       [INT_WIDTH + FRAC_WIDTH]            rf_axis_sat3x_i,
    input       [INT_WIDTH + FRAC_WIDTH]            rf_axis_sat3y_i,
    input       [INT_WIDTH + FRAC_WIDTH]            rf_axis_sat3z_i,
    input       [INT_WIDTH + FRAC_WIDTH]            rf_axis_sat3d_i,

    // 4th Satellite's Coordinate and distance to receiver
    input       [INT_WIDTH + FRAC_WIDTH]            rf_axis_sat4x_i,
    input       [INT_WIDTH + FRAC_WIDTH]            rf_axis_sat4y_i,
    input       [INT_WIDTH + FRAC_WIDTH]            rf_axis_sat4z_i,
    input       [INT_WIDTH + FRAC_WIDTH]            rf_axis_sat4d_i,

    // =========================================================================================================



    // ================================================= OUTPUT ================================================

    // AXI4-Stream handshake signals
    output                                              upc_axis_tvalid_o,
    output                                              upc_axis_tlast_o,
    output                                              upc_axis_tready_o,

    // Estimated User's Location
    output      [INT_WIDTH + FRAC_WIDTH]                upc_axis_userx_o,
    output      [INT_WIDTH + FRAC_WIDTH]                upc_axis_usery_o,
    output      [INT_WIDTH + FRAC_WIDTH]                upc_axis_userz_o

    // =========================================================================================================
    );

    

endmodule
