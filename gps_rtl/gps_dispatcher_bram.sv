module gps_dispatcher_bram(
    input logic             aclk,
    input logic [17 : 0]    i_waddr,

    input logic [11 : 0]    i_raddr_early_0,
    input logic [11 : 0]    i_raddr_late_0,
    input logic [11 : 0]    i_raddr_prompt_0,

    input logic [11 : 0]    i_raddr_early_1,
    input logic [11 : 0]    i_raddr_late_1,
    input logic [11 : 0]    i_raddr_prompt_1,

    input logic [11 : 0]    i_raddr_early_2,
    input logic [11 : 0]    i_raddr_late_2,
    input logic [11 : 0]    i_raddr_prompt_2,

    input logic [11 : 0]    i_raddr_early_3,
    input logic [11 : 0]    i_raddr_late_3,
    input logic [11 : 0]    i_raddr_prompt_3,

    input logic [3:0]       wstrb,
    input logic             i_en,
    input [31:0]            i_data,

    output logic signed [15:0]    o_data_early_0,
    output logic signed [15:0]    o_data_late_0,
    output logic signed [15:0]    o_data_prompt_0,

    output logic signed [15:0]    o_data_early_1,
    output logic signed [15:0]    o_data_late_1,
    output logic signed [15:0]    o_data_prompt_1,

    output logic signed [15:0]    o_data_early_2,
    output logic signed [15:0]    o_data_late_2,
    output logic signed [15:0]    o_data_prompt_2,

    output logic signed [15:0]    o_data_early_3,
    output logic signed [15:0]    o_data_late_3,
    output logic signed [15:0]    o_data_prompt_3
);

logic[15 : 0]               early_prn_tracker_0[0:4095];   // 0x250  to 0x4250
logic[15 : 0]               late_prn_tracker_0[0:4095];    // 0x4254 to 0x8254
logic[15 : 0]               prompt_prn_tracker_0[0:4095];  // 0x8258 to 0xC258

logic[15 : 0]               early_prn_tracker_1[0:4095];   // 0xC25C  to 0x1025C
logic[15 : 0]               late_prn_tracker_1[0:4095];    // 0x10260 to 0x14260
logic[15 : 0]               prompt_prn_tracker_1[0:4095];  // 0x14264 to 0x18264

logic[15 : 0]               early_prn_tracker_2[0:4095];   // 0x18268 to 0x1C268
logic[15 : 0]               late_prn_tracker_2[0:4095];    // 0x1C26C to 0x2026C
logic[15 : 0]               prompt_prn_tracker_2[0:4095];  // 0x20270 to 0x24270

logic[15 : 0]               early_prn_tracker_3[0:4095];   // 0x24274 to 0x28274
logic[15 : 0]               late_prn_tracker_3[0:4095];    // 0x28278 to 0x2C278
logic[15 : 0]               prompt_prn_tracker_3[0:4095];  // 0x2C27C to 0x3027C

always_ff @(posedge aclk) begin
    if (i_en) begin
        if (i_waddr >= 'h250 && i_waddr <= 'h4250) begin
            if (wstrb[0] == 1'b1) early_prn_tracker_0[(i_waddr - 'h250) >> 2][7:0] <= i_data[7:0];
            if (wstrb[1] == 1'b1) early_prn_tracker_0[(i_waddr - 'h250) >> 2][15:8] <= i_data[15:8];
        end else if (i_waddr >= 'h4254 && i_waddr <= 'h8254) begin
            if (wstrb[0] == 1'b1) late_prn_tracker_0[(i_waddr - 'h4254) >> 2][7:0] <= i_data[7:0];
            if (wstrb[1] == 1'b1) late_prn_tracker_0[(i_waddr - 'h4254) >> 2][15:8] <= i_data[15:8];
        end else if (i_waddr >= 'h8258 && i_waddr <= 'hC258) begin
            if (wstrb[0] == 1'b1) prompt_prn_tracker_0[(i_waddr - 'h8258) >> 2][7:0] <= i_data[7:0];
            if (wstrb[1] == 1'b1) prompt_prn_tracker_0[(i_waddr - 'h8258) >> 2][15:8] <= i_data[15:8];
        end else if (i_waddr >= 'hC25C && i_waddr <= 'h1025C) begin
            if (wstrb[0] == 1'b1) early_prn_tracker_1[(i_waddr - 'hC25C) >> 2][7:0] <= i_data[7:0];
            if (wstrb[1] == 1'b1) early_prn_tracker_1[(i_waddr - 'hC25C) >> 2][15:8] <= i_data[15:8];
        end else if (i_waddr >= 'h10260 && i_waddr <= 'h14260) begin
            if (wstrb[0] == 1'b1) late_prn_tracker_1[(i_waddr - 'h10260) >> 2][7:0] <= i_data[7:0];
            if (wstrb[1] == 1'b1) late_prn_tracker_1[(i_waddr - 'h10260) >> 2][15:8] <= i_data[15:8];
        end else if (i_waddr >= 'h14264 && i_waddr <= 'h18264) begin
            if (wstrb[0] == 1'b1) prompt_prn_tracker_1[(i_waddr - 'h14264) >> 2][7:0] <= i_data[7:0];
            if (wstrb[1] == 1'b1) prompt_prn_tracker_1[(i_waddr - 'h14264) >> 2][15:8] <= i_data[15:8];
        end else if (i_waddr >= 'h18268 && i_waddr <= 'h1C268) begin
            if (wstrb[0] == 1'b1) early_prn_tracker_2[(i_waddr - 'h18268) >> 2][7:0] <= i_data[7:0];
            if (wstrb[1] == 1'b1) early_prn_tracker_2[(i_waddr - 'h18268) >> 2][15:8] <= i_data[15:8];
        end else if (i_waddr >= 'h1C26C && i_waddr <= 'h2026C) begin
            if (wstrb[0] == 1'b1) late_prn_tracker_2[(i_waddr - 'h1C26C) >> 2][7:0] <= i_data[7:0];
            if (wstrb[1] == 1'b1) late_prn_tracker_2[(i_waddr - 'h1C26C) >> 2][15:8] <= i_data[15:8];
        end else if (i_waddr >= 'h20270 && i_waddr <= 'h24270) begin
            if (wstrb[0] == 1'b1) prompt_prn_tracker_2[(i_waddr - 'h20270) >> 2][7:0] <= i_data[7:0];
            if (wstrb[1] == 1'b1) prompt_prn_tracker_2[(i_waddr - 'h20270) >> 2][15:8] <= i_data[15:8];
        end else if (i_waddr >= 'h24274 && i_waddr <= 'h28274) begin
            if (wstrb[0] == 1'b1) early_prn_tracker_3[(i_waddr - 'h24274) >> 2][7:0] <= i_data[7:0];
            if (wstrb[1] == 1'b1) early_prn_tracker_3[(i_waddr - 'h24274) >> 2][15:8] <= i_data[15:8];
        end else if (i_waddr >= 'h28278 && i_waddr <= 'h2C278) begin
            if (wstrb[0] == 1'b1) late_prn_tracker_3[(i_waddr - 'h28278) >> 2][7:0] <= i_data[7:0];
            if (wstrb[1] == 1'b1) late_prn_tracker_3[(i_waddr - 'h28278) >> 2][15:8] <= i_data[15:8];
        end else if (i_waddr >= 'h2C27C && i_waddr <= 'h3027C) begin
            if (wstrb[0] == 1'b1) prompt_prn_tracker_3[(i_waddr - 'h2C27C) >> 2][7:0] <= i_data[7:0];
            if (wstrb[1] == 1'b1) prompt_prn_tracker_3[(i_waddr - 'h2C27C) >> 2][15:8] <= i_data[15:8];
        end
    end
    o_data_early_0 <= early_prn_tracker_0[i_raddr_early_0];
    o_data_late_0 <= late_prn_tracker_0[i_raddr_late_0];
    o_data_prompt_0 <= prompt_prn_tracker_0[i_raddr_prompt_0];

    o_data_early_1 <= early_prn_tracker_1[i_raddr_early_1];
    o_data_late_1 <= late_prn_tracker_1[i_raddr_late_1];
    o_data_prompt_1 <= prompt_prn_tracker_1[i_raddr_prompt_1];

    o_data_early_2 <= early_prn_tracker_2[i_raddr_early_2];
    o_data_late_2 <= late_prn_tracker_2[i_raddr_late_2];
    o_data_prompt_2 <= prompt_prn_tracker_2[i_raddr_prompt_2];

    o_data_early_3 <= early_prn_tracker_3[i_raddr_early_3];
    o_data_late_3 <= late_prn_tracker_3[i_raddr_late_3];
    o_data_prompt_3 <= prompt_prn_tracker_3[i_raddr_prompt_3];
end

endmodule