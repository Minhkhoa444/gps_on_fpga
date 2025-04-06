module gps_dispatcher #(
    parameter axil_addr_width = 18,
    parameter axil_data_width = 32,
    parameter num_trackers = 4
) (
    input logic                              aclk,
    input logic                              aresetn,

    // AW channel
    input logic[axil_addr_width - 1 : 0]     s_axil_awaddr,
    input logic                              s_axil_awvalid,
    output logic                             s_axil_awready,

    // W channel
    input logic[axil_data_width - 1 : 0]     s_axil_wdata,
    input logic[axil_data_width / 8 - 1 : 0] s_axil_wstrb,
    input logic                              s_axil_wvalid,
    output logic                             s_axil_wready,

    // B channel
    output logic[1:0]                        s_axil_bresp,
    output logic                             s_axil_bvalid,
    input logic                              s_axil_bready,

    // AR channel
    input logic[axil_addr_width - 1 : 0]     s_axil_araddr,
    input logic                              s_axil_arvalid,
    output logic                             s_axil_arready,

    // R channel
    output logic[axil_data_width - 1 : 0]    s_axil_rdata,
    output logic[1:0]                        s_axil_rresp,
    output logic                             s_axil_rvalid,
    input logic                              s_axil_rready,

    // GPS acquisition
    input logic                              acquisition_valid,
    input logic[4:0]                         prn_id,
    input logic signed[15 : 0]               correlation_result,
    input logic[15 : 0]                      code_delay,
    input logic signed[15 : 0]               doppler_freq,

    // GPS tracking
    input logic                              tracking_valid,
    input logic[num_trackers * 32 - 1 : 0]   dll_out,

    input logic[11:0]                        tracker_0_early_addr,
    input logic[11:0]                        tracker_0_late_addr,
    input logic[11:0]                        tracker_0_prompt_addr,

    input logic[11:0]                        tracker_1_early_addr,
    input logic[11:0]                        tracker_1_late_addr,
    input logic[11:0]                        tracker_1_prompt_addr,

    input logic[11:0]                        tracker_2_early_addr,
    input logic[11:0]                        tracker_2_late_addr,
    input logic[11:0]                        tracker_2_prompt_addr,

    input logic[11:0]                        tracker_3_early_addr,
    input logic[11:0]                        tracker_3_late_addr,
    input logic[11:0]                        tracker_3_prompt_addr,

    // input

    // CA_BRAMS input
    input logic signed[15:0]                      i_ca [0:31],

    // Output to CA_BRAMS
    output logic[11:0]                           o_raddr,

    ////////////////////////////Output to Trackers//////////////////////
    output logic                                         dispatcher_valid,
    output logic signed[15:0]                            tracker_0_early_code,
    output logic signed[15:0]                            tracker_0_late_code,
    output logic signed[15:0]                            tracker_0_prompt_code,

    output logic signed[15:0]                            tracker_1_early_code,
    output logic signed[15:0]                            tracker_1_late_code,
    output logic signed[15:0]                            tracker_1_prompt_code,

    output logic signed[15:0]                            tracker_2_early_code,
    output logic signed[15:0]                            tracker_2_late_code,
    output logic signed[15:0]                            tracker_2_prompt_code,

    output logic signed[15:0]                            tracker_3_early_code,
    output logic signed[15:0]                            tracker_3_late_code,
    output logic signed[15:0]                            tracker_3_prompt_code,

    // Output
    output logic                                     start_acquisition,
    output logic[5 * num_trackers - 1 : 0]           track_prn_id,
    output logic signed[16 * num_trackers - 1 : 0]   track_doppler,
    output logic[16 * num_trackers - 1 : 0]          track_code_delay
);
    localparam addr_lsb = $clog2(axil_data_width) - 3;
    logic s_axil_awready_r;
    logic s_axil_bvalid_r;
    logic[axil_data_width - 1 : 0] s_axil_rdata_r;
    logic s_axil_rvalid_r;

    logic[axil_data_width - 1 : 0] ctrl_cfg_r;                // 0x00
    logic[axil_data_width - 1 : 0] dll_raw_r;                 // 0x04
    logic[axil_data_width - 1 : 0] prn_tracker_1;             // 0x08
    logic[axil_data_width - 1 : 0] prn_tracker_2;             // 0x0C
    logic[4 : 0]                   prn_id_bram[0:3];         // 0x10 to 0x8C
    logic signed[15 : 0]           corr_result_bram[0:3];    // 0x90 to 0x10C
    logic signed[15 : 0]           doppler_bram[0:3];        // 0x110 to 0x18C
    logic[15 : 0]                  code_delay_bram[0:3];     // 0x190 to 0x20C
    logic[15 : 0]                  doppler_tracker[0:7];      // 0x210 to 0x22C
    logic[15 : 0]                  code_delay_tracker[0:7];   // 0x230 to 0x24C
    logic                          acquisition_done;
    logic[num_trackers*32 - 1 : 0] dll_data;

    logic dispatcher_valid_r;
    logic[2:0] cnt;
    logic[11:0]                    o_raddr_reg;
    logic[12:0]                    cnt_2;
    logic[11:0]                    waddr_bram;
    logic flag; 
    logic delay_flag;
    logic started;
    gps_dispatcher_bram bram (
        .aclk(aclk),
        .i_waddr(waddr_bram),
        .i_raddr_early_0(tracker_0_early_addr),
        .i_raddr_late_0(tracker_0_late_addr),
        .i_raddr_prompt_0(tracker_0_prompt_addr),

        .i_raddr_early_1(tracker_1_early_addr),
        .i_raddr_late_1(tracker_1_late_addr),
        .i_raddr_prompt_1(tracker_1_prompt_addr),

        .i_raddr_early_2(tracker_2_early_addr),
        .i_raddr_late_2(tracker_2_late_addr),
        .i_raddr_prompt_2(tracker_2_prompt_addr),

        .i_raddr_early_3(tracker_3_early_addr),
        .i_raddr_late_3(tracker_3_late_addr),
        .i_raddr_prompt_3(tracker_3_prompt_addr),

        .i_en(delay_flag),
        .i_data(i_ca),
        .i_prn_id(prn_id_bram),

        .o_data_early_0(tracker_0_early_code),
        .o_data_late_0(tracker_0_late_code),
        .o_data_prompt_0(tracker_0_prompt_code),

        .o_data_early_1(tracker_1_early_code),
        .o_data_late_1(tracker_1_late_code),
        .o_data_prompt_1(tracker_1_prompt_code),

        .o_data_early_2(tracker_2_early_code),
        .o_data_late_2(tracker_2_late_code),
        .o_data_prompt_2(tracker_2_prompt_code),

        .o_data_early_3(tracker_3_early_code),
        .o_data_late_3(tracker_3_late_code),
        .o_data_prompt_3(tracker_3_prompt_code)
    );

    integer i;
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            cnt <= 'h0;
            for (i = 0;i < 4; i++) begin
                prn_id_bram[i] <= 'h0;
                corr_result_bram[i] <= 'h0;
                code_delay_bram[i] <= 'h0;
                doppler_bram[i] <= 'h0;
            end
        end
        else begin
            if (acquisition_valid) begin
                prn_id_bram[cnt] <= prn_id;
                corr_result_bram[cnt] <= correlation_result;
                code_delay_bram[cnt] <= code_delay;
                doppler_bram[cnt] <=  doppler_freq;
                cnt <= cnt + 1;
            end
        end
    end

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            started <= 'h0;
            cnt_2 <= 'h0;
        end else begin
            if (cnt == 4 && cnt_2 < 4096) begin
                o_raddr_reg <= (started == 0) ? 'h0 : o_raddr_reg + 1;
                cnt_2 <= cnt_2 + 1;
                started <= 'h1;
            end else begin
                started <= 'h0;
                cnt_2 <= (cnt == 4) ? cnt_2 + 1 : 0;
            end
        end
    end

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            flag <= 'h0;
            delay_flag <= 'h0;
        end else begin
            if (cnt == 4 && cnt_2 < 4097) begin
                flag <= 'h1;
                delay_flag <= flag;
                waddr_bram <= o_raddr_reg;  
            end else begin
                flag <= 'h0;
                delay_flag <= 'h0;
                // waddr_bram <= 'h0;
            end
        end
    end

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            dispatcher_valid_r <= 'h0;
        end else begin
            if (cnt_2 == 4097) begin
                dispatcher_valid_r <= 'h1;
            end else begin
                dispatcher_valid_r <= 'h0;
            end
        end
    end

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_awready_r <= 1'h0;
        end
        else begin
            s_axil_awready_r <= !s_axil_awready_r && (s_axil_awvalid && s_axil_wvalid);
        end
    end

    always_ff @(posedge aclk or negedge aresetn) begin
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

    always_ff @(posedge aclk or negedge aresetn) begin
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

    // always @(posedge aclk or negedge aresetn) begin
    //     if (!aresetn) begin
    //         ctrl_cfg_r <= 'h0;
    //         dll_raw_r <= 'h0;
    //         prn_tracker_1 <= 'h0;
    //         prn_tracker_2 <= 'h0;
    //         // flag <= 'h0;
    //         last_correlation_result <= 'h0;
    //         last_prn_id <= -1;
    //         for (i = 0; i < 4; i = i + 1) begin
    //             prn_id_bram[i] <= 'h0;
    //             corr_result_bram[i] <= 'h0;
    //             doppler_bram[i] <= 'h0;
    //             code_delay_bram[i] <= 'h0;
    //         end
    //         for (i=0; i < 8; i = i + 1) begin
    //             doppler_tracker[i] <= 'h0;
    //             code_delay_tracker[i] <= 'h0;
    //         end
    //     end
    //     else begin
    //         if (s_axil_awready) begin
    //             case (s_axil_awaddr[axil_addr_width - 1 : addr_lsb])
    //                 // 0x00
    //                 'd0:
    //                 begin
    //                     if (s_axil_wstrb[0]  == 1'b1) begin
    //                         ctrl_cfg_r[0] <= s_axil_wdata[0];
    //                     end
    //                 end
    //                 // 0x04
    //                 'd1:
    //                 begin
    //                 end
    //                 // 0x08
    //                 'd2:
    //                 begin
    //                     if (s_axil_wstrb[0] == 1'b1) begin
    //                         prn_tracker_1[7:0] <= s_axil_wdata[7:0];
    //                     end
    //                     if (s_axil_wstrb[1] == 1'b1) begin
    //                         prn_tracker_1[15:8] <= s_axil_wdata[15:8];
    //                     end
    //                     if (s_axil_wstrb[2] == 1'b1) begin
    //                         prn_tracker_1[23:16] <= s_axil_wdata[23:16];
    //                     end
    //                     if (s_axil_wstrb[3] == 1'b1) begin
    //                         prn_tracker_1[24] <= s_axil_wdata[24];
    //                     end
    //                 end
    //                 // 0x0C
    //                 'd3:
    //                 begin
    //                     if (s_axil_wstrb[0] == 1'b1) begin
    //                         prn_tracker_2[7:0] <= s_axil_wdata[7:0];
    //                     end
    //                     if (s_axil_wstrb[1] == 1'b1) begin
    //                         prn_tracker_2[14:8] <= s_axil_wdata[14:8];
    //                     end
    //                     // if (s_axil_wstrb[2] == 1'b1) begin
    //                     //     prn_tracker_2[17:16] <= s_axil_wdata[17:16];
    //                     // end
    //                 end
    //                 // 0x10 to 0x8C
    //                 'd4, 'd5, 'd6, 'd7, 'd8, 'd9, 'd10, 'd11, 'd12, 'd13, 'd14, 'd15,
    //                 'd16, 'd17, 'd18, 'd19, 'd20, 'd21, 'd22, 'd23, 'd24, 'd25, 'd26,
    //                 'd27, 'd28, 'd29, 'd30, 'd31, 'd32, 'd33, 'd34, 'd35: 
    //                 begin
    //                 end
    //                 // 0x90 to 0x10C
    //                 'd36, 'd37, 'd38, 'd39, 'd40, 'd41, 'd42, 'd43, 'd44, 'd45, 'd46, 'd47,
    //                 'd48, 'd49, 'd50, 'd51, 'd52, 'd53, 'd54, 'd55, 'd56, 'd57, 'd58, 'd59,
    //                 'd60, 'd61, 'd62, 'd63, 'd64, 'd65, 'd66, 'd67:
    //                 begin
    //                 end
    //                 // 0x110 to 0x18C
    //                 'd68, 'd69, 'd70, 'd71, 'd72, 'd73, 'd74, 'd75, 'd76, 'd77, 'd78, 'd79,
    //                 'd80, 'd81, 'd82, 'd83, 'd84, 'd85, 'd86, 'd87, 'd88, 'd89, 'd90, 'd91,
    //                 'd92, 'd93, 'd94, 'd95, 'd96, 'd97, 'd98, 'd99:
    //                 begin
    //                 end
    //                 // 0x190 to 0x20C
    //                 'd100, 'd101, 'd102, 'd103, 'd104, 'd105, 'd106, 'd107, 'd108, 'd109, 'd110, 'd111,
    //                 'd112, 'd113, 'd114, 'd115, 'd116, 'd117, 'd118, 'd119, 'd120, 'd121, 'd122, 'd123,
    //                 'd124, 'd125, 'd126, 'd127, 'd128, 'd129, 'd130, 'd131:
    //                 begin
    //                 end
    //                 // 0x210 to 0x22C
    //                 'd132, 'd133, 'd134, 'd135, 'd136, 'd137, 'd138, 'd139:
    //                 begin
    //                     if (s_axil_wstrb[0] == 1'b1) begin
    //                         doppler_tracker[s_axil_awaddr[axil_addr_width - 1 : addr_lsb] - 132][7:0] <= s_axil_wdata[7:0];
    //                     end
    //                     if (s_axil_wstrb[1] == 1'b1) begin
    //                         doppler_tracker[s_axil_awaddr[axil_addr_width - 1 : addr_lsb] - 132][15:8] <= s_axil_wdata[15:8];
    //                     end
    //                     // if (s_axil_wstrb[2] == 1'b1) begin
    //                     //     doppler_tracker[s_axil_awaddr[axil_addr_width - 1 : addr_lsb] - 132][23:16] <= s_axil_wdata[23:16];
    //                     // end
    //                     // if (s_axil_wstrb[3] == 1'b1) begin
    //                     //     doppler_tracker[s_axil_awaddr[axil_addr_width - 1 : addr_lsb] - 132][31:24] <= s_axil_wdata[31:24];
    //                     // end
    //                 end
    //                 // 0x230 to 0x24C
    //                 'd140, 'd141, 'd142, 'd143, 'd144, 'd145, 'd146, 'd147:
    //                 begin
    //                     if (s_axil_wstrb[0] == 1'b1) begin
    //                         code_delay_tracker[s_axil_awaddr[axil_addr_width - 1 : addr_lsb] - 140][7:0] <= s_axil_wdata[7:0];
    //                     end
    //                     if (s_axil_wstrb[1] == 1'b1) begin
    //                         code_delay_tracker[s_axil_awaddr[axil_addr_width - 1 : addr_lsb] - 140][15:8] <= s_axil_wdata[15:8];
    //                     end
    //                 end

    //                 default: 
    //                 begin
    //                     // Handle invalid addresses
    //                 end
    //             endcase
    //         end
    //         if (correlation_result > corr_result_bram[prn_id] && acquisition_valid) begin
    //             corr_result_bram[prn_id] <= correlation_result;
    //             doppler_bram[prn_id] <= doppler_freq;
    //             code_delay_bram[prn_id] <= code_delay;
    //             last_correlation_result <= correlation_result;
    //             last_prn_id <= prn_id;
    //             // flag <= 'h1;
    //         end else begin
    //             // flag <= 'h0;
    //         end
    //         if (tracking_valid) begin
    //             dll_data <= dll_out;
    //         end
    //     end
    // end

    // reg[15:0]                       top_4[0:3];
    // reg[4:0]                        peak_id[0:3], top4_idx[0:3];
    // reg[15:0]                       min_val, min_val_1, min_val_2;
    // reg[1:0]                        min_idx, min_idx_1, min_idx_2;
    // integer                         k, found;

    // always @(*) begin
    //     min_val_1 = (top_4[0] < top_4[1]) ? top_4[0] : top_4[1];
    //     min_idx_1 = (top_4[0] < top_4[1]) ? 0 : 1;
    //     min_val_2 = (min_val_1 < top_4[2]) ? min_val_1 : top_4[2];
    //     min_idx_2 = (min_val_1 < top_4[2]) ? min_idx_1 : 2;
    //     min_val = (min_val_2 < top_4[3]) ? min_val_2 : top_4[3];
    //     min_idx = (min_val_2 < top_4[3]) ? min_idx_2 : 3;
    // end

    // always @(acquisition_valid or correlation_result or prn_id) begin
    //     found = -1;
    //     for (k = 0;k < 4; k = k + 1) begin
    //         if (peak_id[k] == prn_id) begin
    //             found = k;
    //         end
    //     end
    // end

    // always @(posedge aclk or negedge aresetn) begin
    //     if (!aresetn) begin
    //         top_4[0] <= 0;
    //         top_4[1] <= 0;
    //         top_4[2] <= 0;
    //         top_4[3] <= 0;
    //         peak_id[0] <= 0;
    //         peak_id[1] <= 0;
    //         peak_id[2] <= 0;
    //         peak_id[3] <= 0;
    //     end else if (acquisition_valid) begin
    //         if (found != -1) begin
    //             top_4[found] <= (correlation_result > top_4[found]) ? correlation_result : top_4[found];
    //         end else if (prn_id == last_prn_id && ((peak_id[3] == prn_id) || (peak_id[2] == prn_id) || (peak_id[1] == prn_id) || (peak_id[0] == prn_id))) begin
    //             if (peak_id[3] == prn_id) begin 
    //                 top_4[3] <= (correlation_result > top_4[3]) ? correlation_result : top_4[3];
    //             end else if (peak_id[2] == prn_id) begin
    //                 top_4[2] <= (correlation_result > top_4[2]) ? correlation_result : top_4[2];
    //             end else if (peak_id[1] == prn_id) begin
    //                 top_4[1] <= (correlation_result > top_4[1]) ? correlation_result : top_4[1];
    //             end else if (peak_id[0] == prn_id) begin
    //                 top_4[0] <= (correlation_result > top_4[0]) ? correlation_result : top_4[0];
    //             end
    //         end else begin
    //             top_4[min_idx] <= (min_val < correlation_result) ? correlation_result : top_4[min_idx];
    //             peak_id[min_idx] <= (min_val < correlation_result) ? prn_id : peak_id[min_idx];
    //         end
    //     end 
    //     // end else if (flag) begin
    //     //     if (found != -1) begin
    //     //         top_4[found] <= (last_correlation_result > top_4[found]) ? last_correlation_result : top_4[found];
    //     //     end else begin
    //     //         top_4[min_idx] <= (min_val < last_correlation_result) ? last_correlation_result : top_4[min_idx];
    //     //         peak_id[min_idx] <= (min_val < last_correlation_result) ? last_prn_id : peak_id[min_idx];
    //     //     end
    //     // end 
    // end

    // always @(posedge aclk) begin
    //     if (!aresetn) begin
    //         acquisition_done <= 'b0;
    //         // acquisition_done_delay <= 'b0;
    //     end
    //     else begin
    //         acquisition_done <= (doppler_freq == -10000) && (prn_id) && (code_delay);
    //         // acquisition_done_delay <= acquisition_done;
    //     end
    //     if (acquisition_done) begin
    //         top4_idx[0] <= peak_id[0];
    //         top4_idx[1] <= peak_id[1];
    //         top4_idx[2] <= peak_id[2];
    //         top4_idx[3] <= peak_id[3];
    //     end
    // end

    always_ff @(posedge aclk or negedge aresetn) begin
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
                        //s_axil_rdata_r <= prn_id_bram[s_axil_araddr[axil_addr_width - 1 : addr_lsb] - 4];
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
    for (j = 0; j < 4; j = j + 1) begin : gen_track_outputs
        assign track_prn_id[(j + 1) * 5 - 1 : j * 5] = prn_id_bram[j];
        assign track_doppler[(j + 1) * 16 - 1 : j * 16] = doppler_bram[j];
        assign track_code_delay[(j + 1) * 16 - 1 : j * 16] = code_delay_bram[j];
    end
    endgenerate

    assign o_raddr = o_raddr_reg;
    assign dispatcher_valid = dispatcher_valid_r;
endmodule 