module top;
    logic[31 : 0] IQ_OUT_tdata;
    logic[3 : 0] IQ_OUT_tkeep;
    logic IQ_OUT_tready;
    logic IQ_OUT_tvalid;
    logic[31 : 0] M_AXI_0_araddr;
    logic[2 : 0] M_AXI_0_arprot;
    logic M_AXI_0_arready;
    logic M_AXI_0_arvalid;
    logic[31 : 0] M_AXI_0_awaddr;
    logic[2 : 0] M_AXI_0_awprot;
    logic M_AXI_0_awready;
    logic M_AXI_0_awvalid;
    logic M_AXI_0_bready;
    logic[1 : 0] M_AXI_0_bresp;
    logic M_AXI_0_bvalid;
    logic[31 : 0] M_AXI_0_rdata;
    logic M_AXI_0_rready;
    logic[1 : 0] M_AXI_0_rresp;
    logic M_AXI_0_rvalid;
    logic[31 : 0] M_AXI_0_wdata;
    logic M_AXI_0_wready;
    logic[3 : 0] M_AXI_0_wstrb;
    logic M_AXI_0_wvalid;
    logic[7 : 0] NAV_IN_tdata;
    logic NAV_IN_tready;
    logic NAV_IN_tvalid;
    logic[0 : 0] aresetn_o;
    logic clk50_o;

    logic signed[15 : 0] s_axis_gps_i;
    logic signed[15 : 0] s_axis_gps_q;

    design_1_wrapper design_1_wrapper_inst (
        .IQ_OUT_tdata(IQ_OUT_tdata),
        .IQ_OUT_tkeep(IQ_OUT_tkeep),
        .IQ_OUT_tready(IQ_OUT_tready),
        .IQ_OUT_tvalid(IQ_OUT_tvalid),
        .M_AXI_0_araddr(M_AXI_0_araddr),
        .M_AXI_0_arprot(M_AXI_0_arprot),
        .M_AXI_0_arready(M_AXI_0_arready),
        .M_AXI_0_arvalid(M_AXI_0_arvalid),
        .M_AXI_0_awaddr(M_AXI_0_awaddr),
        .M_AXI_0_awprot(M_AXI_0_awprot),
        .M_AXI_0_awready(M_AXI_0_awready),
        .M_AXI_0_awvalid(M_AXI_0_awvalid),
        .M_AXI_0_bready(M_AXI_0_bready),
        .M_AXI_0_bresp(M_AXI_0_bresp),
        .M_AXI_0_bvalid(M_AXI_0_bvalid),
        .M_AXI_0_rdata(M_AXI_0_rdata),
        .M_AXI_0_rready(M_AXI_0_rready),
        .M_AXI_0_rresp(M_AXI_0_rresp),
        .M_AXI_0_rvalid(M_AXI_0_rvalid),
        .M_AXI_0_wdata(M_AXI_0_wdata),
        .M_AXI_0_wready(M_AXI_0_wready),
        .M_AXI_0_wstrb(M_AXI_0_wstrb),
        .M_AXI_0_wvalid(M_AXI_0_wvalid),
        .NAV_IN_tdata(NAV_IN_tdata),
        .NAV_IN_tready(NAV_IN_tready),
        .NAV_IN_tvalid(NAV_IN_tvalid),
        .aresetn_o(aresetn_o),
        .clk50_o(clk50_o)
    );

    assign s_axis_gps_i = IQ_OUT_tdata[31 : 16];
    assign s_axis_gps_q = IQ_OUT_tdata[15 : 0];

    gps_top #(
        .axil_addr_width(10),
        .axil_data_width(32),
        .num_trackers(4),
        .ACC_WIDTH(32)
    ) gps_top_inst(
        .clk(clk50_o),
        .rst_n(aresetn_o),

        .s_axis_tvalid(IQ_OUT_tvalid),
        .s_axis_gps_i(s_axis_gps_i),
        .s_axis_gps_q(s_axis_gps_q),
        .s_axis_tready(IQ_OUT_tready),

        .s_axil_awaddr(M_AXI_0_awaddr[9 : 0]),
        .s_axil_awvalid(M_AXI_0_awvalid),
        .s_axil_awready(M_AXI_0_awready),
        .s_axil_wdata(M_AXI_0_wdata),
        .s_axil_wstrb(M_AXI_0_wstrb),
        .s_axil_wvalid(M_AXI_0_wvalid),
        .s_axil_wready(M_AXI_0_wready),
        .s_axil_bresp(M_AXI_0_bresp),
        .s_axil_bvalid(M_AXI_0_bvalid),
        .s_axil_bready(M_AXI_0_bready),
        .s_axil_araddr(M_AXI_0_araddr[9 : 0]),
        .s_axil_arvalid(M_AXI_0_arvalid),
        .s_axil_arready(M_AXI_0_arready),
        .s_axil_rdata(M_AXI_0_rdata),
        .s_axil_rresp(M_AXI_0_rresp),
        .s_axil_rvalid(M_AXI_0_rvalid),
        .s_axil_rready(M_AXI_0_rready),

        .nav_tdata(NAV_IN_tdata),
        .nav_tvalid(NAV_IN_tvalid)
    );
endmodule
