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

module gps_acquisition_wrapper(
    input   clk,
    input   rst_n,
    input                           s_axis_tvalid,      // tvalid
    input   signed  [15:0]          s_axis_tdata_i,     // gps_i
    input   signed  [15:0]          s_axis_tdata_q,     // gps_q
    output                          s_axis_tready,      // tready

    output                          o_vld,
    output  signed  [15:0]          o_corr_result,
    output  signed  [14:0]          o_doppler_shift,
    output          [11:0]          o_code_phase_delay,
    output          [4:0]           o_prn_id
);

    wire    acq_o_vld;
    wire    signed  [15:0]          acq_corr_result;
    wire    signed  [14:0]          acq_doppler_shift;
    wire    [4:0]                   acq_prn_id;
    wire    [11:0]                  acq_code_phase_delay;
    `ifdef WRAPPER_SV
        wire    [1:0]                   rec_all_sat_cnt;
        wire                            acq_done;
        wire    signed  [DAT_WIDTH-1:0] ca_o_data   [0:31];
        wire    [11:0]                  precomputed_ca_rdaddr;
        precomputed_ca ca (
            .clk(clk),
        
            .i_rdaddr(precomputed_ca_rdaddr),
            .o_data(ca_o_data)
        );
    `endif

    gps_acquisition acq(
        .clk(clk),
        .rst_n(rst_n),

        `ifdef WRAPPER_SV
            // input data from precomputed_ca
            .ca_o_data(ca_o_data),
            .precomputed_ca_rdaddr(precomputed_ca_rdaddr),
        `endif

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
    
    ila_0 ila_0 (
        .clk(clk), // input wire clk
    
    
        .probe0(acq.acc_start) // input wire [0:0] probe0
    );

    rec_all_sat rec(
        .clk(clk),
        .rst_n(rst_n),

        .i_vld(acq_o_vld),
        .i_corr_result(acq_corr_result),
        .i_prn_id(acq_prn_id),
        .i_doppler_shift(acq_doppler_shift),
        .i_code_phase_delay(acq_code_phase_delay),

        `ifdef WRAPPER_SV
        .o_cnt(rec_all_sat_cnt),
        .o_acq_done(acq_done),
        `endif

        .o_vld(o_vld),
        .o_corr_result(o_corr_result),
        .o_doppler_shift(o_doppler_shift),
        .o_code_phase_delay(o_code_phase_delay),
        .o_prn_id(o_prn_id)
    );
endmodule