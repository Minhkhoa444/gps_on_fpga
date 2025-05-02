`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/23/2025 10:01:01 AM
// Design Name: 
// Module Name: gps_acquisition_wrapper
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

// `define WRAPPER_SV
module gps_acquisition_wrapper_sv(
    input   logic   clk,
    input   logic   rst_n,

    input   logic                   s_axis_tvalid,      // tvalid
    input   logic   signed  [15:0]  s_axis_tdata_i,     // gps_i
    input   logic   signed  [15:0]  s_axis_tdata_q,     // gps_q
    output  logic                   s_axis_tready,      // tready

    output  logic                   o_vld,
    output  logic   signed  [14:0]  o_doppler_shift,
    output  logic           [11:0]  o_code_phase_delay,
    output  logic           [4:0]   o_prn_id
);

    logic   acq_o_vld;
    logic   signed  [15:0]  acq_corr_result;
    logic   signed  [14:0]  acq_doppler_shift;
    logic   [4:0]           acq_prn_id;
    logic   [11:0]          acq_code_phase_delay;

    gps_acquisition acq(
        .clk(clk),
        .rst_n(rst_n),

        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tdata_i(s_axis_tdata_i),
        .s_axis_tdata_q(s_axis_tdata_q),
        .s_axis_tready(s_axis_tready),

        .m_axis_tvalid(acq_o_vld),
        .m_axis_tdata(acq_corr_result),
        .m_axis_tprn_id(acq_prn_id),
        .m_axis_td_shift(acq_doppler_shift),
        .m_axis_tposition(acq_code_phase_delay)
    );

    rec_all_sat rec(
        .clk(clk),
        .rst_n(rst_n),

        .i_vld(acq_o_vld),
        .i_corr_result(acq_corr_result),
        .i_prn_id(acq_prn_id),
        .i_doppler_shift(acq_doppler_shift),
        .i_code_phase_delay(acq_code_phase_delay),

        .o_vld(o_vld),
        .o_doppler_shift(o_doppler_shift),
        .o_code_phase_delay(o_code_phase_delay),
        .o_prn_id(o_prn_id)
    );
endmodule