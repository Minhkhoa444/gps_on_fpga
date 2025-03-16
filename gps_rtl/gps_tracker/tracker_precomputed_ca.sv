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
    output  logic   signed [DAT_WIDTH - 1 : 0]      ca_code[0 : 31][0 : 4095]
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

    always_comb begin
        for(int i = 0; i < 4096; i = i + 1) begin
            ca_code[0][i] = ca_code_0[i];
            ca_code[1][i] = ca_code_1[i];
            ca_code[2][i] = ca_code_2[i];
            ca_code[3][i] = ca_code_3[i];
            ca_code[4][i] = ca_code_4[i];
            ca_code[5][i] = ca_code_5[i];
            ca_code[6][i] = ca_code_6[i];
            ca_code[7][i] = ca_code_7[i];
            ca_code[8][i] = ca_code_8[i];
            ca_code[9][i] = ca_code_9[i];
            ca_code[10][i] = ca_code_10[i];
            ca_code[11][i] = ca_code_11[i];
            ca_code[12][i] = ca_code_12[i];
            ca_code[13][i] = ca_code_13[i];
            ca_code[14][i] = ca_code_14[i];
            ca_code[15][i] = ca_code_15[i];
            ca_code[16][i] = ca_code_16[i];
            ca_code[17][i] = ca_code_17[i];
            ca_code[18][i] = ca_code_18[i];
            ca_code[19][i] = ca_code_19[i];
            ca_code[20][i] = ca_code_20[i];
            ca_code[21][i] = ca_code_21[i];
            ca_code[22][i] = ca_code_22[i];
            ca_code[23][i] = ca_code_23[i];
            ca_code[24][i] = ca_code_24[i];
            ca_code[25][i] = ca_code_25[i];
            ca_code[26][i] = ca_code_26[i];
            ca_code[27][i] = ca_code_27[i];
            ca_code[28][i] = ca_code_28[i];
            ca_code[29][i] = ca_code_29[i];
            ca_code[30][i] = ca_code_30[i];
            ca_code[31][i] = ca_code_31[i];
        end
    end
endmodule
