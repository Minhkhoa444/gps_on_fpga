`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/12/2025 08:04:44 PM
// Design Name: 
// Module Name: precomputed_ca
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tracker_precomputed_ca #(
    parameter DAT_WIDTH = 16
) (
    input   logic                                   clk,
    input   logic   [4 : 0]                         prn_id[7],
    input   logic   [11 : 0]                        ca_code_early_addr[7],
    input   logic   [11 : 0]                        ca_code_late_addr[7],
    input   logic   [11 : 0]                        ca_code_prompt_addr[7],

    output  logic   signed [DAT_WIDTH - 1 : 0]      ca_code_early[7],
    output  logic   signed [DAT_WIDTH - 1 : 0]      ca_code_late[7],
    output  logic   signed [DAT_WIDTH - 1 : 0]      ca_code_prompt[7]
);

    logic   signed  [DAT_WIDTH-1:0]   ca_code_0 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_1 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_2 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_3 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_4 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_5 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_6 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_7 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_8 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_9 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_10 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_11 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_12 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_13 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_14 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_15 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_16 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_17 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_18 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_19 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_20 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_21 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_22 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_23 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_24 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_25 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_26 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_27 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_28 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_29 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_30 [0:4095];
    logic   signed  [DAT_WIDTH-1:0]   ca_code_31 [0:4095];

    initial begin
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_01.mem", ca_code_0);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_02.mem", ca_code_1);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_03.mem", ca_code_2);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_04.mem", ca_code_3);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_05.mem", ca_code_4);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_06.mem", ca_code_5);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_07.mem", ca_code_6);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_08.mem", ca_code_7);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_09.mem", ca_code_8);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_10.mem", ca_code_9);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_11.mem", ca_code_10);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_12.mem", ca_code_11);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_13.mem", ca_code_12);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_14.mem", ca_code_13);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_15.mem", ca_code_14);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_16.mem", ca_code_15);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_17.mem", ca_code_16);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_18.mem", ca_code_17);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_19.mem", ca_code_18);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_20.mem", ca_code_19);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_21.mem", ca_code_20);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_22.mem", ca_code_21);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_23.mem", ca_code_22);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_24.mem", ca_code_23);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_25.mem", ca_code_24);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_26.mem", ca_code_25);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_27.mem", ca_code_26);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_28.mem", ca_code_27);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_29.mem", ca_code_28);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_30.mem", ca_code_29);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_31.mem", ca_code_30);
        $readmemb("./../gps_rtl/gps_acquisition/mem/CA_PRN_32.mem", ca_code_31);
    end

    always_ff @(posedge clk) begin
        for(int i = 0; i < 7; i = i + 1) begin
            case(prn_id[i])
                0: begin
                    ca_code_early[i] <= ca_code_0[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_0[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_0[ca_code_prompt_addr[i]];
                end
                1: begin
                    ca_code_early[i] <= ca_code_1[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_1[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_1[ca_code_prompt_addr[i]];
                end
                2: begin
                    ca_code_early[i] <= ca_code_2[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_2[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_2[ca_code_prompt_addr[i]];
                end
                3: begin
                    ca_code_early[i] <= ca_code_3[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_3[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_3[ca_code_prompt_addr[i]];
                end
                4: begin
                    ca_code_early[i] <= ca_code_4[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_4[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_4[ca_code_prompt_addr[i]];
                end
                5: begin
                    ca_code_early[i] <= ca_code_5[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_5[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_5[ca_code_prompt_addr[i]];
                end
                6: begin
                    ca_code_early[i] <= ca_code_6[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_6[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_6[ca_code_prompt_addr[i]];
                end
                7: begin
                    ca_code_early[i] <= ca_code_7[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_7[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_7[ca_code_prompt_addr[i]];
                end
                8: begin
                    ca_code_early[i] <= ca_code_8[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_8[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_8[ca_code_prompt_addr[i]];
                end
                9: begin
                    ca_code_early[i] <= ca_code_9[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_9[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_9[ca_code_prompt_addr[i]];
                end
                10: begin
                    ca_code_early[i] <= ca_code_10[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_10[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_10[ca_code_prompt_addr[i]];
                end
                11: begin
                    ca_code_early[i] <= ca_code_11[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_11[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_11[ca_code_prompt_addr[i]];
                end
                12: begin
                    ca_code_early[i] <= ca_code_12[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_12[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_12[ca_code_prompt_addr[i]];
                end
                13: begin
                    ca_code_early[i] <= ca_code_13[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_13[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_13[ca_code_prompt_addr[i]];
                end
                14: begin
                    ca_code_early[i] <= ca_code_14[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_14[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_14[ca_code_prompt_addr[i]];
                end
                15: begin
                    ca_code_early[i] <= ca_code_15[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_15[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_15[ca_code_prompt_addr[i]];
                end
                16: begin
                    ca_code_early[i] <= ca_code_16[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_16[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_16[ca_code_prompt_addr[i]];
                end
                17: begin
                    ca_code_early[i] <= ca_code_17[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_17[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_17[ca_code_prompt_addr[i]];
                end
                18: begin
                    ca_code_early[i] <= ca_code_18[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_18[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_18[ca_code_prompt_addr[i]];
                end
                19: begin
                    ca_code_early[i] <= ca_code_19[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_19[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_19[ca_code_prompt_addr[i]];
                end
                20: begin
                    ca_code_early[i] <= ca_code_20[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_20[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_20[ca_code_prompt_addr[i]];
                end
                21: begin
                    ca_code_early[i] <= ca_code_21[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_21[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_21[ca_code_prompt_addr[i]];
                end
                22: begin
                    ca_code_early[i] <= ca_code_22[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_22[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_22[ca_code_prompt_addr[i]];
                end
                23: begin
                    ca_code_early[i] <= ca_code_23[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_23[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_23[ca_code_prompt_addr[i]];
                end
                24: begin
                    ca_code_early[i] <= ca_code_24[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_24[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_24[ca_code_prompt_addr[i]];
                end
                25: begin
                    ca_code_early[i] <= ca_code_25[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_25[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_25[ca_code_prompt_addr[i]];
                end
                26: begin
                    ca_code_early[i] <= ca_code_26[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_26[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_26[ca_code_prompt_addr[i]];
                end
                27: begin
                    ca_code_early[i] <= ca_code_27[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_27[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_27[ca_code_prompt_addr[i]];
                end
                28: begin
                    ca_code_early[i] <= ca_code_28[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_28[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_28[ca_code_prompt_addr[i]];
                end
                29: begin
                    ca_code_early[i] <= ca_code_29[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_29[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_29[ca_code_prompt_addr[i]];
                end
                30: begin
                    ca_code_early[i] <= ca_code_30[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_30[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_30[ca_code_prompt_addr[i]];
                end
                31: begin
                    ca_code_early[i] <= ca_code_31[ca_code_early_addr[i]];
                    ca_code_late[i] <= ca_code_31[ca_code_late_addr[i]];
                    ca_code_prompt[i] <= ca_code_31[ca_code_prompt_addr[i]];
                end
            endcase
        end
    end
endmodule
