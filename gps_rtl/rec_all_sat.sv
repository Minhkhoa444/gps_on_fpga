`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/24/2025 03:29:34 PM
// Design Name: 
// Module Name: rec_all_sat
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
// `define VERIFICATION
// `define WRAPPER_SV
module rec_all_sat(
    input   logic   clk,
    input   logic   rst_n,

    input   logic   i_vld,
    input   logic   signed  [15:0]  i_corr_result,
    input   logic   [4:0]   i_prn_id,
    input   logic   signed  [14:0]  i_doppler_shift,
    input   logic   [11:0]  i_code_phase_delay,

    // `ifdef WRAPPER_SV
    //     // output  logic   [1:0]   o_cnt,
    //     output  logic   o_acq_done,
    // `endif

    output  logic   o_vld,
    output  logic   signed  [14:0]  o_doppler_shift,
    output  logic   [11:0]          o_code_phase_delay,
    output  logic   [4:0]           o_prn_id
);
    logic   acq_done;
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            acq_done <= 'b0;
        end
        else begin
            if(i_doppler_shift==-10000 && &i_prn_id && &i_code_phase_delay && i_vld) begin
            // if(i_doppler_shift==-2500 && &i_prn_id && &i_code_phase_delay && i_vld) begin
                acq_done <= 'b1;
            end
        end
    end
    // assign  o_acq_done = acq_done;

    logic   signed  [15:0]  corr_result         [0:31];
    logic   signed  [14:0]  doppler_shift       [0:31];
    logic   [11:0]          code_phase_delay    [0:31];

    integer i;

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            for(i=0; i<32; i=i+1) begin
                corr_result[i] <= 'b0;
            end
        end
        else begin
            if(i_vld) begin
                if(i_corr_result > corr_result[i_prn_id]) begin
                    corr_result[i_prn_id] <= i_corr_result;
                    doppler_shift[i_prn_id] <= i_doppler_shift;
                    code_phase_delay[i_prn_id] <= i_code_phase_delay;
                end
            end
        end
    end

    logic   top_4_i_vld;
    logic   [4:0]   cnt;
    logic   flag_top_4_i_vld;
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            top_4_i_vld <= 'b0;
            flag_top_4_i_vld <= 'b0;
        end
        else begin
            if(~top_4_i_vld && ~flag_top_4_i_vld) begin
                if(acq_done) begin
                    top_4_i_vld <= 'b1;
                    flag_top_4_i_vld <= 'b1;
                end
            end
            else begin
                if(&cnt) begin
                    top_4_i_vld <= 'b0;
                end
            end
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            cnt <= 'b0;
        end
        else begin
            if(top_4_i_vld) cnt <= cnt + 'b1;
        end
    end

    logic   top_4_o_vld;
    logic   signed  [15:0]  o_corr_result_0_tmp;
    logic   signed  [14:0]  o_doppler_shift_0_tmp;
    logic   [4:0]           o_prn_id_0_tmp;
    logic   [11:0]          o_code_phase_delay_0_tmp;

    logic   signed  [15:0]  o_corr_result_1_tmp;
    logic   signed  [14:0]  o_doppler_shift_1_tmp;
    logic   [4:0]           o_prn_id_1_tmp;
    logic   [11:0]          o_code_phase_delay_1_tmp;

    logic   signed  [15:0]  o_corr_result_2_tmp;
    logic   signed  [14:0]  o_doppler_shift_2_tmp;
    logic   [4:0]           o_prn_id_2_tmp;
    logic   [11:0]          o_code_phase_delay_2_tmp;

    logic   signed  [15:0]  o_corr_result_3_tmp;
    logic   signed  [14:0]  o_doppler_shift_3_tmp;
    logic   [4:0]           o_prn_id_3_tmp;
    logic   [11:0]          o_code_phase_delay_3_tmp;

    logic   signed  [15:0]  o_corr_result_0;
    logic   signed  [14:0]  o_doppler_shift_0;
    logic   [4:0]           o_prn_id_0;
    logic   [11:0]          o_code_phase_delay_0;

    logic   signed  [15:0]  o_corr_result_1;
    logic   signed  [14:0]  o_doppler_shift_1;
    logic   [4:0]           o_prn_id_1;
    logic   [11:0]          o_code_phase_delay_1;

    logic   signed  [15:0]  o_corr_result_2;
    logic   signed  [14:0]  o_doppler_shift_2;
    logic   [4:0]           o_prn_id_2;
    logic   [11:0]          o_code_phase_delay_2;

    logic   signed  [15:0]  o_corr_result_3;
    logic   signed  [14:0]  o_doppler_shift_3;
    logic   [4:0]           o_prn_id_3;
    logic   [11:0]          o_code_phase_delay_3;

    pick_top_4 pick(
        .clk(clk),
        .rst_n(rst_n),

        .i_vld(top_4_i_vld),
        .i_corr_result(corr_result[cnt]),
        .i_doppler_shift(doppler_shift[cnt]),
        .i_prn_id(cnt),
        .i_code_phase_delay(code_phase_delay[cnt]),

        .o_vld(top_4_o_vld),
        .o_corr_result_0(o_corr_result_0_tmp),
        .o_doppler_shift_0(o_doppler_shift_0_tmp),
        .o_prn_id_0(o_prn_id_0_tmp),
        .o_code_phase_delay_0(o_code_phase_delay_0_tmp),

        .o_corr_result_1(o_corr_result_1_tmp),
        .o_doppler_shift_1(o_doppler_shift_1_tmp),
        .o_prn_id_1(o_prn_id_1_tmp),
        .o_code_phase_delay_1(o_code_phase_delay_1_tmp),

        .o_corr_result_2(o_corr_result_2_tmp),
        .o_doppler_shift_2(o_doppler_shift_2_tmp),
        .o_prn_id_2(o_prn_id_2_tmp),
        .o_code_phase_delay_2(o_code_phase_delay_2_tmp),

        .o_corr_result_3(o_corr_result_3_tmp),
        .o_doppler_shift_3(o_doppler_shift_3_tmp),
        .o_prn_id_3(o_prn_id_3_tmp),
        .o_code_phase_delay_3(o_code_phase_delay_3_tmp)
    );

    always_ff @(posedge clk) begin
        if(top_4_o_vld) begin
            o_corr_result_0 <= o_corr_result_0_tmp;
            o_doppler_shift_0 <= o_doppler_shift_0_tmp;
            o_prn_id_0 <= o_prn_id_0_tmp;
            o_code_phase_delay_0 <= o_code_phase_delay_0_tmp;

            o_corr_result_1 <= o_corr_result_1_tmp;
            o_doppler_shift_1 <= o_doppler_shift_1_tmp;
            o_prn_id_1 <= o_prn_id_1_tmp;
            o_code_phase_delay_1 <= o_code_phase_delay_1_tmp;

            o_corr_result_2 <= o_corr_result_2_tmp;
            o_doppler_shift_2 <= o_doppler_shift_2_tmp;
            o_prn_id_2 <= o_prn_id_2_tmp;
            o_code_phase_delay_2 <= o_code_phase_delay_2_tmp;

            o_corr_result_3 <= o_corr_result_3_tmp;
            o_doppler_shift_3 <= o_doppler_shift_3_tmp;
            o_prn_id_3 <= o_prn_id_3_tmp;
            o_code_phase_delay_3 <= o_code_phase_delay_3_tmp;
        end
    end

    // `ifndef WRAPPER_SV
        logic   [1:0]   o_cnt;
    // `endif
    logic   o_vld_tmp;
    logic   flag_top_4_o_vld;
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            o_vld_tmp <= 'b0;
            flag_top_4_o_vld <= 'b0;
        end
        else begin
            if(~o_vld_tmp && ~flag_top_4_o_vld) begin
                if(top_4_o_vld) begin
                    flag_top_4_o_vld <= 'b1;
                    o_vld_tmp <= 'b1;
                end
            end
            else begin
                if(&o_cnt) begin
                    o_vld_tmp <= 'b0;
                end
            end
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            o_cnt <= 'b0;
        end
        else begin
            if(o_vld_tmp) o_cnt <= o_cnt + 'b1;
        end
    end

    logic   signed  [15:0]  o_corr_result_tmp;
    logic   signed  [14:0]  o_doppler_shift_tmp;
    logic   [11:0]          o_code_phase_delay_tmp;
    logic   [4:0]           o_prn_id_tmp;
    always @* begin
        case(o_cnt)
            2'b00:
                begin
                    o_corr_result_tmp = o_corr_result_0;
                    o_doppler_shift_tmp = o_doppler_shift_0;
                    o_code_phase_delay_tmp = o_code_phase_delay_0;
                    o_prn_id_tmp = o_prn_id_0;
                end

            2'b01:
                begin
                    o_corr_result_tmp = o_corr_result_1;
                    o_doppler_shift_tmp = o_doppler_shift_1;
                    o_code_phase_delay_tmp = o_code_phase_delay_1;
                    o_prn_id_tmp = o_prn_id_1;
                end

            2'b10:
                begin
                    o_corr_result_tmp = o_corr_result_2;
                    o_doppler_shift_tmp = o_doppler_shift_2;
                    o_code_phase_delay_tmp = o_code_phase_delay_2;
                    o_prn_id_tmp = o_prn_id_2;
                end

            2'b11:
                begin
                    o_corr_result_tmp = o_corr_result_3;
                    o_doppler_shift_tmp = o_doppler_shift_3;
                    o_code_phase_delay_tmp = o_code_phase_delay_3;
                    o_prn_id_tmp = o_prn_id_3;
                end

            default:
                begin
                    o_corr_result_tmp = 'b0;
                    o_doppler_shift_tmp = 'b0;
                    o_code_phase_delay_tmp = 'b0;
                    o_prn_id_tmp = 'b0;
                end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            o_vld <= 'b0;
        end
        else begin
            o_vld <= o_vld_tmp;
            o_doppler_shift <= o_doppler_shift_tmp;
            o_code_phase_delay <= o_code_phase_delay_tmp;
            o_prn_id <= o_prn_id_tmp;
        end
    end
endmodule
