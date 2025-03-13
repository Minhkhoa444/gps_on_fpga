module fir_decimator #(
    parameter data_width = 16,
    parameter fraction_width = 15,
    parameter coeff_width = 16,
    parameter filter_N = 20,
    parameter coeff_file = "../sdr_tb/fir_decimator_mem/coeff.mem",

    parameter decimation_rate = 4
) (
    input                                   aclk,
    input                                   rst_i,

    input signed[data_width - 1 : 0]        s_axis_tdata,
    input                                   s_axis_tvalid,
    output signed                           s_axis_tready,

    output signed[data_width - 1 : 0]       m_axis_tdata,
    output                                  m_axis_tvalid,
    input                                   m_axis_tready
);

    wire signed[data_width - 1 : 0] fir_m_axis_tdata;
    wire fir_m_axis_tvalid;       
    wire fir_s_axis_tready;
    wire dec_s_axis_tready; 

    fir_filter #(
        .data_width(data_width),
        .fraction_width(fraction_width),
        .coeff_width(coeff_width),
        .filter_N(filter_N),
        .coeff_file(coeff_file)   
    ) fir_dut (
        .aclk(aclk),
        .rst_i(rst_i),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(fir_m_axis_tdata),
        .m_axis_tvalid(fir_m_axis_tvalid),
        .m_axis_tready(dec_s_axis_tready)
    );

    decimator #(
        .data_width(data_width),
        .decimation_rate(decimation_rate)
    ) decimator_dut (
        .aclk(aclk),
        .rst_i(rst_i),
        .s_axis_tdata(fir_m_axis_tdata),
        .s_axis_tvalid(fir_m_axis_tvalid),
        .s_axis_tready(dec_s_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready)
    );

endmodule
