`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/17/2025 09:37:45 AM
// Design Name: 
// Module Name: soft_multiplier
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

//import fft_pkg::*;

module soft_multiplier #(
    parameter   DAT_WIDTH_OP_1 = 28,
    parameter   DAT_WIDTH_OP_2 = 16,
    parameter   FRAC_BIT = 15
)(
    input   logic   clk,
    input   logic   rst_n,

    input   logic   i_vld,
    input   logic   signed  [DAT_WIDTH_OP_1-1:0]     i_operand_1,
    input   logic   signed  [DAT_WIDTH_OP_2-1:0]     i_operand_2,

    output  logic   o_vld,
    output  logic   signed  [DAT_WIDTH_OP_1-1:0]     o_result
);

    logic   signed  [DAT_WIDTH_OP_1*2-1:0]      mult_stg    [0:DAT_WIDTH_OP_2-1];
    logic                                       vld_stg     [0:DAT_WIDTH_OP_2-1];
    logic   signed  [DAT_WIDTH_OP_1-1:0]        operand_1   [0:DAT_WIDTH_OP_2-1];
    logic   signed  [DAT_WIDTH_OP_2-1:0]        operand_2   [0:DAT_WIDTH_OP_2-1];

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            vld_stg[0] <= 'b0;
        end
        else begin
            vld_stg[0] <= i_vld;
        end
    end

    logic   signed  [DAT_WIDTH_OP_1*2-1:0] mult_stg_0_tmp;
    always_comb begin
        if(i_operand_2[0]) begin
            mult_stg_0_tmp = i_operand_1;
        end
        else begin
            mult_stg_0_tmp = 'b0;
        end
    end
    always_ff @(posedge clk) begin
        mult_stg[0] <= mult_stg_0_tmp;
        operand_1[0] <= i_operand_1;
        operand_2[0] <= i_operand_2;
    end

    genvar i;
    generate
        for(i=1; i<DAT_WIDTH_OP_2-1; i++) begin
            logic   signed  [DAT_WIDTH_OP_1*2-1:0]  mult_stg_tmp;
            always_comb begin
                if(operand_2[i-1][i]) begin
                    mult_stg_tmp = $signed(mult_stg[i-1] + (operand_1[i-1] <<< i));
                end
                else begin
                    mult_stg_tmp = mult_stg[i-1];
                end
            end
            always_ff @(posedge clk, negedge rst_n) begin
                if(~rst_n) begin
                    vld_stg[i] <= 'b0;
                end
                else begin
                    vld_stg[i] <= vld_stg[i-1];
                end
            end
            always_ff @(posedge clk) begin
                mult_stg[i] <= mult_stg_tmp;
            end
            always_ff @(posedge clk) begin
                operand_1[i] <= operand_1[i-1];
                operand_2[i] <= operand_2[i-1];
            end
        end
    endgenerate

    always_ff @(posedge clk) begin
        if(operand_2[DAT_WIDTH_OP_2-2][DAT_WIDTH_OP_2-1]) begin
            mult_stg[DAT_WIDTH_OP_2-1] <= $signed(mult_stg[DAT_WIDTH_OP_2-2] + (-(operand_1[DAT_WIDTH_OP_2-2] <<< (DAT_WIDTH_OP_2-1))));
        end
        else begin
            mult_stg[DAT_WIDTH_OP_2-1] <= mult_stg[DAT_WIDTH_OP_2-2];
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            vld_stg[DAT_WIDTH_OP_2-1] <= 'b0;
        end
        else begin
            vld_stg[DAT_WIDTH_OP_2-1] <= vld_stg[DAT_WIDTH_OP_2-2];
        end
    end
    always_ff @(posedge clk) begin
        operand_1[DAT_WIDTH_OP_2-1] <= operand_1[DAT_WIDTH_OP_2-2];
        operand_2[DAT_WIDTH_OP_2-1] <= operand_2[DAT_WIDTH_OP_2-2];
    end
    assign  o_result = mult_stg[DAT_WIDTH_OP_2-1] >>> FRAC_BIT;
    assign  o_vld = vld_stg[DAT_WIDTH_OP_2-1];

endmodule
