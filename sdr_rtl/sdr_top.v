module sdr_top #(
    parameter adc_resolution = 12,
    parameter lo_freq = 50000000,
    parameter baud_rate = 192000    //  12 ksps max
) (
    input[adc_resolution - 1 : 0]           adc_i,
    input                                   clk50_i,
    input                                   rst_i,
    
    //  UART
    output                                  tx_o,
    output                                  rx_o,

    //  RMII
    output                                  mdc_o,
    output                                  mdio_o,
    output                                  txd0_o,
    output                                  txd1_o,
    output                                  rxd0_o,
    output                                  rxd1_o,
    output                                  tx_en_o,
    output                                  retclk_o,
    output                                  crs_o
);

    /*
    Format used:
    12 bit resolution -> 16 bit fixed point normalized (1 sign bit + 15 decimal or Q1.15)

    Example:
    raw_adc_val run from 0 to 4095
    raw_adc_val = 3010 => normalized to adc_val = 3000 / 4096 = 0.7324 => 3000 / 2^12 * 2^15 = 3000 * 2^3

    => adc_val = raw_adc_val << (decimal_width - adc_resolution)

    */

    localparam fixed_point_width = 16;
    localparam cic_filter_orders = 5;
    localparam decimation_rate = 5000;  //  decimate from 50 MSPS to 10 kSPS
    localparam fir_filter_orders = 30;

    wire[fixed_point_width - 1 : 0] u_adc_m_axis_tdata_w;
    wire u_adc_m_axis_tvalid_w;
    wire u_adc_m_axis_tready_w;

    adc_to_axis #(
        .adc_resolution(adc_resolution),
        .data_width(fixed_point_width),  //  Must be greater than or equal adc_resolution
        .decimal_width(fixed_point_width - 1)
    ) u_adc (
        .aclk(clk50_i),
        .rst_i(rst_i),

        .adc_i(adc_i),

        .m_axis_tdata(u_adc_m_axis_tdata_w),
        .m_axis_tvalid(u_adc_m_axis_tvalid_w),
        .m_axis_tready(u_adc_m_axis_tready_w)
    );

    wire[fixed_point_width * 2 - 1 : 0] u_dc_m_axis_tdata_w;
    wire u_dc_m_axis_tvalid_w;
    wire u_dc_m_axis_tready_w;

    down_converter #(
        .data_width(fixed_point_width),
        .frequency(lo_freq)
    ) u_dc (
        .aclk(clk50_i),
        .rst_i(rst_i),

        .s_axis_tdata(u_adc_m_axis_tdata_w),
        .s_axis_tvalid(u_adc_m_axis_tvalid_w),
        .s_axis_tready(u_adc_m_axis_tready_w),

        .m_axis_tdata(u_dc_m_axis_tdata_w),
        .m_axis_tvalid(u_dc_m_axis_tvalid_w),
        .m_axis_tready(u_dc_m_axis_tready_w)
    );

    wire[fixed_point_width - 1 : 0] u_cic0_m_axis_tdata_w;
    wire u_cic0_m_axis_tvalid_w;
    wire u_cic0_m_axis_tready_w;
    wire u_cic0_decimated_clk_w;

    cic_filter #(
        .data_width(fixed_point_width),
        .filter_R(decimation_rate),
        .filter_N(cic_filter_orders)
    ) u_cic0 (
        .aclk(clk50_i),
        .rst_i(rst_i),
        
        .s_axis_tdata(u_dc_m_axis_tdata_w[fixed_point_width * 2 - 1 : fixed_point_width]),
        .s_axis_tvalid(u_dc_m_axis_tvalid_w),
        .s_axis_tready(u_dc_m_axis_tready_w),

        .m_axis_tdata(u_cic0_m_axis_tdata_w),
        .m_axis_tvalid(u_cic0_m_axis_tvalid_w),
        .m_axis_tready(u_cic0_m_axis_tready_w),

        .decimated_clk_o(u_cic0_decimated_clk_w)
    );

    wire[fixed_point_width - 1 : 0] u_cic1_m_axis_tdata_w;
    wire u_cic1_m_axis_tvalid_w;
    wire u_cic1_m_axis_tready_w;
    wire u_cic1_decimated_clk_w;

    cic_filter #(
        .data_width(fixed_point_width),
        .filter_R(decimation_rate),
        .filter_N(cic_filter_orders)
    ) u_cic1 (
        .aclk(clk50_i),
        .rst_i(rst_i),
        
        .s_axis_tdata(u_dc_m_axis_tdata_w[fixed_point_width - 1 : 0]),
        .s_axis_tvalid(u_dc_m_axis_tvalid_w),
        .s_axis_tready(),

        .m_axis_tdata(u_cic1_m_axis_tdata_w),
        .m_axis_tvalid(u_cic1_m_axis_tvalid_w),
        .m_axis_tready(u_cic1_m_axis_tready_w),

        .decimated_clk_o(u_cic1_decimated_clk_w)
    );

    wire[fixed_point_width - 1 : 0] u_fir0_m_axis_tdata_w;
    wire u_fir0_m_axis_tvalid_w;
    wire u_fir0_m_axis_tready_w;

    fir_filter #(
        .data_width(fixed_point_width),
        .coeff_width(fixed_point_width),
        .filter_N(fir_filter_orders),
        .coeff_file("coefflut.mem")
    ) u_fir0 (
        .aclk(clk50_i),
        .rst_i(rst_i),

        .s_axis_tdata(u_cic0_m_axis_tdata_w),
        .s_axis_tvalid(u_cic0_m_axis_tvalid_w),
        .s_axis_tready(u_cic0_m_axis_tready_w),

        .m_axis_tdata(u_fir0_m_axis_tdata_w),
        .m_axis_tvalid(u_fir0_m_axis_tvalid_w),
        .m_axis_tready(u_fir0_m_axis_tready_w)
    );

    wire[fixed_point_width - 1 : 0] u_fir1_m_axis_tdata_w;
    wire u_fir1_m_axis_tvalid_w;
    wire u_fir1_m_axis_tready_w;

    fir_filter #(
        .data_width(fixed_point_width),
        .coeff_width(fixed_point_width),
        .filter_N(fir_filter_orders),
        .coeff_file("coefflut.mem")
    ) u_fir1 (
        .aclk(clk50_i),
        .rst_i(rst_i),

        .s_axis_tdata(u_cic1_m_axis_tdata_w),
        .s_axis_tvalid(u_cic1_m_axis_tvalid_w),
        .s_axis_tready(u_cic1_m_axis_tready_w),

        .m_axis_tdata(u_fir1_m_axis_tdata_w),
        .m_axis_tvalid(u_fir1_m_axis_tvalid_w),
        .m_axis_tready(u_fir1_m_axis_tready_w)
    );
    assign tx_o = 1'b1;
    assign rx_o = 1'b1;

    assign mdc_o = 1'b0; 
    assign mdio_o = 1'b0; 
    assign txd0_o = 1'b0; 
    assign txd1_o = 1'b0; 
    assign rxd0_o = 1'b0; 
    assign rxd1_o = 1'b0;
    assign tx_en_o = 1'b0;
    assign retclk_o = 1'b0;
    assign crs_o = 1'b0;
endmodule
