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
    input   logic   [4 : 0]                         prn_id[0 : 7],
    output  logic   signed [DAT_WIDTH - 1 : 0]      ca_code[0 : 4096 * 8 - 1]
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
                0:  ca_code[i * 4096 +: 4096] <= ca_code_0;
                1:  ca_code[i * 4096 +: 4096] <= ca_code_1;
                2:  ca_code[i * 4096 +: 4096] <= ca_code_2;
                3:  ca_code[i * 4096 +: 4096] <= ca_code_3;
                4:  ca_code[i * 4096 +: 4096] <= ca_code_4;
                5:  ca_code[i * 4096 +: 4096] <= ca_code_5;
                6:  ca_code[i * 4096 +: 4096] <= ca_code_6;
                7:  ca_code[i * 4096 +: 4096] <= ca_code_7;
                8:  ca_code[i * 4096 +: 4096] <= ca_code_8;
                9:  ca_code[i * 4096 +: 4096] <= ca_code_9;
                10: ca_code[i * 4096 +: 4096] <= ca_code_10;
                11: ca_code[i * 4096 +: 4096] <= ca_code_11;
                12: ca_code[i * 4096 +: 4096] <= ca_code_12;
                13: ca_code[i * 4096 +: 4096] <= ca_code_13;
                14: ca_code[i * 4096 +: 4096] <= ca_code_14;
                15: ca_code[i * 4096 +: 4096] <= ca_code_15;
                16: ca_code[i * 4096 +: 4096] <= ca_code_16;
                17: ca_code[i * 4096 +: 4096] <= ca_code_17;
                18: ca_code[i * 4096 +: 4096] <= ca_code_18;
                19: ca_code[i * 4096 +: 4096] <= ca_code_19;
                20: ca_code[i * 4096 +: 4096] <= ca_code_20;
                21: ca_code[i * 4096 +: 4096] <= ca_code_21;
                22: ca_code[i * 4096 +: 4096] <= ca_code_22;
                23: ca_code[i * 4096 +: 4096] <= ca_code_23;
                24: ca_code[i * 4096 +: 4096] <= ca_code_24;
                25: ca_code[i * 4096 +: 4096] <= ca_code_25;
                26: ca_code[i * 4096 +: 4096] <= ca_code_26;
                27: ca_code[i * 4096 +: 4096] <= ca_code_27;
                28: ca_code[i * 4096 +: 4096] <= ca_code_28;
                29: ca_code[i * 4096 +: 4096] <= ca_code_29;
                30: ca_code[i * 4096 +: 4096] <= ca_code_30;
                31: ca_code[i * 4096 +: 4096] <= ca_code_31;
            endcase
        end
    end
endmodule
