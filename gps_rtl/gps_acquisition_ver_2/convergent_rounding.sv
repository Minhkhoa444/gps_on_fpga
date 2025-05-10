`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/18/2025 08:53:48 AM
// Design Name: 
// Module Name: convergent_rounding
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

(*use_dsp = "no"*)
module convergent_rounding #(
    parameter   IWIDTH = 33,
    parameter   OWIDTH = 18
)
(
    input   clk,
    input   rst_n,

    input   logic   i_vld,
    input   logic   signed  [IWIDTH-1:0]    i_data,

    output  logic   signed  [OWIDTH-1:0]    o_data,
    output  logic   o_vld
);

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            o_vld <= 'b0;
        end
        else begin
            o_vld <= i_vld;
        end
    end

    logic   signed  [IWIDTH-1:0]    rounded_result;

    // (*use_dsp = "no"*)
    assign  rounded_result = i_data[IWIDTH-1:0] + {{(OWIDTH){1'b0}}, i_data[IWIDTH-OWIDTH], {(IWIDTH-OWIDTH-1){!i_data[IWIDTH-OWIDTH]}}};

    always_ff @(posedge clk) begin
        o_data <= rounded_result[(IWIDTH-1):(IWIDTH-OWIDTH)];
    end

endmodule
