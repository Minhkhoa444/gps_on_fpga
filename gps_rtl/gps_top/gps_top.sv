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
    input   logic                               s_axil_rready,
    // --------------------------------------------------------------
    
    // ---------- INPUT/OUTPUT FROM/TO XILINX DMA ----------
    output logic[7 : 0]                         nav_tdata,
    output logic                                nav_tvalid
    // -----------------------------------------------------------------
);
    /* --------------------------------------------- INTERNAL SIGNALS DECLARATION --------------------------------------------- */
    // Signals for precomputed_ca ROM
    // When acquisition is operating -> precomputed_ca_rdaddr = ca_rdaddr_fr_acq. Otherwise it is ca_rdaddr_fr_tracker
        logic   [11:0]  ca_rdaddr_fr_acq;                       // Read Address from Acquisition 
        logic   [11:0]  ca_rdaddr_fr_dispatcher;                   // Read Address from Tracker
        logic   [11:0]  precomputed_ca_rdaddr;                  // Read Address to precomputed_ca
        logic   signed  [DAT_WIDTH-1:0] ca_o_data   [0:31];     // Output from precomputed_ca module

    // Signals for output of acquisition module
        logic   acq_done;                                       // Indicate whether the acq has been done
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
    logic   [11 : 0]                        tracker_0_early_addr;
    logic   [11 : 0]                        tracker_0_late_addr;
    logic   [11 : 0]                        tracker_0_prompt_addr;
    logic   [11 : 0]                        tracker_1_early_addr;
    logic   [11 : 0]                        tracker_1_late_addr;
    logic   [11 : 0]                        tracker_1_prompt_addr;
    logic   [11 : 0]                        tracker_2_early_addr;
    logic   [11 : 0]                        tracker_2_late_addr;
    logic   [11 : 0]                        tracker_2_prompt_addr;
    logic   [11 : 0]                        tracker_3_early_addr;
    logic   [11 : 0]                        tracker_3_late_addr;
    logic   [11 : 0]                        tracker_3_prompt_addr;
    logic   signed  [15 : 0]                tracker_0_early_code;
    logic   signed  [15 : 0]                tracker_0_late_code;
    logic   signed  [15 : 0]                tracker_0_prompt_code;
    logic   signed  [15 : 0]                tracker_1_early_code;
    logic   signed  [15 : 0]                tracker_1_late_code;
    logic   signed  [15 : 0]                tracker_1_prompt_code;
    logic   signed  [15 : 0]                tracker_2_early_code;
    logic   signed  [15 : 0]                tracker_2_late_code;
    logic   signed  [15 : 0]                tracker_2_prompt_code;
    logic   signed  [15 : 0]                tracker_3_early_code;
    logic   signed  [15 : 0]                tracker_3_late_code;
    logic   signed  [15 : 0]                tracker_3_prompt_code;
    logic   [11 : 0]                        early_code_addr[7];
    logic   [11 : 0]                        late_code_addr[7];
    logic   [11 : 0]                        prompt_code_addr[7];
    logic   signed  [15 : 0]                early_code[7];
    logic   signed  [15 : 0]                late_code[7];
    logic   signed  [15 : 0]                prompt_code[7];
    logic                                   tracking_valid[num_trackers];
    logic   signed  [15 : 0]                prompt_i[num_trackers];
    logic   signed  [15 : 0]                prompt_q[num_trackers];
    logic                                   nav_bit[num_trackers];
    logic                                   nav_bit_valid[num_trackers];
    // ---------------------------------
    // ------------------------------------



    // Precomputed CA Code ROM 
    precomputed_ca ca(
        .clk(clk),

        .i_rdaddr(precomputed_ca_rdaddr),
        .o_data(ca_o_data)
    );

    always_comb begin
        if(~acq_done) begin
            precomputed_ca_rdaddr = ca_rdaddr_fr_acq;
        end
        else begin
            precomputed_ca_rdaddr = ca_rdaddr_fr_dispatcher;
        end
    end



    // GPS Acquisition Module
    gps_acquisition_wrapper acquisition(
        .clk(clk),
        .rst_n(rst_n),

        // input and output from/to precomputed ca
        .ca_o_data(ca_o_data),
        .precomputed_ca_rdaddr(ca_rdaddr_fr_acq),
        .o_acq_done(acq_done),

        // input data from sdr and output tready to sdr
        .s_axis_tvalid      (s_axis_tvalid),        // tvalid
        .s_axis_tdata_i     (s_axis_gps_i),         // gps_i
        .s_axis_tdata_q     (s_axis_gps_q),         // gps_q
        .s_axis_tready      (s_axis_tready),        // tready

        // input tready, output data from/to gps_dispatcher
        .o_vld              (acq_o_vld),
        .o_doppler_shift    (acq_o_prn_id),
        .o_code_phase_delay (acq_o_doppler_shift),
        .o_prn_id           (acq_o_code_phase_delay)
    );

    

    // GPS Dispatcher Module
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
        .code_delay         (acq_o_code_phase_delay),
        .doppler_freq       (acq_o_doppler_shift),

        // GPS tracking
        .tracking_valid     (tracking_valid[0]),
        .dll_out            (dll_out),
        .tracker_0_early_addr(tracker_0_early_addr),
        .tracker_0_late_addr(tracker_0_late_addr),
        .tracker_0_prompt_addr(tracker_0_prompt_addr),

        .tracker_1_early_addr(tracker_1_early_addr),
        .tracker_1_late_addr(tracker_1_late_addr),
        .tracker_1_prompt_addr(tracker_1_prompt_addr),

        .tracker_2_early_addr(tracker_2_early_addr),
        .tracker_2_late_addr(tracker_2_late_addr),
        .tracker_2_prompt_addr(tracker_2_prompt_addr),

        .tracker_3_early_addr(tracker_3_early_addr),
        .tracker_3_late_addr(tracker_3_late_addr),
        .tracker_3_prompt_addr(tracker_3_prompt_addr),

        .tracker_0_early_code(tracker_0_early_code),
        .tracker_0_late_code(tracker_0_late_code),
        .tracker_0_prompt_code(tracker_0_prompt_code),

        .tracker_1_early_code(tracker_1_early_code),
        .tracker_1_late_code(tracker_1_late_code),
        .tracker_1_prompt_code(tracker_1_prompt_code),

        .tracker_2_early_code(tracker_2_early_code),
        .tracker_2_late_code(tracker_2_late_code),
        .tracker_2_prompt_code(tracker_2_prompt_code),

        .tracker_3_early_code(tracker_3_early_code),
        .tracker_3_late_code(tracker_3_late_code),
        .tracker_3_prompt_code(tracker_3_prompt_code),
        // Output
        .start_acquisition  (start_acquisition),
        .track_prn_id       (track_prn_id),
        .track_doppler      (track_doppler),
        .track_code_delay   (track_code_delay)
    );

    assign early_code_addr[0] = tracker_0_early_addr;
    assign early_code_addr[1] = tracker_1_early_addr;
    assign early_code_addr[2] = tracker_2_early_addr;
    assign early_code_addr[3] = tracker_3_early_addr;
    assign late_code_addr[0] = tracker_0_late_addr;
    assign late_code_addr[1] = tracker_1_late_addr;
    assign late_code_addr[2] = tracker_2_late_addr;
    assign late_code_addr[3] = tracker_3_late_addr;
    assign prompt_code_addr[0] = tracker_0_prompt_addr;
    assign prompt_code_addr[1] = tracker_1_prompt_addr;
    assign prompt_code_addr[2] = tracker_2_prompt_addr;
    assign prompt_code_addr[3] = tracker_3_prompt_addr;

    assign early_code[0] = tracker_0_early_code;
    assign early_code[1] = tracker_1_early_code;
    assign early_code[2] = tracker_2_early_code;
    assign early_code[3] = tracker_3_early_code;
    assign late_code[0] = tracker_0_late_code;
    assign late_code[1] = tracker_1_late_code;
    assign late_code[2] = tracker_2_late_code;
    assign late_code[3] = tracker_3_late_code;
    assign prompt_code[0] = tracker_0_prompt_code;
    assign prompt_code[1] = tracker_1_prompt_code;
    assign prompt_code[2] = tracker_2_prompt_code;
    assign prompt_code[3] = tracker_3_prompt_code;



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
                .i_init_code_phase  (track_code_delay[16 * i + 15 : 16  * i]),
                .i_init_doppler     (track_doppler[16 * i + 15 : 16 * i]),

                .o_valid            (tracking_valid[i]),
                .o_prompt_i         (prompt_i[i]),
                .o_prompt_q         (prompt_q[i]),
                .o_nav_bit          (nav_tdata[i]),
                .o_nav_bit_valid    (nav_bit_valid[i]),

                .early_code_addr    (early_code_addr[i]),
                .late_code_addr     (late_code_addr[i]),
                .prompt_code_addr   (prompt_code_addr[i]),
                .early_code         (early_code[i]),
                .late_code          (late_code[i]),
                .prompt_code        (prompt_code[i])
            );
            assign dll_out[32 * i + 31 : 32 * i] = {prompt_i[i], prompt_q[i]};
        end
    endgenerate

    assign nav_tvalid = nav_bit_valid[0];
endmodule
