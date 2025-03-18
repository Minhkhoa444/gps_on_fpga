module gps_dispatcher #(
    parameter axil_addr_width = 10,
    parameter axil_data_width = 32,
    parameter num_trackers = 8
) (
    input wire                              aclk,
    input wire                              aresetn,

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

    // GPS acquisition
    input wire                              acquisition_valid,
    input wire[4:0]                         prn_id,
    input wire[15 : 0]                      correlation_result,
    input wire[15 : 0]                      code_delay,
    input wire[15 : 0]                      doppler_freq,

    // GPS tracking
    input wire                              tracking_valid,
    input wire[num_trackers * 32 - 1 : 0]   dll_out,

    input[11:0]                             tracker_0_early_addr,
    input[11:0]                             tracker_0_late_addr,
    input[11:0]                             tracker_0_prompt_addr,

    input[11:0]                             tracker_1_early_addr,
    input[11:0]                             tracker_1_late_addr,
    input[11:0]                             tracker_1_prompt_addr,

    input[11:0]                             tracker_2_early_addr,
    input[11:0]                             tracker_2_late_addr,
    input[11:0]                             tracker_2_prompt_addr,

    input[11:0]                             tracker_3_early_addr,
    input[11:0]                             tracker_3_late_addr,
    input[11:0]                             tracker_3_prompt_addr,

    output signed[15:0]                            tracker_0_early_code,
    output signed[15:0]                            tracker_0_late_code,
    output signed[15:0]                            tracker_0_prompt_code,

    output signed[15:0]                            tracker_1_early_code,
    output signed[15:0]                            tracker_1_late_code,
    output signed[15:0]                            tracker_1_prompt_code,

    output signed[15:0]                            tracker_2_early_code,
    output signed[15:0]                            tracker_2_late_code,
    output signed[15:0]                            tracker_2_prompt_code,

    output signed[15:0]                            tracker_3_early_code,
    output signed[15:0]                            tracker_3_late_code,
    output signed[15:0]                            tracker_3_prompt_code,

    // Output
    output wire                             start_acquisition,
    output wire[5 * num_trackers - 1 : 0]   track_prn_id,
    output wire[16 * num_trackers - 1 : 0]  track_doppler,
    output wire[16 * num_trackers - 1 : 0]  track_code_delay
);
    localparam addr_lsb = $clog2(axil_data_width) - 3;
    reg s_axil_awready_r;
    reg s_axil_bvalid_r;
    reg[axil_data_width - 1 : 0] s_axil_rdata_r;
    reg s_axil_rvalid_r;

    reg[axil_data_width - 1 : 0] ctrl_cfg_r;                // 0x00
    reg[axil_data_width - 1 : 0] dll_raw_r;                 // 0x04
    reg[axil_data_width - 1 : 0] prn_tracker_1;             // 0x08
    reg[axil_data_width - 1 : 0] prn_tracker_2;             // 0x0C
    reg[4 : 0]                   prn_id_bram[0:31];         // 0x10 to 0x8C
    reg[15 : 0]                  corr_result_bram[0:31];    // 0x90 to 0x10C
    reg[15 : 0]                  doppler_bram[0:31];        // 0x110 to 0x18C
    reg[15 : 0]                  code_delay_bram[0:31];     // 0x190 to 0x20C
    reg[15 : 0]                  doppler_tracker[0:7];      // 0x210 to 0x22C
    reg[15 : 0]                  code_delay_tracker[0:7];   // 0x230 to 0x24C

    reg[15 : 0]                  early_prn_tracker_0[0:4095];   // 0x250  to 0x4250
    reg[15 : 0]                  late_prn_tracker_0[0:4095];    // 0x4254 to 0x8254
    reg[15 : 0]                  prompt_prn_tracker_0[0:4095];  // 0x8258 to 0xC258

    reg[15 : 0]                  early_prn_tracker_1[0:4095];   // 0xC25C  to 0x1025C
    reg[15 : 0]                  late_prn_tracker_1[0:4095];    // 0x10260 to 0x14260
    reg[15 : 0]                  prompt_prn_tracker_1[0:4095];  // 0x14264 to 0x18264

    reg[15 : 0]                  early_prn_tracker_2[0:4095];   // 0x18268 to 0x1C268
    reg[15 : 0]                  late_prn_tracker_2[0:4095];    // 0x1C26C to 0x2026C
    reg[15 : 0]                  prompt_prn_tracker_2[0:4095];  // 0x20270 to 0x24270

    reg[15 : 0]                  early_prn_tracker_3[0:4095];   // 0x24274 to 0x28274
    reg[15 : 0]                  late_prn_tracker_3[0:4095];    // 0x28278 to 0x2C278
    reg[15 : 0]                  prompt_prn_tracker_3[0:4095];  // 0x2C27C to 0x3027C

    
    
    reg[num_trackers*32 - 1 : 0] dll_data;

    integer i;
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

    always @(posedge aclk) begin
        if (!aresetn) begin
            ctrl_cfg_r <= 'h0;
            dll_raw_r <= 'h0;
            prn_tracker_1 <= 'h0;
            prn_tracker_2 <= 'h0;
            for (i = 0; i < 31; i = i + 1) begin
                prn_id_bram[i] <= 'h0;
                corr_result_bram[i] <= 'h0;
                doppler_bram[i] <= 'h0;
                code_delay_bram[i] <= 'h0;
            end
            for (i=0; i < 8; i = i + 1) begin
                doppler_tracker[i] <= 'h0;
                code_delay_tracker[i] <= 'h0;
            end
        end
        else begin
            if (s_axil_awready) begin
                case (s_axil_awaddr[axil_addr_width - 1 : addr_lsb])
                    // 0x00
                    'd0:
                    begin
                        if (s_axil_wstrb[0]  == 1'b1) begin
                            ctrl_cfg_r[0] <= s_axil_wdata[0];
                        end
                    end
                    // 0x04
                    'd1:
                    begin
                    end
                    // 0x08
                    'd2:
                    begin
                        if (s_axil_wstrb[0] == 1'b1) begin
                            prn_tracker_1[7:0] <= s_axil_wdata[7:0];
                        end
                        if (s_axil_wstrb[1] == 1'b1) begin
                            prn_tracker_1[15:8] <= s_axil_wdata[15:8];
                        end
                        if (s_axil_wstrb[2] == 1'b1) begin
                            prn_tracker_1[23:16] <= s_axil_wdata[23:16];
                        end
                        if (s_axil_wstrb[3] == 1'b1) begin
                            prn_tracker_1[24] <= s_axil_wdata[24];
                        end
                    end
                    // 0x0C
                    'd3:
                    begin
                        if (s_axil_wstrb[0] == 1'b1) begin
                            prn_tracker_2[7:0] <= s_axil_wdata[7:0];
                        end
                        if (s_axil_wstrb[1] == 1'b1) begin
                            prn_tracker_2[14:8] <= s_axil_wdata[14:8];
                        end
                        // if (s_axil_wstrb[2] == 1'b1) begin
                        //     prn_tracker_2[17:16] <= s_axil_wdata[17:16];
                        // end
                    end
                    // 0x10 to 0x8C
                    'd4, 'd5, 'd6, 'd7, 'd8, 'd9, 'd10, 'd11, 'd12, 'd13, 'd14, 'd15,
                    'd16, 'd17, 'd18, 'd19, 'd20, 'd21, 'd22, 'd23, 'd24, 'd25, 'd26,
                    'd27, 'd28, 'd29, 'd30, 'd31, 'd32, 'd33, 'd34, 'd35: 
                    begin
                    end
                    // 0x90 to 0x10C
                    'd36, 'd37, 'd38, 'd39, 'd40, 'd41, 'd42, 'd43, 'd44, 'd45, 'd46, 'd47,
                    'd48, 'd49, 'd50, 'd51, 'd52, 'd53, 'd54, 'd55, 'd56, 'd57, 'd58, 'd59,
                    'd60, 'd61, 'd62, 'd63, 'd64, 'd65, 'd66, 'd67:
                    begin
                    end
                    // 0x110 to 0x18C
                    'd68, 'd69, 'd70, 'd71, 'd72, 'd73, 'd74, 'd75, 'd76, 'd77, 'd78, 'd79,
                    'd80, 'd81, 'd82, 'd83, 'd84, 'd85, 'd86, 'd87, 'd88, 'd89, 'd90, 'd91,
                    'd92, 'd93, 'd94, 'd95, 'd96, 'd97, 'd98, 'd99:
                    begin
                    end
                    // 0x190 to 0x20C
                    'd100, 'd101, 'd102, 'd103, 'd104, 'd105, 'd106, 'd107, 'd108, 'd109, 'd110, 'd111,
                    'd112, 'd113, 'd114, 'd115, 'd116, 'd117, 'd118, 'd119, 'd120, 'd121, 'd122, 'd123,
                    'd124, 'd125, 'd126, 'd127, 'd128, 'd129, 'd130, 'd131:
                    begin
                    end
                    // 0x210 to 0x22C
                    'd132, 'd133, 'd134, 'd135, 'd136, 'd137, 'd138, 'd139:
                    begin
                        if (s_axil_wstrb[0] == 1'b1) begin
                            doppler_tracker[s_axil_awaddr[axil_addr_width - 1 : addr_lsb] - 132][7:0] <= s_axil_wdata[7:0];
                        end
                        if (s_axil_wstrb[1] == 1'b1) begin
                            doppler_tracker[s_axil_awaddr[axil_addr_width - 1 : addr_lsb] - 132][15:8] <= s_axil_wdata[15:8];
                        end
                        // if (s_axil_wstrb[2] == 1'b1) begin
                        //     doppler_tracker[s_axil_awaddr[axil_addr_width - 1 : addr_lsb] - 132][23:16] <= s_axil_wdata[23:16];
                        // end
                        // if (s_axil_wstrb[3] == 1'b1) begin
                        //     doppler_tracker[s_axil_awaddr[axil_addr_width - 1 : addr_lsb] - 132][31:24] <= s_axil_wdata[31:24];
                        // end
                    end
                    // 0x230 to 0x24C
                    'd140, 'd141, 'd142, 'd143, 'd144, 'd145, 'd146, 'd147:
                    begin
                        if (s_axil_wstrb[0] == 1'b1) begin
                            code_delay_tracker[s_axil_awaddr[axil_addr_width - 1 : addr_lsb] - 140][7:0] <= s_axil_wdata[7:0];
                        end
                        if (s_axil_wstrb[1] == 1'b1) begin
                            code_delay_tracker[s_axil_awaddr[axil_addr_width - 1 : addr_lsb] - 140][15:8] <= s_axil_wdata[15:8];
                        end
                    end

                    default: 
                    begin
                        // Handle invalid addresses
                    end
                endcase
                if (s_axil_awaddr >= 'h250 && s_axil_awaddr <= 'h4250) begin
                    if (s_axil_wstrb[0] == 1'b1) begin
                        early_prn_tracker_0[(s_axil_awaddr - 'h250) >> 2][7:0] <= s_axil_wdata[7:0];
                    end
                    if (s_axil_wstrb[1] == 1'b1) begin
                        early_prn_tracker_0[(s_axil_awaddr - 'h250) >> 2][15:8] <= s_axil_wdata[15:8];
                    end
                end else if (s_axil_awaddr >= 'h4254 && s_axil_awaddr <= 'h8254) begin
                    if (s_axil_wstrb[0] == 1'b1) begin
                        late_prn_tracker_0[(s_axil_awaddr - 'h4254) >> 2][7:0] <= s_axil_wdata[7:0];
                    end
                    if (s_axil_wstrb[1] == 1'b1) begin
                        late_prn_tracker_0[(s_axil_awaddr - 'h4254) >> 2][15:8] <= s_axil_wdata[15:8];
                    end
                end else if (s_axil_awaddr >= 'h8258 && s_axil_awaddr <= 'hC258) begin
                    if (s_axil_wstrb[0] == 1'b1) begin
                        prompt_prn_tracker_0[(s_axil_awaddr - 'h8258) >> 2][7:0] <= s_axil_wdata[7:0];
                    end
                    if (s_axil_wstrb[1] == 1'b1) begin
                        prompt_prn_tracker_0[(s_axil_awaddr - 'h8258) >> 2][15:8] <= s_axil_wdata[15:8];
                    end
                end else if (s_axil_awaddr >= 'hC25C && s_axil_awaddr <= 'h1025C) begin
                    if (s_axil_wstrb[0] == 1'b1) begin
                        early_prn_tracker_1[(s_axil_awaddr - 'hC25C) >> 2][7:0] <= s_axil_wdata[7:0];
                    end
                    if (s_axil_wstrb[1] == 1'b1) begin
                        early_prn_tracker_1[(s_axil_awaddr - 'hC25C) >> 2][15:8] <= s_axil_wdata[15:8];
                    end
                end else if (s_axil_awaddr >= 'h10260 && s_axil_awaddr <= 'h14260) begin
                    if (s_axil_wstrb[0] == 1'b1) begin
                        late_prn_tracker_1[(s_axil_awaddr - 'h10260) >> 2][7:0] <= s_axil_wdata[7:0];
                    end
                    if (s_axil_wstrb[1] == 1'b1) begin
                        late_prn_tracker_1[(s_axil_awaddr - 'h10260) >> 2][15:8] <= s_axil_wdata[15:8];
                    end
                end else if (s_axil_awaddr >= 'h14264 && s_axil_awaddr <= 'h18264) begin
                    if (s_axil_wstrb[0] == 1'b1) begin
                        prompt_prn_tracker_1[(s_axil_awaddr - 'h14264) >> 2][7:0] <= s_axil_wdata[7:0];
                    end
                    if (s_axil_wstrb[1] == 1'b1) begin
                        prompt_prn_tracker_1[(s_axil_awaddr - 'h14264) >> 2][15:8] <= s_axil_wdata[15:8];
                    end
                end else if (s_axil_awaddr >= 'h18268 && s_axil_awaddr <= 'h1C268) begin
                    if (s_axil_wstrb[0] == 1'b1) begin
                        early_prn_tracker_2[(s_axil_awaddr - 'h18268) >> 2][7:0] <= s_axil_wdata[7:0];
                    end
                    if (s_axil_wstrb[1] == 1'b1) begin
                        early_prn_tracker_2[(s_axil_awaddr - 'h18268) >> 2][15:8] <= s_axil_wdata[15:8];
                    end
                end else if (s_axil_awaddr >= 'h1C26C && s_axil_awaddr <= 'h2026C) begin
                    if (s_axil_wstrb[0] == 1'b1) begin
                        late_prn_tracker_2[(s_axil_awaddr - 'h1C26C) >> 2][7:0] <= s_axil_wdata[7:0];
                    end
                    if (s_axil_wstrb[1] == 1'b1) begin
                        late_prn_tracker_2[(s_axil_awaddr - 'h1C26C) >> 2][15:8] <= s_axil_wdata[15:8];
                    end
                end else if (s_axil_awaddr >= 'h20270 && s_axil_awaddr <= 'h24270) begin
                    if (s_axil_wstrb[0] == 1'b1) begin
                        prompt_prn_tracker_2[(s_axil_awaddr - 'h20270) >> 2][7:0] <= s_axil_wdata[7:0];
                    end
                    if (s_axil_wstrb[1] == 1'b1) begin
                        prompt_prn_tracker_2[(s_axil_awaddr - 'h20270) >> 2][15:8] <= s_axil_wdata[15:8];
                    end
                end else if (s_axil_awaddr >= 'h24274 && s_axil_awaddr <= 'h28274) begin
                    if (s_axil_wstrb[0] == 1'b1) begin
                        early_prn_tracker_3[(s_axil_awaddr - 'h24274) >> 2][7:0] <= s_axil_wdata[7:0];
                    end
                    if (s_axil_wstrb[1] == 1'b1) begin
                        early_prn_tracker_3[(s_axil_awaddr - 'h24274) >> 2][15:8] <= s_axil_wdata[15:8];
                    end
                end else if (s_axil_awaddr >= 'h28278 && s_axil_awaddr <= 'h2C278) begin
                    if (s_axil_wstrb[0] == 1'b1) begin
                        late_prn_tracker_3[(s_axil_awaddr - 'h28278) >> 2][7:0] <= s_axil_wdata[7:0];
                    end
                    if (s_axil_wstrb[1] == 1'b1) begin
                        late_prn_tracker_3[(s_axil_awaddr - 'h28278) >> 2][15:8] <= s_axil_wdata[15:8];
                    end
                end else if (s_axil_awaddr >= 'h2C27C && s_axil_awaddr <= 'h3027C) begin
                    if (s_axil_wstrb[0] == 1'b1) begin
                        prompt_prn_tracker_3[(s_axil_awaddr - 'h2C27C) >> 2][7:0] <= s_axil_wdata[7:0];
                    end
                    if (s_axil_wstrb[1] == 1'b1) begin
                        prompt_prn_tracker_3[(s_axil_awaddr - 'h2C27C) >> 2][15:8] <= s_axil_wdata[15:8];
                    end
                end
            end
            if (correlation_result > corr_result_bram[prn_id] && acquisition_valid) begin
                corr_result_bram[prn_id] <= correlation_result;
                doppler_bram[prn_id] <= doppler_freq;
                code_delay_bram[prn_id] <= code_delay;
            end

            if (tracking_valid) begin
                dll_data <= dll_out;
            end
        end
    end
    always @(posedge aclk) begin
        if (!aresetn) begin
            s_axil_rdata_r <= 'h0;
        end
        else begin
            if (s_axil_rvalid || s_axil_rready) begin
                case (s_axil_araddr[axil_addr_width - 1 : addr_lsb])
                    // 0x00
                    'd0:
                    begin
                        s_axil_rdata_r <= ctrl_cfg_r;
                    end
                    // 0x04
                    'd1:
                    begin
                        s_axil_rdata_r <= dll_raw_r;
                    end
                    // 0x08
                    'd2:
                    begin
                        s_axil_rdata_r <= prn_tracker_1;
                    end
                    // 0x0C
                    'd3:
                    begin
                        s_axil_rdata_r <= prn_tracker_2;
                    end
                    // 0x10 to 0x8C
                    'd4, 'd5, 'd6, 'd7, 'd8, 'd9, 'd10, 'd11, 'd12, 'd13, 'd14, 'd15,
                    'd16, 'd17, 'd18, 'd19, 'd20, 'd21, 'd22, 'd23, 'd24, 'd25, 'd26,
                    'd27, 'd28, 'd29, 'd30, 'd31, 'd32, 'd33, 'd34, 'd35: 
                    begin 
                        s_axil_rdata_r <= prn_id_bram[s_axil_araddr[axil_addr_width - 1 : addr_lsb] - 4];
                    end
                    // 0x90 to 0x10C
                    'd36, 'd37, 'd38, 'd39, 'd40, 'd41, 'd42, 'd43, 'd44, 'd45, 'd46, 'd47,
                    'd48, 'd49, 'd50, 'd51, 'd52, 'd53, 'd54, 'd55, 'd56, 'd57, 'd58, 'd59,
                    'd60, 'd61, 'd62, 'd63, 'd64, 'd65, 'd66, 'd67:
                    begin
                        s_axil_rdata_r <= corr_result_bram[s_axil_araddr[axil_addr_width - 1 : addr_lsb] - 36];
                    end
                    // 0x110 to 0x18C
                    'd68, 'd69, 'd70, 'd71, 'd72, 'd73, 'd74, 'd75, 'd76, 'd77, 'd78, 'd79,
                    'd80, 'd81, 'd82, 'd83, 'd84, 'd85, 'd86, 'd87, 'd88, 'd89, 'd90, 'd91,
                    'd92, 'd93, 'd94, 'd95, 'd96, 'd97, 'd98, 'd99:
                    begin
                        s_axil_rdata_r <= doppler_bram[s_axil_araddr[axil_addr_width - 1 : addr_lsb] - 68];
                    end
                    // 0x190 to 0x20C
                    'd100, 'd101, 'd102, 'd103, 'd104, 'd105, 'd106, 'd107, 'd108, 'd109, 'd110, 'd111,
                    'd112, 'd113, 'd114, 'd115, 'd116, 'd117, 'd118, 'd119, 'd120, 'd121, 'd122, 'd123,
                    'd124, 'd125, 'd126, 'd127, 'd128, 'd129, 'd130, 'd131:
                    begin
                        s_axil_rdata_r <= code_delay_bram[s_axil_araddr[axil_addr_width - 1 : addr_lsb] - 100];
                    end
                    // 0x210 to 0x22C
                    'd132, 'd133, 'd134, 'd135, 'd136, 'd137, 'd138, 'd139:
                    begin
                        s_axil_rdata_r <= doppler_tracker[s_axil_araddr[axil_addr_width - 1 : addr_lsb] - 132];
                    end
                    // 0x230 to 0x24C
                    'd140, 'd141, 'd142, 'd143, 'd144, 'd145, 'd146, 'd147:
                    begin
                        s_axil_rdata_r <= code_delay_tracker[s_axil_araddr[axil_addr_width - 1 : addr_lsb] - 140];
                    end
                    default: 
                    begin
                        // Handle invalid addresses
                        s_axil_rdata_r <= 0;
                    end
                endcase
            end
        end
    end

    // always @(prn_id or correlation_result or doppler_freq or code_delay) begin

    // end

    // always @(lock_loss) begin
        
    // end

    assign s_axil_awready = s_axil_awready_r;
    assign s_axil_wready = s_axil_awready_r;
    assign s_axil_bresp = 2'b00;
    assign s_axil_bvalid = s_axil_bvalid_r;
    assign s_axil_arready = !s_axil_rvalid_r;
    assign s_axil_rdata = s_axil_rdata_r;
    assign s_axil_rresp = 2'b00;
    assign s_axil_rvalid = s_axil_rvalid_r;
    
    assign start_acquisition = ctrl_cfg_r[0];
    genvar j;
    generate
    for (j = 0; j < num_trackers; j = j + 1) begin
        if (j < 5) begin
            assign track_prn_id[(j + 1) * 5 - 1 : j * 5] = prn_tracker_1[(j + 1) * 5 - 1 : j * 5];
        end
        else begin
            assign track_prn_id[(j + 1) * 5 - 1 : j * 5] = prn_tracker_2[(j - 4) * 5 - 1 : (j - 5) * 5];
        end

        assign track_doppler[(j + 1) * 16 - 1 : j * 16] = doppler_tracker[j];
        assign track_code_delay[(j + 1) * 16 - 1 : j * 16] = code_delay_tracker[j];
    end
    endgenerate

    assign tracker_0_early_code = early_prn_tracker_0[tracker_0_early_addr];
    assign tracker_0_late_code = late_prn_tracker_0[tracker_0_late_addr];
    assign tracker_0_prompt_code = prompt_prn_tracker_0[tracker_0_prompt_addr];

    assign tracker_1_early_code = early_prn_tracker_1[tracker_1_early_addr];
    assign tracker_1_late_code = late_prn_tracker_1[tracker_1_late_addr];
    assign tracker_1_prompt_code = prompt_prn_tracker_1[tracker_1_prompt_addr];

    assign tracker_2_early_code = early_prn_tracker_2[tracker_2_early_addr];
    assign tracker_2_late_code = late_prn_tracker_2[tracker_2_late_addr];
    assign tracker_2_prompt_code = prompt_prn_tracker_2[tracker_2_prompt_addr];

    assign tracker_3_early_code = early_prn_tracker_3[tracker_0_early_addr];
    assign tracker_3_late_code = late_prn_tracker_3[tracker_0_late_addr];
    assign tracker_3_prompt_code = prompt_prn_tracker_3[tracker_0_prompt_addr];

endmodule 