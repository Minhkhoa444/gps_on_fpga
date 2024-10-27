module eth_udp_top #(
    parameter fifo_depth = 1024,
    parameter transmit_threshold = 0.75,
    parameter ipg_length = 12,

    parameter src_mac = 48'h01_23_45_67_89_0A,
    parameter src_ip = 32'hC0_A8_00_2C,
    parameter src_port = 16'd1024,
    parameter dest_mac = 48'h00_D8_61_05_97_0F,
    parameter dest_ip = 32'hC0_A8_00_04,
    parameter dest_port = 16'd1024
) (
    input                                   clk50_i,
    input                                   rst_i,
    
    //  TX interface
    input[7 : 0]                            s_axis_tdata,
    input                                   s_axis_tvalid,
    output                                  s_axis_tready,

    //  RX interface
    output[7 : 0]                           m_axis_tdata,
    output                                  m_axis_tvalid,
    input                                   m_axis_tready,

    //  RMII
    output[1 : 0]                           txd_o,
    output                                  txen_o,

    input[1 : 0]                            rxd_i,
    input                                   crs_dv_i
);

    wire[7 : 0] udp_data_tx_w;
    wire[7 : 0] udp_data_rx_w;
    wire udp_valid_tx_w;
    wire udp_valid_rx_w;

    //  TX section
    eth_udp_tx #(
        .fifo_depth(fifo_depth),
        .transmit_threshold(transmit_threshold),
        .ipg_length(ipg_length),

        .src_mac(src_mac),
        .src_ip(src_ip),
        .src_port(src_port),
        .dest_mac(dest_mac),
        .dest_ip(dest_ip),
        .dest_port(dest_port)
    ) u_eth_udp_tx(
        .aclk(clk50_i),
        .rst_i(rst_i),

        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),

        .udp_data_o(udp_data_tx_w),
        .udp_valid_o(udp_valid_tx_w)
    );

    eth_tx u_eth_tx(
        .clk50_i(clk50_i),
        .rst_i(rst_i),

        .data_in_i(udp_data_tx_w),
        .tx_valid_i(udp_valid_tx_w),

        .txd_o(txd_o),
        .txen_o(txen_o)
    );

    //  RX section
    eth_rx u_eth_rx(
        .clk50_i(clk50_i),
        .rst_i(rst_i),

        .data_out_o(udp_data_rx_w),
        .rx_valid_o(udp_valid_rx_w),

        .rxd_i(rxd_i),
        .crs_dv_i(crs_dv_i)
    );
endmodule
