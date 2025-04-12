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

// import acquisition_pkg::*;
import fft_pkg::*;

module gps_top #(
    parameter axil_addr_width = 10,
    parameter axil_data_width = 32,
    parameter num_trackers = 4,
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
    // // AW channel
    // input   logic   [axil_addr_width - 1 : 0]   s_axil_awaddr,
    // input   logic                               s_axil_awvalid,
    // output  logic                               s_axil_awready,

    // // W channel
    // input   logic   [axil_data_width - 1 : 0]   s_axil_wdata,
    // input   logic   [axil_data_width / 8 - 1 : 0]   s_axil_wstrb,
    // input   logic                               s_axil_wvalid,
    // output  logic                               s_axil_wready,

    // // B channel
    // output  logic   [1:0]                       s_axil_bresp,
    // output  logic                               s_axil_bvalid,
    // input   logic                               s_axil_bready,

    // // AR channel
    // input   logic   [axil_addr_width - 1 : 0]   s_axil_araddr,
    // input   logic                               s_axil_arvalid,
    // output  logic                               s_axil_arready,

    // // R channel
    // output  logic   [axil_data_width - 1 : 0]   s_axil_rdata,
    // output  logic   [1:0]                       s_axil_rresp,
    // output  logic                               s_axil_rvalid,
    // input   logic                               s_axil_rready,
    // // --------------------------------------------------------------
    
    // ---------- INPUT/OUTPUT FROM/TO XILINX DMA ----------
    output logic[3 : 0]                         nav_tdata,
    output logic                                nav_tvalid
    // -----------------------------------------------------------------
);
    /* --------------------------------------------- INTERNAL SIGNALS DECLARATION --------------------------------------------- */
    // Signals for output of acquisition module
    logic   acq_o_vld;                                      // Only 4 valid asserted corresponding to 4 top peak
    logic   signed  [14:0]  acq_o_doppler_shift;            // Only 4 doppler shifts corresponding to 4 top peak
    logic   [11:0]  acq_o_code_phase_delay;                 // Only 4 code phase delay corresponding to 4 top peak
    logic   [4:0]   acq_o_prn_id;                           // Only 4 PRN ID corresponding to 4 top peak
    /* ----------------------------------------------------------------------------------------------------------------------- */

    // ---------- GPS Dispatcher ----------
    // GPS acquisition
    logic   [5:0]                           prn_id;
    logic   [axil_data_width - 1 : 0]       correlation_result;
    logic   [axil_data_width - 1 : 0]       code_delay;
    logic   [axil_data_width - 1 : 0]       doppler_freq;

    // GPS tracking
    logic   [num_trackers * 32 - 1 : 0]     dll_out;

    // Output
    logic                                   start_acquisition;
    logic   [6 * num_trackers - 1 : 0]      track_prn_id;
    logic   [16 * num_trackers - 1 : 0]     track_doppler;
    logic   [16 * num_trackers - 1 : 0]     track_code_delay;

    // ---------- GPS Tracker ----------
    logic                                   tracking_valid[num_trackers];
    logic   signed  [15 : 0]                prompt_i[num_trackers];
    logic   signed  [15 : 0]                prompt_q[num_trackers];
    logic                                   nav_bit[num_trackers];
    logic                                   nav_bit_valid[num_trackers];
    // ---------------------------------
    logic                                   s_axis_tready_r;


    // GPS Acquisition Module
    gps_acquisition_wrapper_sv acquisition(
        .clk(clk),
        .rst_n(rst_n),

        // input data from sdr and output tready to sdr
        .s_axis_tvalid      (s_axis_tvalid),        // tvalid
        .s_axis_tdata_i     (s_axis_gps_i),         // gps_i
        .s_axis_tdata_q     (s_axis_gps_q),         // gps_q
        .s_axis_tready      (s_axis_tready_r),        // tready

        // input tready, output data from/to gps_dispatcher
        .o_vld              (acq_o_vld),
        .o_doppler_shift    (acq_o_doppler_shift),
        .o_code_phase_delay (acq_o_code_phase_delay),
        .o_prn_id           (acq_o_prn_id)
    );

    logic [1:0] idx;
    logic   signed  [14:0]  doppler_shift_idx [0:3];            
    logic   [11:0]  code_delay_idx [0:3];     
    logic   [4:0]   prn_id_idx [0:3];  

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            idx <= 'h0;
            for (int i = 0; i < 4; i++) begin
                doppler_shift_idx[i] <= 'h0;
                code_delay_idx[i] <= 'h0;
                prn_id_idx[i] <= 'h0;
            end
        end else begin
            if (acq_o_vld) begin
                doppler_shift_idx[idx] <= acq_o_doppler_shift;
                code_delay_idx[idx] <= acq_o_code_phase_delay;
                prn_id_idx[idx] <= acq_o_prn_id;
                idx <= idx + 1;
            end
        end
    end

    // assign acq_o_vld = 1;
    // assign acq_o_doppler_shift = 1;
    // assign acq_o_code_phase_delay = 1;
    // assign acq_o_prn_id = 1;

    // 4 GPS Trackers
    genvar i;
    generate
        for(i = 0; i < num_trackers; i = i + 1) begin
            gps_tracker_channel gps_tracker(
                .clk_i(clk),
                .rst_i(rst_n),

                .i_valid            (s_axis_tvalid),
                .i_data_i           (s_axis_gps_i),
                .i_data_q           (s_axis_gps_q),
                .i_prn_id           (doppler_shift_idx[i]),
                .i_init_code_phase  (code_delay_idx[i]),
                .i_init_doppler     (doppler_shift_idx[i]),
                // .i_prn_id           ((idx == i && acq_o_vld) ? acq_o_prn_id : 0),
                // .i_init_code_phase  ((idx == i && acq_o_vld) ? acq_o_code_phase_delay : 0),
                // .i_init_doppler     ((idx == i && acq_o_vld) ? acq_o_doppler_shift : 0),

                .o_valid            (tracking_valid[i]),
                .o_prompt_i         (prompt_i[i]),
                .o_prompt_q         (prompt_q[i]),
                .o_nav_bit          (nav_tdata[i]),
                .o_nav_bit_valid    (nav_bit_valid[i])
            );
            assign dll_out[32 * i + 31 : 32 * i] = {prompt_i[i], prompt_q[i]};
        end
    endgenerate

    assign nav_tvalid = nav_bit_valid[0];
    assign s_axis_tready = 1;
endmodule
