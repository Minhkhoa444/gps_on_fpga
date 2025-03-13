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
    input   logic   clk,
    input   logic   [11:0]                      i_rdaddr,

    output  logic   signed [DAT_WIDTH-1:0]        o_data  [0:31]
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
        o_data[0] <= ca_code_0[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[1] <= ca_code_1[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[2] <= ca_code_2[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[3] <= ca_code_3[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[4] <= ca_code_4[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[5] <= ca_code_5[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[6] <= ca_code_6[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[7] <= ca_code_7[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[8] <= ca_code_8[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[9] <= ca_code_9[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[10] <= ca_code_10[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[11] <= ca_code_11[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[12] <= ca_code_12[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[13] <= ca_code_13[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[14] <= ca_code_14[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[15] <= ca_code_15[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[16] <= ca_code_16[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[17] <= ca_code_17[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[18] <= ca_code_18[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[19] <= ca_code_19[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[20] <= ca_code_20[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[21] <= ca_code_21[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[22] <= ca_code_22[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[23] <= ca_code_23[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[24] <= ca_code_24[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[25] <= ca_code_25[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[26] <= ca_code_26[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[27] <= ca_code_27[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[28] <= ca_code_28[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[29] <= ca_code_29[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[30] <= ca_code_30[i_rdaddr];
    end

    always_ff @(posedge clk) begin
        o_data[31] <= ca_code_31[i_rdaddr];
    end

endmodule
