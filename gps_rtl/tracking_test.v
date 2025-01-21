`default_nettype none
module tracking_test#(
    parameter axil_addr_width = 10,
    parameter axil_data_width = 32,
    num_trackers = 8
) (
    input wire                               aclk,
    input wire                               aresetn,

    // AW channel
    input wire[axil_addr_width - 1 : 0]     s_axil_awaddr,
    input wire                              s_axil_awvalid,
    output wire                             s_axil_awready,

    // W channel
    input wire[axil_data_width - 1 : 0]     s_axil_wdata,
    input wire[axil_data_width / 8 - 1 : 0] s_axil_wstrb,
    input wire                              s_axil_wvalid,
    output wire                             s_axil_wready,

    // B channel
    output wire[1:0]                        s_axil_bresp,
    output wire                             s_axil_bvalid,
    input wire                              s_axil_bready,

    // AR channel
    input wire[axil_addr_width - 1 : 0]     s_axil_araddr,
    input wire                              s_axil_arvalid,
    output wire                             s_axil_arready,

    // R channel
    output wire[axil_data_width - 1 : 0]    s_axil_rdata,
    output wire[1:0]                        s_axil_rresp,
    output wire                             s_axil_rvalid,
    input wire                              s_axil_rready,

    // acquisition input
    input wire[5:0]                         prn_id,
    input wire[axil_data_width - 1 : 0]     correlation_result,
    input wire[axil_data_width - 1 : 0]     code_delay,
    input wire[axil_data_width - 1 : 0]     doppler_freq,

    // tracking outputs
    output wire [5:0]                       out_prn_id   [num_trackers-1:0],
    output wire [axil_data_width - 1 : 0]   out_doppler  [num_trackers-1:0],
    output wire [axil_data_width - 1 : 0]   out_code_delay [num_trackers-1:0]
);
    reg s_axil_awready_r;
    reg s_axil_bvalid_r;
    reg s_axil_rvalid_r;

    reg[num_trackers * 6 - 1 : 0]               dispatcher_prn_id;
    reg[axil_data_width * num_trackers - 1 : 0] dispatcher_doppler;
    reg[axil_data_width * num_trackers - 1 : 0] dispatcher_code_delay;

    always @(posedge aclk) begin
        if (!aresetn) begin
            s_axil_awready_r <= 1'h0;
        end
        else begin
            s_axil_awready_r <= !s_axil_awready_r && (s_axil_awvalid && s_axil_wvalid);
        end
    end

        always @(posedge aclk) begin
        if (!aresetn) begin
            s_axil_bvalid_r <= 1'h0;
        end
        else begin
            if (s_axil_awready) begin
                s_axil_bvalid_r <= 1'h1;
            end
            else if (s_axil_bready) begin
                s_axil_bvalid_r <= 1'h0;
            end
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            s_axil_rvalid_r <= 1'h0;
        end
        else begin
            if (s_axil_arvalid && s_axil_arready) begin
                s_axil_rvalid_r <= 1'h1;
            end
            else if (s_axil_rready) begin
                s_axil_rvalid_r <= 1'h0;
            end
        end
    end

    gps_dispatcher #(
        .axil_addr_width(axil_addr_width),
        .axil_data_width(axil_data_width)
    ) dispatcher_dut (
        .aclk(aclk),
        .aresetn(aresetn),

        .s_axil_awaddr(s_axil_awaddr),
        .s_axil_awvalid(s_axil_awvalid),
        .s_axil_awready(s_axil_awready),

        .s_axil_wdata(s_axil_wdata),
        .s_axil_wstrb(s_axil_wstrb),
        .s_axil_wvalid(s_axil_wvalid),
        .s_axil_wready(s_axil_wready),

        .s_axil_bresp(s_axil_bresp),
        .s_axil_bvalid(s_axil_bvalid),
        .s_axil_bready(s_axil_bready),

        .s_axil_araddr(s_axil_araddr),
        .s_axil_arvalid(s_axil_arvalid),
        .s_axil_arready(s_axil_arready),

        .s_axil_rdata(s_axil_rdata),
        .s_axil_rresp(s_axil_rresp),
        .s_axil_rvalid(s_axil_rvalid),
        .s_axil_rready(s_axil_rready),

        // acquisition
        .prn_id(prn_id),
        .correlation_result(correlation_result),
        .code_delay(code_delay),
        .doppler_freq(doppler_freq),

        // tracking
        .lock_loss(),
        .dll_out(),

        .start_acquisition(),
        .track_prn_id(dispatcher_prn_id),
        .track_doppler(dispatcher_doppler),
        .track_code_delay(dispatcher_code_delay)
    );

    // Tracker Instantiations
    genvar i;
    generate
        for (i = 0; i < num_trackers; i = i + 1) begin : trackers
            jun_tracker #(
                .axil_addr_width(axil_addr_width),
                .axil_data_width(axil_data_width)
            ) tracker_dut (
                .track_prn_id(dispatcher_prn_id[i*6 +: 6]),
                .track_doppler(dispatcher_doppler[i*axil_data_width +: axil_data_width]),
                .track_code_delay(dispatcher_code_delay[i*axil_data_width +: axil_data_width]),
                .out_prn_id(out_prn_id[i]),
                .out_doppler(out_doppler[i]),
                .out_code_delay(out_code_delay[i])
            );
        end
    endgenerate

    assign s_axil_awready = s_axil_awready_r;
    assign s_axil_wready = s_axil_awready_r;
    assign s_axil_bresp = 2'b00;
    assign s_axil_bvalid = s_axil_bvalid_r;
    assign s_axil_arready = !s_axil_rvalid_r;
    assign s_axil_rresp = 2'b00;
    assign s_axil_rvalid = s_axil_rvalid_r;
endmodule