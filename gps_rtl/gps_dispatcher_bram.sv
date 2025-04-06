module gps_dispatcher_bram(
    input logic             aclk,
    input logic [11 : 0]    i_waddr,

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

    input logic                   i_en,
    input logic signed [15:0]     i_data[0:31],
    input logic [4:0]             i_prn_id[0:3],

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
        early_prn_tracker_0[i_waddr] <= i_data[i_prn_id[0]];
        late_prn_tracker_0[i_waddr] <= i_data[i_prn_id[0]];
        prompt_prn_tracker_0[i_waddr] <= i_data[i_prn_id[0]];

        early_prn_tracker_1[i_waddr] <= i_data[i_prn_id[1]];
        late_prn_tracker_1[i_waddr] <= i_data[i_prn_id[1]];
        prompt_prn_tracker_1[i_waddr] <= i_data[i_prn_id[1]];

        early_prn_tracker_2[i_waddr] <= i_data[i_prn_id[2]];
        late_prn_tracker_2[i_waddr] <= i_data[i_prn_id[2]];
        prompt_prn_tracker_2[i_waddr] <= i_data[i_prn_id[2]];

        early_prn_tracker_3[i_waddr] <= i_data[i_prn_id[3]];
        late_prn_tracker_3[i_waddr] <= i_data[i_prn_id[3]];
        prompt_prn_tracker_3[i_waddr] <= i_data[i_prn_id[3]];
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