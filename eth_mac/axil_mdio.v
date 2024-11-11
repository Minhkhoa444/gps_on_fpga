module axil_mdio #(
    parameter axil_addr_width = 32,
    parameter axil_data_width = 32
) (
    input                                   aclk,
    input                                   aresetn,

    //  AW channel
    input[axil_addr_width - 1 : 0]          s_axil_awaddr,
    input                                   s_axil_awvalid,
    output                                  s_axil_awready,
    
    //  W channel
    input[axil_data_width - 1 : 0]          s_axil_wdata,
    input[axil_data_width / 8 - 1 : 0]      s_axil_wstrb,
    input                                   s_axil_wvalid,
    output                                  s_axil_wready,

    //  B channel
    output[1 : 0]                           s_axil_bresp,
    output                                  s_axil_bvalid,
    input                                   s_axil_bready,

    //  AR channel
    input[axil_addr_width - 1 : 0]          s_axil_araddr,
    input                                   s_axil_arvalid,
    output                                  s_axil_arready,

    //  R channel
    output[axil_data_width - 1 : 0]         s_axil_rdata,
    output[1 : 0]                           s_axil_rresp,
    output                                  s_axil_rvalid,
    input                                   s_axil_rready,

    //  MDIO
    output                                  mdc_o,
    output                                  mdio_o,
    input                                   mdio_i,
    output                                  mdio_oe_o,

    output                                  mdio_interrupt_o
);
    localparam addr_lsb = $clog2(axil_data_width) - 3;

    reg s_axil_awready_r;
    reg s_axil_bvalid_r;
    reg[axil_data_width - 1 : 0] s_axil_rdata_r;
    reg s_axil_rvalid_r;

    reg mdc_r;
    reg[1 : 0] opcode_r;
    reg[4 : 0] phy_addr_r;
    reg[4 : 0] reg_addr_r;
    reg[15 : 0] wreg_data_r;
    reg[15 : 0] rreg_data_r;

    reg[axil_data_width - 1 : 0] mdio_ip_ver_r;         //  0x04
    reg[axil_data_width - 1 : 0] mdio_clk_prescaler_r;  //  0x08
    reg[axil_data_width - 1 : 0] mdio_cfg_r;            //  0x0A
    reg[axil_data_width - 1 : 0] mdio_addr_cfg_r;       //  0x10
    reg[axil_data_width - 1 : 0] mdio_phy_data_r;       //  0x14
    reg[axil_data_width - 1 : 0] mdio_status_r;         //  0x18

    function[axil_data_width - 1 : 0] wstrb_func;
        input[axil_data_width - 1 : 0] old_wdata;
        input[axil_data_width - 1 : 0] new_wdata;
        input[axil_data_width / 8 - 1 : 0] wstrb;

        integer i;
        for(i = 0; i < axil_data_width / 8; i = i + 1) begin
            wstrb_func[i * 8 + 7 : i * 8] = wstrb[i] ? new_wdata[i * 8 + 7 : i * 8] : old_wdata[i * 8 + 7 : i * 8];
        end
    endfunction

    always @(posedge aclk) begin
        if(!aresetn) begin
            s_axil_awready_r <= 1'h0;
        end
        else begin
            s_axil_awready_r <= !s_axil_awready_r && (s_axil_awvalid && s_axil_wvalid) && (!s_axil_bvalid || s_axil_bready);
        end
    end

    always @(posedge aclk) begin
        if(!aresetn) begin
            s_axil_bvalid_r <= 1'h0;
        end
        else begin
            if(s_axil_awready) begin
                s_axil_bvalid_r <= 1'h1;
            end
            else if(s_axil_bready) begin
                s_axil_bvalid_r <= 1'h0;
            end
        end
    end

    always @(posedge aclk) begin
        if(!aresetn) begin
            s_axil_rvalid_r <= 1'h0;
        end
        else begin
            if(s_axil_arvalid && s_axil_arready) begin
                s_axil_rvalid_r <= 1'h1;
            end
            else if(s_axil_rready) begin
                s_axil_rvalid_r <= 1'h0;
            end
        end
    end

    always @(posedge aclk) begin
        if(!aresetn) begin
            mdio_cfg_r <= 'h0;
            mdio_addr_cfg_r <= 'h0;
        end
        else begin
            if(s_axil_awready) begin
                case(s_axil_awaddr[axil_addr_width - 1 : addr_lsb])
                    'd1:
                    begin
                        mdio_ip_ver_r <= 32'h00_00_11_11;
                    end
                    'd2:
                    begin
                        mdio_cfg_r <= wstrb_func(mdio_cfg_r, s_axil_wdata, s_axil_wstrb);
                    end
                    'd3:
                    begin
                        mdio_cfg_r <= 'h0;
                    end
                    'd4:
                    begin
                        mdio_cfg_r <= 'h0;
                    end
                    'd5:
                    begin
                        mdio_cfg_r <= 'h0;
                    end
                endcase
            end
        end
    end

    always @(posedge aclk) begin
        if(!aresetn) begin
            s_axil_rdata_r <= 'h0;
        end
        else begin
            if(!s_axil_rvalid || s_axil_rready) begin
                case(s_axil_araddr[axil_addr_width - 1 : addr_lsb])
                    'd1:
                    begin
                        s_axil_rdata_r <= mdio_ip_ver_r;
                    end
                    'd2:
                    begin
                        s_axil_rdata_r <= mdio_cfg_r;
                    end
                    'd3:
                    begin
                        s_axil_rdata_r <= 'h0;
                    end
                    'd4:
                    begin
                        s_axil_rdata_r <= 'h0;
                    end
                    'd5:
                    begin
                        s_axil_rdata_r <= 'h0;
                    end
                endcase
            end
        end
    end

    //  mdc generator
    always @(posedge aclk) begin
        if(!aresetn) begin

        end
        else begin

        end
    end


    mdio u_mdio(
        .clk_i(aclk),
        .rst_i(~aresetn),

        .mdc_i(mdc_r),
        .mdio_i(mdio_i),
        .mdio_o(mdio_o),
        .mdio_oe_o(mdio_oe_o),

        .opcode_i(opcode_r),
        .phy_addr_i(phy_addr_r),
        .reg_addr_i(reg_addr_r),

        .wreg_data_i(wreg_data_r),
        .rreg_data_o(rreg_data_r)
    );

    assign mdc_o = mdc_r;

    assign s_axil_awready = s_axil_awready_r;
    assign s_axil_wready = s_axil_awready_r;
    assign s_axil_bresp = 2'b00;
    assign s_axil_bvalid = s_axil_bvalid_r;
    assign s_axil_arready = !s_axil_rvalid_r;
    assign s_axil_rdata = s_axil_rdata_r;
    assign s_axil_rresp = 2'b00;
    assign s_axil_rvalid = s_axil_rvalid_r;
endmodule
