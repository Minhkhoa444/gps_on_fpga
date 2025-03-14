`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/10/2025 08:08:37 PM
// Design Name: 
// Module Name: gps_top
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

import acquisition_pkg::*;
import fft_pkg::*;

module gps_top #(
    parameter axil_addr_width = 10,
    parameter axil_data_width = 32,
    parameter num_trackers = 8,
    parameter ACC_WIDTH = 32
)(
    input   logic   clk,
    input   logic   rst_n,

    // ---------- INPUT/OUTPUT FROM/TO SOFTWARE_DEFINED RADIO ----------
    input   logic                               s_axis_tvalid,
    input   logic   signed  [DAT_WIDTH-1:0]     s_axis_gps_i,
    input   logic   signed  [DAT_WIDTH-1:0]     s_axis_gps_q,

    output  logic                               s_axis_tready,
    // -----------------------------------------------------------------

    // ---------- INPUT/OUTPUT FROM/TO XILINX INTERCONNECT ----------
    // AW channel
    input   logic   [axil_addr_width - 1 : 0]   s_axil_awaddr,
    input   logic                               s_axil_awvalid,
    output  logic                               s_axil_awready,

    // W channel
    input   logic   [axil_data_width - 1 : 0]   s_axil_wdata,
    input   logic   [axil_data_width / 8 - 1 : 0]   s_axil_wstrb,
    input   logic                               s_axil_wvalid,
    output  logic                               s_axil_wready,

    // B channel
    output  logic   [1:0]                       s_axil_bresp,
    output  logic                               s_axil_bvalid,
    input   logic                               s_axil_bready,

    // AR channel
    input   logic   [axil_addr_width - 1 : 0]   s_axil_araddr,
    input   logic                               s_axil_arvalid,
    output  logic                               s_axil_arready,

    // R channel
    output  logic   [axil_data_width - 1 : 0]   s_axil_rdata,
    output  logic   [1:0]                       s_axil_rresp,
    output  logic                               s_axil_rvalid,
    input   logic                               s_axil_rready
    // --------------------------------------------------------------
    
);
    // ---------- GPS Acquisition ----------
    // Output
    logic                                   acq_o_vld;
    logic   signed  [15:0]                  acq_o_data;
    logic           [4:0]                   acq_o_prn_id;
    logic   signed  [14:0]                  acq_o_d_shift;
    logic           [11:0]                  acq_o_position;
    // -------------------------------------

    // ---------- GPS Dispatcher ----------
    // GPS acquisition
    logic   [5:0]                           prn_id;
    logic   [axil_data_width - 1 : 0]       correlation_result;
    logic   [axil_data_width - 1 : 0]       code_delay;
    logic   [axil_data_width - 1 : 0]       doppler_freq;

    // GPS tracking
    logic   [num_trackers - 1 : 0]          lock_loss;
    logic   [num_trackers * 32 - 1 : 0]     dll_out;

    // Output
    logic                                   start_acquisition;
    logic   [6 * num_trackers - 1 : 0]      track_prn_id;
    logic   [16 * num_trackers - 1 : 0]     track_doppler;
    logic   [16 * num_trackers - 1 : 0]     track_code_delay;

    // ---------- GPS Tracker ----------
    logic                                   tracking_valid[num_trackers];
    logic   signed  [31 : 0]                prompt_i[num_trackers];
    logic   signed  [31 : 0]                prompt_q[num_trackers];
    logic                                   pll_lock[num_trackers];
    logic                                   dll_lock[num_trackers];
    logic                                   nav_bit[num_trackers];
    logic                                   nav_bit_valid[num_trackers];
    // ---------------------------------
    // ------------------------------------


    gps_acquisition acquisition(
        .clk(clk),
        .rst_n(~start_acquisition),

        // input data from sdr and output tready to sdr
        .s_axis_tvalid      (s_axis_tvalid),        // tvalid
        .s_axis_tdata_i     (s_axis_gps_i),         // gps_i
        .s_axis_tdata_q     (s_axis_gps_q),         // gps_q
        .s_axis_tready      (s_axis_tready),        // tready

        // input tready, output data from/to gps_dispatcher
        .m_axis_tvalid      (acq_o_vld),
        .m_axis_tdata       (acq_o_data),
        .m_axis_tprn_id     (acq_o_prn_id),
        .m_axis_td_shift    (acq_o_d_shift),
        .m_axis_tposition   (acq_o_position)
    );

    gps_dispatcher dispatcher(
        .aclk(clk),
        .aresetn(rst_n),

        // AW channel
        .s_axil_awaddr      (s_axil_awaddr),
        .s_axil_awvalid     (s_axil_awvalid),
        .s_axil_awready     (s_axil_awready),

        // W channel
        .s_axil_wdata       (s_axil_wdata),
        .s_axil_wstrb       (s_axil_wstrb),
        .s_axil_wvalid      (s_axil_wvalid),
        .s_axil_wready      (s_axil_wready),

        // B channel
        .s_axil_bresp       (s_axil_bresp),
        .s_axil_bvalid      (s_axil_bvalid),
        .s_axil_bready      (s_axil_bready),

        // AR channel
        .s_axil_araddr      (s_axil_araddr),
        .s_axil_arvalid     (s_axil_arvalid),
        .s_axil_arready     (s_axil_arready),

        // R channel
        .s_axil_rdata       (s_axil_rdata),
        .s_axil_rresp       (s_axil_rresp),
        .s_axil_rvalid      (s_axil_rvalid),
        .s_axil_rready      (s_axil_rready),

        // GPS acquisition
        .acquisition_valid  (acq_o_vld),
        .prn_id             (acq_o_prn_id),
        .correlation_result (acq_o_data),
        .code_delay         (acq_o_position),
        .doppler_freq       (acq_o_d_shift),

        // GPS tracking
        .tracking_valid     (tracking_valid[0]),
        .lock_loss          (lock_loss),
        .dll_out            (dll_out),

        // Output
        .start_acquisition  (start_acquisition),
        .track_prn_id       (track_prn_id),
        .track_doppler      (track_doppler),
        .track_code_delay   (track_code_delay)
    );

    genvar i;
    generate
        for(i = 0; i < num_trackers; i = i + 1) begin
            gps_tracker_channel gps_tracker(
                .clk_i(clk),
                .rst_i(rst_n),

                .i_valid            (s_axis_tvalid),
                .i_data_i           (s_axis_gps_i),
                .i_data_q           (s_axis_gps_q),
                .i_prn_select       (track_prn_id[6 * i + 4 : 6 * i]),
                .i_init_code_phase  (track_code_delay[16 * i + 15 : 16  * i]),
                .i_init_doppler     (track_doppler[16 * i + 15 : 16 * i]),

                .o_valid            (tracking_valid[i]),
                .o_prompt_i         (prompt_i[i]),
                .o_prompt_q         (prompt_q[i]),
                .o_pll_lock         (pll_lock[i]),
                .o_dll_lock         (dll_lock[i]),
                .o_nav_bit          (nav_bit[i]),
                .o_nav_bit_valid    (nav_bit_valid[i])
            );
            assign lock_loss[i] = ~(pll_lock[i] && dll_lock[i]);
            assign dll_out[32 * i + 31 : 32 * i] = {prompt_i[i], prompt_q[i]};
        end
    endgenerate
endmodule
