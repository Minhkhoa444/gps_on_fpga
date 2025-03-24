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
        .o_corr_result(o_corr_result),
        .o_doppler_shift(o_doppler_shift),
        .o_code_phase_delay(o_code_phase_delay),
        .o_prn_id(o_prn_id)
    );

    // reg acq_done;
    // always @(posedge clk, negedge rst_n) begin
    //     if(~rst_n) begin
    //         acq_done <= 'b0;
    //     end
    //     else begin
    //         if(acq_doppler_shift==-10000 && &acq_prn_id && &acq_code_phase_delay) begin
    //             acq_done <= 'b1;
    //         end
    //     end
    // end

    // reg signed  [15:0]  corr_result         [0:31];
    // reg signed  [14:0]  doppler_shift       [0:31];
    // reg [11:0]          code_phase_delay    [0:31];

    // integer i;

    // always @(posedge clk, negedge rst_n) begin
    //     if(~rst_n) begin
    //         for(i=0; i<32; i=i+1) begin
    //             corr_result[i] <= 'b0;
    //         end
    //     end
    //     else begin
    //         if(acq_o_vld) begin
    //             if(acq_corr_result > corr_result[acq_prn_id]) begin
    //                 corr_result[acq_prn_id] <= acq_corr_result;
    //                 doppler_shift[acq_prn_id] <= acq_doppler_shift;
    //                 code_phase_delay[acq_prn_id] <= acq_code_phase_delay;
    //             end
    //         end
    //     end
    // end

    // reg top_4_vld;
    // reg [4:0]   cnt;
    // reg flag;
    // always @(posedge clk, negedge rst_n) begin
    //     if(~rst_n) begin
    //         top_4_vld <= 'b0;
    //         flag <= 'b0;
    //     end
    //     else begin
    //         if(~top_4_vld && ~flag) begin
    //             if(acq_done) begin
    //                 top_4_vld <= 'b1;
    //                 flag <= 'b1;
    //             end
    //         end
    //         else begin
    //             if(&cnt) begin
    //                 top_4_vld <= 'b0;
    //             end
    //         end
    //     end
    // end

    // always @(posedge clk, negedge rst_n) begin
    //     if(~rst_n) begin
    //         cnt <= 'b0;
    //     end
    //     else begin
    //         if(top_4_vld) cnt <= cnt + 'b1;
    //     end
    // end

    // wire    pick_vld_tmp;
    // wire    signed  [15:0]  o_corr_result_0_tmp;
    // wire    signed  [14:0]  o_doppler_shift_0_tmp;
    // wire    [4:0]           o_prn_id_0_tmp;
    // wire    [11:0]          o_code_phase_delay_0_tmp;

    // wire    signed  [15:0]  o_corr_result_1_tmp;
    // wire    signed  [14:0]  o_doppler_shift_1_tmp;
    // wire    [4:0]           o_prn_id_1_tmp;
    // wire    [11:0]          o_code_phase_delay_1_tmp;

    // wire    signed  [15:0]  o_corr_result_2_tmp;
    // wire    signed  [14:0]  o_doppler_shift_2_tmp;
    // wire    [4:0]           o_prn_id_2_tmp;
    // wire    [11:0]          o_code_phase_delay_2_tmp;

    // wire    signed  [15:0]  o_corr_result_3_tmp;
    // wire    signed  [14:0]  o_doppler_shift_3_tmp;
    // wire    [4:0]           o_prn_id_3_tmp;
    // wire    [11:0]          o_code_phase_delay_3_tmp;

    // reg    signed  [15:0]  o_corr_result_0;
    // reg    signed  [14:0]  o_doppler_shift_0;
    // reg    [4:0]           o_prn_id_0;
    // reg    [11:0]          o_code_phase_delay_0;

    // reg    signed  [15:0]  o_corr_result_1;
    // reg    signed  [14:0]  o_doppler_shift_1;
    // reg    [4:0]           o_prn_id_1;
    // reg    [11:0]          o_code_phase_delay_1;

    // reg    signed  [15:0]  o_corr_result_2;
    // reg    signed  [14:0]  o_doppler_shift_2;
    // reg    [4:0]           o_prn_id_2;
    // reg    [11:0]          o_code_phase_delay_2;

    // reg    signed  [15:0]  o_corr_result_3;
    // reg    signed  [14:0]  o_doppler_shift_3;
    // reg    [4:0]           o_prn_id_3;
    // reg    [11:0]          o_code_phase_delay_3;

    // pick_top_4 pick(
    //     .clk(clk),
    //     .rst_n(rst_n),

    //     .i_vld(top_4_vld),
    //     .i_corr_result(corr_result[cnt]),
    //     .i_doppler_shift(doppler_shift[cnt]),
    //     .i_prn_id(cnt),
    //     .i_code_phase_delay(code_phase_delay[cnt]),

    //     .o_vld(pick_vld_tmp),
    //     .o_corr_result_0(o_corr_result_0_tmp),
    //     .o_doppler_shift_0(o_doppler_shift_0_tmp),
    //     .o_prn_id_0(o_prn_id_0_tmp),
    //     .o_code_phase_delay_0(o_code_phase_delay_0_tmp),

    //     .o_corr_result_1(o_corr_result_1_tmp),
    //     .o_doppler_shift_1(o_doppler_shift_1_tmp),
    //     .o_prn_id_1(o_prn_id_1_tmp),
    //     .o_code_phase_delay_1(o_code_phase_delay_1_tmp),

    //     .o_corr_result_2(o_corr_result_2_tmp),
    //     .o_doppler_shift_2(o_doppler_shift_2_tmp),
    //     .o_prn_id_2(o_prn_id_2_tmp),
    //     .o_code_phase_delay_2(o_code_phase_delay_2_tmp),

    //     .o_corr_result_3(o_corr_result_3_tmp),
    //     .o_doppler_shift_3(o_doppler_shift_3_tmp),
    //     .o_prn_id_3(o_prn_id_3_tmp),
    //     .o_code_phase_delay_3(o_code_phase_delay_3_tmp)
    // );

    // always @(posedge clk) begin
    //     o_corr_result_0 <= o_corr_result_0_tmp;
    //     o_doppler_shift_0 <= o_doppler_shift_0_tmp;
    //     o_prn_id_0 <= o_prn_id_0_tmp;
    //     o_code_phase_delay_0 <= o_code_phase_delay_0_tmp;

    //     o_corr_result_1 <= o_corr_result_1_tmp;
    //     o_doppler_shift_1 <= o_doppler_shift_1_tmp;
    //     o_prn_id_1 <= o_prn_id_1_tmp;
    //     o_code_phase_delay_1 <= o_code_phase_delay_1_tmp;

    //     o_corr_result_2 <= o_corr_result_2_tmp;
    //     o_doppler_shift_2 <= o_doppler_shift_2_tmp;
    //     o_prn_id_2 <= o_prn_id_2_tmp;
    //     o_code_phase_delay_2 <= o_code_phase_delay_2_tmp;

    //     o_corr_result_3 <= o_corr_result_3_tmp;
    //     o_doppler_shift_3 <= o_doppler_shift_3_tmp;
    //     o_prn_id_3 <= o_prn_id_3_tmp;
    //     o_code_phase_delay_3 <= o_code_phase_delay_3_tmp;
    // end

    // reg [1:0]   o_cnt;
    // reg o_vld_tmp;
    // reg flag_2;
    // always @(posedge clk, negedge rst_n) begin
    //     if(~rst_n) begin
    //         o_vld_tmp <= 'b0;
    //         flag_2 <= 'b0;
    //     end
    //     else begin
    //         if(~o_vld_tmp && ~flag_2) begin
    //             if(pick_vld_tmp) begin
    //                 flag_2 <= 'b1;
    //                 o_vld_tmp <= 'b1;
    //             end
    //         end
    //         else begin
    //             if(&o_cnt) begin
    //                 o_vld_tmp <= 'b0;
    //             end
    //         end
    //     end
    // end
    // always @(posedge clk, negedge rst_n) begin
    //     if(~rst_n) begin
    //         o_cnt <= 'b0;
    //     end
    //     else begin
    //         if(o_vld) o_cnt <= o_cnt + 'b1;
    //     end
    // end

    // assign o_vld = o_vld_tmp;
    // reg signed  [15:0]          o_corr_result_tmp;
    // reg signed  [14:0]          o_doppler_shift_tmp;
    // reg [11:0]                  o_code_phase_delay_tmp;
    // reg [4:0]                   o_prn_id_tmp;
    // always @* begin
    //     case(o_cnt)
    //         2'b00:
    //             begin
    //                 o_corr_result_tmp = o_corr_result_0;
    //                 o_doppler_shift_tmp = o_doppler_shift_0;
    //                 o_code_phase_delay_tmp = o_code_phase_delay_0;
    //                 o_prn_id_tmp = o_prn_id_0;
    //             end

    //         2'b01:
    //             begin
    //                 o_corr_result_tmp = o_corr_result_1;
    //                 o_doppler_shift_tmp = o_doppler_shift_1;
    //                 o_code_phase_delay_tmp = o_code_phase_delay_1;
    //                 o_prn_id_tmp = o_prn_id_1;
    //             end

    //         2'b10:
    //             begin
    //                 o_corr_result_tmp = o_corr_result_2;
    //                 o_doppler_shift_tmp = o_doppler_shift_2;
    //                 o_code_phase_delay_tmp = o_code_phase_delay_2;
    //                 o_prn_id_tmp = o_prn_id_2;
    //             end

    //         2'b11:
    //             begin
    //                 o_corr_result_tmp = o_corr_result_3;
    //                 o_doppler_shift_tmp = o_doppler_shift_3;
    //                 o_code_phase_delay_tmp = o_code_phase_delay_3;
    //                 o_prn_id_tmp = o_prn_id_3;
    //             end

    //         default:
    //             begin
    //                 o_corr_result_tmp = 'b0;
    //                 o_doppler_shift_tmp = 'b0;
    //                 o_code_phase_delay_tmp = 'b0;
    //                 o_prn_id_tmp = 'b0;
    //             end
    //     endcase
    // end
    // assign o_corr_result = o_corr_result_tmp;
    // assign o_doppler_shift = o_doppler_shift_tmp;
    // assign o_code_phase_delay = o_code_phase_delay_tmp;
    // assign o_prn_id = o_prn_id_tmp;
endmodule