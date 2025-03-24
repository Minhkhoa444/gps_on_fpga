module top_acqusition_wrapper;
    logic[63 : 0] acq_in_tdata;
    logic acq_in_tvalid;
    logic acq_in_tready;
    logic aresetn_o;
    logic clk50_o;
    logic iq_tdata[31 : 0];
    logic iq_tvalid;
    logic iq_tready;
    logic signed[15 : 0] acq_corr_result;
    logic signed[14 : 0] acq_doppler_shift;
    logic[4 : 0] acq_prn_id;
    logic[11 : 0] acq_code_phase_delay;

    assign acq_in_tdata = {
        acq_corr_result,
        {acq_doppler_shift[14], acq_doppler_shift},
        {11'b0, acq_prn_id},
        {4'b0, acq_code_phase_delay}
    };

    gps_acquisition_ps_design_wrapper block_design(
        .ACQ_IN_tdata(acq_in_tdata),
        .ACQ_IN_tready(acq_in_tready),
        .ACQ_IN_tvalid(acq_in_tvalid),
        .IQ_OUT_tdata(iq_tdata),
        .IQ_OUT_tkeep(),
        .IQ_OUT_tlast(),
        .IQ_OUT_tready(iq_tready),
        .IQ_OUT_tvalid(iq_tvalid),
        .aresetn_o(aresetn_o),
        .clk50_o(clk50_o)
    );

    gps_acquisition_wrapper acquisition_wrapper(
        .clk(clk50_o),
        .rst_n(aresetn_o),
        .s_axis_tvalid(iq_tvalid),
        .s_axis_tdata_i(iq_tdata[31 : 16]),
        .s_axis_tdata_q(iq_tdata[15 : 0]),
        .s_axis_tready(iq_tready),

        .o_vld(acq_in_tvalid),
        .o_corr_result(acq_corr_result),
        .o_doppler_shift(acq_doppler_shift),
        .o_code_phase_delay(acq_code_phase_delay),
        .o_prn_id(acq_prn_id)
    );
endmodule
