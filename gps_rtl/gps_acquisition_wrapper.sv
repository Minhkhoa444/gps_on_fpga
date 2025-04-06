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
module gps_acquisition_wrapper(
    input   logic   clk,
    input   logic   rst_n,

    `ifdef WRAPPER_SV
        input   logic           tracker_i_vld,
        input   logic   [11:0]  early_code_addr [0:3],
        input   logic   [11:0]  prompt_code_addr[0:3],
        input   logic   [11:0]  late_code_addr  [0:3],

        output  logic           tracker_o_vld,
        output  logic   signed  [15:0]  early_code  [0:3],
        output  logic   signed  [15:0]  prompt_code [0:3],
        output  logic   signed  [15:0]  late_code   [0:3],
    `endif

    input   logic                   s_axis_tvalid,      // tvalid
    input   logic   signed  [15:0]  s_axis_tdata_i,     // gps_i
    input   logic   signed  [15:0]  s_axis_tdata_q,     // gps_q
    output  logic                   s_axis_tready,      // tready

    output  logic                   o_vld,
    output  logic   signed  [15:0]  o_corr_result,
    output  logic   signed  [14:0]  o_doppler_shift,
    output  logic           [11:0]  o_code_phase_delay,
    output  logic           [4:0]   o_prn_id
);

    logic   acq_o_vld;
    logic   signed  [15:0]  acq_corr_result;
    logic   signed  [14:0]  acq_doppler_shift;
    logic   [4:0]           acq_prn_id;
    logic   [11:0]          acq_code_phase_delay;

    logic   signed  [DAT_WIDTH-1:0] ca_o_data   [0:31];
    logic   [11:0]  ca_rdaddr_fr_acq;
    logic   [11:0]  precomputed_ca_rdaddr;
    logic   acq_done;

    `ifdef WRAPPER_SV
        logic   [1:0]   cnt_top_4_id;
        logic   [4:0]   top_4_id    [0:3];
        logic   top_4_vld   [0:3];
        integer i,k;
        logic   [11:0]  rdaddr;
        logic   rd_vld;
        logic   tracker_bram_done;
        logic   [11:0]  wraddr;
        logic   wr_vld;
        logic   [15:0]  bram_early_code[0:3][0:4095];
        logic   [15:0]  bram_prompt_code[0:3][0:4095];
        logic   [15:0]  bram_late_code[0:3][0:4095];
        integer j;
    `endif

    always_comb begin
        if(~acq_done) begin
            precomputed_ca_rdaddr = ca_rdaddr_fr_acq;
        end
        else begin
            precomputed_ca_rdaddr = rdaddr;
        end
        // else if(~tracker_bram_done) begin
        //     precomputed_ca_rdaddr = rdaddr;
        // end
        // else begin
        //     precomputed_ca_rdaddr = early_code_addr[0];
        // end
    end

    precomputed_ca ca (
        .clk(clk),
    
        .i_rdaddr(precomputed_ca_rdaddr),
        .o_data(ca_o_data)
    );

    gps_acquisition acq(
        .clk(clk),
        .rst_n(rst_n),

        // input data from precomputed_ca
        .ca_o_data(ca_o_data),
        .precomputed_ca_rdaddr(ca_rdaddr_fr_acq),

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

        `ifdef WRAPPER_SV
            .o_cnt(cnt_top_4_id),
        `endif

        .o_acq_done(acq_done),

        .o_vld(o_vld),
        .o_corr_result(o_corr_result),
        .o_doppler_shift(o_doppler_shift),
        .o_code_phase_delay(o_code_phase_delay),
        .o_prn_id(o_prn_id)
    );

    `ifdef WRAPPER_SV
        always_ff @(posedge clk) begin
            if(o_vld) begin
                top_4_id[cnt_top_4_id] <= o_prn_id;
            end
        end
        always_ff @(posedge clk, negedge rst_n) begin
            if(~rst_n) begin
                for(k=0; k<4; k++) begin
                    top_4_vld[k] <= 'b0;
                end
            end
            else begin
                top_4_vld[0] <= o_vld;
                for(i=1;i<4; i++) begin
                    top_4_vld[i] <= top_4_vld[i-1];
                end
            end
        end

        always_ff @(posedge clk, negedge rst_n) begin
            if(~rst_n) begin
                rdaddr <= 'b0;
                rd_vld <= 'b0;
            end
            else begin
                if(~(|rdaddr[11:0])) begin
                    rd_vld <= top_4_vld[3];
                end
                else begin
                    if(&rdaddr[11:0]) begin
                        rd_vld <= 'b0;
                    end
                end

                if(rd_vld) begin
                    rdaddr <= rdaddr + 1'b1;
                end
            end
        end

        always_ff @(posedge clk, negedge rst_n) begin
            if(~rst_n) begin
                wr_vld <= 'b0;
            end
            else begin
                wr_vld <= rd_vld;
            end
        end

        always_ff @(posedge clk, negedge rst_n) begin
            if(~rst_n) begin
                wraddr <= 'b0;
            end
            else begin
                if(wr_vld) begin
                    wraddr <= wraddr + 1'b1;
                end
            end
        end

        always_ff @(posedge clk, negedge rst_n) begin
            if(~rst_n) begin
                tracker_bram_done <= 'b0;
            end
            else begin
                if(&wraddr) begin
                    tracker_bram_done <= 'b1;
                end
            end
        end

        always_ff @(posedge clk) begin
            for(j=0; j<4; j++) begin
                if(wr_vld) begin
                    bram_early_code[j][wraddr] <= ca_o_data[top_4_id[j]];
                    bram_prompt_code[j][wraddr] <= ca_o_data[top_4_id[j]];
                    bram_late_code[j][wraddr] <= ca_o_data[top_4_id[j]];
                end
                
                early_code[j] <= bram_early_code[j][early_code_addr[j]];
                prompt_code[j] <= bram_prompt_code[j][prompt_code_addr[j]];
                late_code[j] <= bram_late_code[j][late_code_addr[j]];
            end
        end
    `endif
endmodule