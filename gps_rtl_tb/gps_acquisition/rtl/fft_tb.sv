`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/06/2025 02:56:45 PM
// Design Name: 
// Module Name: fft_tb
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

import fft_pkg::*;

module fft_tb;
    localparam FFT_SIZE = 4096;

    logic           clk;
    logic           rst_n;
    logic           i_vld;
    data_t          i_data;
    logic           o_vld;
    data_t          o_data;

    logic   signed  [15:0]  ca_code [0:31][0:4095];

    task c1;
        @(posedge clk);
        #0.3;
    endtask

    fft_top dut(.*);

    
    initial begin
        #0 clk = 1'b1;
        forever #5 clk = ~clk; 
    end

    initial begin
        $readmemb("../mem/CA_PRN_01.mem",ca_code[0]);
        $readmemb("../mem/CA_PRN_02.mem",ca_code[1]);
        $readmemb("../mem/CA_PRN_03.mem",ca_code[2]);
        $readmemb("../mem/CA_PRN_04.mem",ca_code[3]);
        $readmemb("../mem/CA_PRN_05.mem",ca_code[4]);
        $readmemb("../mem/CA_PRN_06.mem",ca_code[5]);
        $readmemb("../mem/CA_PRN_07.mem",ca_code[6]);
        $readmemb("../mem/CA_PRN_08.mem",ca_code[7]);
        $readmemb("../mem/CA_PRN_09.mem",ca_code[8]);
        $readmemb("../mem/CA_PRN_10.mem",ca_code[9]);
        $readmemb("../mem/CA_PRN_11.mem",ca_code[10]);
        $readmemb("../mem/CA_PRN_12.mem",ca_code[11]);
        $readmemb("../mem/CA_PRN_13.mem",ca_code[12]);
        $readmemb("../mem/CA_PRN_14.mem",ca_code[13]);
        $readmemb("../mem/CA_PRN_15.mem",ca_code[14]);
        $readmemb("../mem/CA_PRN_16.mem",ca_code[15]);
        $readmemb("../mem/CA_PRN_17.mem",ca_code[16]);
        $readmemb("../mem/CA_PRN_18.mem",ca_code[17]);
        $readmemb("../mem/CA_PRN_19.mem",ca_code[18]);
        $readmemb("../mem/CA_PRN_20.mem",ca_code[19]);
        $readmemb("../mem/CA_PRN_21.mem",ca_code[20]);
        $readmemb("../mem/CA_PRN_22.mem",ca_code[21]);
        $readmemb("../mem/CA_PRN_23.mem",ca_code[22]);
        $readmemb("../mem/CA_PRN_24.mem",ca_code[23]);
        $readmemb("../mem/CA_PRN_25.mem",ca_code[24]);
        $readmemb("../mem/CA_PRN_26.mem",ca_code[25]);
        $readmemb("../mem/CA_PRN_27.mem",ca_code[26]);
        $readmemb("../mem/CA_PRN_28.mem",ca_code[27]);
        $readmemb("../mem/CA_PRN_29.mem",ca_code[28]);
        $readmemb("../mem/CA_PRN_30.mem",ca_code[29]);
        $readmemb("../mem/CA_PRN_31.mem",ca_code[30]);
        $readmemb("../mem/CA_PRN_32.mem",ca_code[31]);
    end

    initial begin
        #0
        rst_n = 1'b0;
        i_vld = 1'b0;
        repeat(2) c1;
        rst_n = 1'b1;
        repeat(10) c1;
        for(int i=0; i<32; i++) begin
            for(int j=0; j<4096; j++) begin
                c1;
                if(i==0 && j==0) begin
                    $display("Start input FFT at time %t",$time);
                end
                i_vld = 'b1;
                `ifdef NON_SCALE
                    i_data.data_re = {ca_code[i][j][15] ? {12{1'b1}} : {12{1'b0}}, ca_code[i][j]};
                    i_data.data_im = 28'b0;
                `else
                    i_data.data_re = {ca_code[i][j][15], ca_code[i][j]};
                    i_data.data_im = 17'b0;
                `endif
            end
        end
        c1;
        i_vld = 1'b0;
        // #100000
        // $finish;
    end

    event simulation_end;
    data_t  expected_output [0:31][0:4095];
    data_t  actual_output   [0:31][$];
    `ifdef NON_SCALE
        logic   signed  [27:0]  expected_re [0:31][0:4095];
        logic   signed  [27:0]  expected_im [0:31][0:4095];
    `else
        logic   signed  [16:0]  expected_re [0:31][0:4095];
        logic   signed  [16:0]  expected_im [0:31][0:4095];
    `endif

    initial begin
        `ifdef NON_SCALE
            $readmemb("../mem/fft_result/fft_real_non_scale_0.mem", expected_re[0]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_0.mem", expected_im[0]);
            $readmemb("../mem/fft_result/fft_real_non_scale_1.mem", expected_re[1]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_1.mem", expected_im[1]);
            $readmemb("../mem/fft_result/fft_real_non_scale_2.mem", expected_re[2]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_2.mem", expected_im[2]);
            $readmemb("../mem/fft_result/fft_real_non_scale_3.mem", expected_re[3]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_3.mem", expected_im[3]);
            $readmemb("../mem/fft_result/fft_real_non_scale_4.mem", expected_re[4]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_4.mem", expected_im[4]);
            $readmemb("../mem/fft_result/fft_real_non_scale_5.mem", expected_re[5]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_5.mem", expected_im[5]);
            $readmemb("../mem/fft_result/fft_real_non_scale_6.mem", expected_re[6]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_6.mem", expected_im[6]);
            $readmemb("../mem/fft_result/fft_real_non_scale_7.mem", expected_re[7]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_7.mem", expected_im[7]);
            $readmemb("../mem/fft_result/fft_real_non_scale_8.mem", expected_re[8]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_8.mem", expected_im[8]);
            $readmemb("../mem/fft_result/fft_real_non_scale_9.mem", expected_re[9]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_9.mem", expected_im[9]);
            $readmemb("../mem/fft_result/fft_real_non_scale_10.mem", expected_re[10]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_10.mem", expected_im[10]);
            $readmemb("../mem/fft_result/fft_real_non_scale_11.mem", expected_re[11]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_11.mem", expected_im[11]);
            $readmemb("../mem/fft_result/fft_real_non_scale_12.mem", expected_re[12]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_12.mem", expected_im[12]);
            $readmemb("../mem/fft_result/fft_real_non_scale_13.mem", expected_re[13]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_13.mem", expected_im[13]);
            $readmemb("../mem/fft_result/fft_real_non_scale_14.mem", expected_re[14]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_14.mem", expected_im[14]);
            $readmemb("../mem/fft_result/fft_real_non_scale_15.mem", expected_re[15]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_15.mem", expected_im[15]);
            $readmemb("../mem/fft_result/fft_real_non_scale_16.mem", expected_re[16]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_16.mem", expected_im[16]);
            $readmemb("../mem/fft_result/fft_real_non_scale_17.mem", expected_re[17]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_17.mem", expected_im[17]);
            $readmemb("../mem/fft_result/fft_real_non_scale_18.mem", expected_re[18]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_18.mem", expected_im[18]);
            $readmemb("../mem/fft_result/fft_real_non_scale_19.mem", expected_re[19]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_19.mem", expected_im[19]);
            $readmemb("../mem/fft_result/fft_real_non_scale_20.mem", expected_re[20]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_20.mem", expected_im[20]);
            $readmemb("../mem/fft_result/fft_real_non_scale_21.mem", expected_re[21]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_21.mem", expected_im[21]);
            $readmemb("../mem/fft_result/fft_real_non_scale_22.mem", expected_re[22]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_22.mem", expected_im[22]);
            $readmemb("../mem/fft_result/fft_real_non_scale_23.mem", expected_re[23]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_23.mem", expected_im[23]);
            $readmemb("../mem/fft_result/fft_real_non_scale_24.mem", expected_re[24]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_24.mem", expected_im[24]);
            $readmemb("../mem/fft_result/fft_real_non_scale_25.mem", expected_re[25]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_25.mem", expected_im[25]);
            $readmemb("../mem/fft_result/fft_real_non_scale_26.mem", expected_re[26]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_26.mem", expected_im[26]);
            $readmemb("../mem/fft_result/fft_real_non_scale_27.mem", expected_re[27]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_27.mem", expected_im[27]);
            $readmemb("../mem/fft_result/fft_real_non_scale_28.mem", expected_re[28]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_28.mem", expected_im[28]);
            $readmemb("../mem/fft_result/fft_real_non_scale_29.mem", expected_re[29]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_29.mem", expected_im[29]);
            $readmemb("../mem/fft_result/fft_real_non_scale_30.mem", expected_re[30]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_30.mem", expected_im[30]);
            $readmemb("../mem/fft_result/fft_real_non_scale_31.mem", expected_re[31]);
            $readmemb("../mem/fft_result/fft_imag_non_scale_31.mem", expected_im[31]);
        `else
            $readmemb("../mem/fft_result/fft_real_scale_0.mem", expected_re[0]);
            $readmemb("../mem/fft_result/fft_imag_scale_0.mem", expected_im[0]);
            $readmemb("../mem/fft_result/fft_real_scale_1.mem", expected_re[1]);
            $readmemb("../mem/fft_result/fft_imag_scale_1.mem", expected_im[1]);
            $readmemb("../mem/fft_result/fft_real_scale_2.mem", expected_re[2]);
            $readmemb("../mem/fft_result/fft_imag_scale_2.mem", expected_im[2]);
            $readmemb("../mem/fft_result/fft_real_scale_3.mem", expected_re[3]);
            $readmemb("../mem/fft_result/fft_imag_scale_3.mem", expected_im[3]);
            $readmemb("../mem/fft_result/fft_real_scale_4.mem", expected_re[4]);
            $readmemb("../mem/fft_result/fft_imag_scale_4.mem", expected_im[4]);
            $readmemb("../mem/fft_result/fft_real_scale_5.mem", expected_re[5]);
            $readmemb("../mem/fft_result/fft_imag_scale_5.mem", expected_im[5]);
            $readmemb("../mem/fft_result/fft_real_scale_6.mem", expected_re[6]);
            $readmemb("../mem/fft_result/fft_imag_scale_6.mem", expected_im[6]);
            $readmemb("../mem/fft_result/fft_real_scale_7.mem", expected_re[7]);
            $readmemb("../mem/fft_result/fft_imag_scale_7.mem", expected_im[7]);
            $readmemb("../mem/fft_result/fft_real_scale_8.mem", expected_re[8]);
            $readmemb("../mem/fft_result/fft_imag_scale_8.mem", expected_im[8]);
            $readmemb("../mem/fft_result/fft_real_scale_9.mem", expected_re[9]);
            $readmemb("../mem/fft_result/fft_imag_scale_9.mem", expected_im[9]);
            $readmemb("../mem/fft_result/fft_real_scale_10.mem", expected_re[10]);
            $readmemb("../mem/fft_result/fft_imag_scale_10.mem", expected_im[10]);
            $readmemb("../mem/fft_result/fft_real_scale_11.mem", expected_re[11]);
            $readmemb("../mem/fft_result/fft_imag_scale_11.mem", expected_im[11]);
            $readmemb("../mem/fft_result/fft_real_scale_12.mem", expected_re[12]);
            $readmemb("../mem/fft_result/fft_imag_scale_12.mem", expected_im[12]);
            $readmemb("../mem/fft_result/fft_real_scale_13.mem", expected_re[13]);
            $readmemb("../mem/fft_result/fft_imag_scale_13.mem", expected_im[13]);
            $readmemb("../mem/fft_result/fft_real_scale_14.mem", expected_re[14]);
            $readmemb("../mem/fft_result/fft_imag_scale_14.mem", expected_im[14]);
            $readmemb("../mem/fft_result/fft_real_scale_15.mem", expected_re[15]);
            $readmemb("../mem/fft_result/fft_imag_scale_15.mem", expected_im[15]);
            $readmemb("../mem/fft_result/fft_real_scale_16.mem", expected_re[16]);
            $readmemb("../mem/fft_result/fft_imag_scale_16.mem", expected_im[16]);
            $readmemb("../mem/fft_result/fft_real_scale_17.mem", expected_re[17]);
            $readmemb("../mem/fft_result/fft_imag_scale_17.mem", expected_im[17]);
            $readmemb("../mem/fft_result/fft_real_scale_18.mem", expected_re[18]);
            $readmemb("../mem/fft_result/fft_imag_scale_18.mem", expected_im[18]);
            $readmemb("../mem/fft_result/fft_real_scale_19.mem", expected_re[19]);
            $readmemb("../mem/fft_result/fft_imag_scale_19.mem", expected_im[19]);
            $readmemb("../mem/fft_result/fft_real_scale_20.mem", expected_re[20]);
            $readmemb("../mem/fft_result/fft_imag_scale_20.mem", expected_im[20]);
            $readmemb("../mem/fft_result/fft_real_scale_21.mem", expected_re[21]);
            $readmemb("../mem/fft_result/fft_imag_scale_21.mem", expected_im[21]);
            $readmemb("../mem/fft_result/fft_real_scale_22.mem", expected_re[22]);
            $readmemb("../mem/fft_result/fft_imag_scale_22.mem", expected_im[22]);
            $readmemb("../mem/fft_result/fft_real_scale_23.mem", expected_re[23]);
            $readmemb("../mem/fft_result/fft_imag_scale_23.mem", expected_im[23]);
            $readmemb("../mem/fft_result/fft_real_scale_24.mem", expected_re[24]);
            $readmemb("../mem/fft_result/fft_imag_scale_24.mem", expected_im[24]);
            $readmemb("../mem/fft_result/fft_real_scale_25.mem", expected_re[25]);
            $readmemb("../mem/fft_result/fft_imag_scale_25.mem", expected_im[25]);
            $readmemb("../mem/fft_result/fft_real_scale_26.mem", expected_re[26]);
            $readmemb("../mem/fft_result/fft_imag_scale_26.mem", expected_im[26]);
            $readmemb("../mem/fft_result/fft_real_scale_27.mem", expected_re[27]);
            $readmemb("../mem/fft_result/fft_imag_scale_27.mem", expected_im[27]);
            $readmemb("../mem/fft_result/fft_real_scale_28.mem", expected_re[28]);
            $readmemb("../mem/fft_result/fft_imag_scale_28.mem", expected_im[28]);
            $readmemb("../mem/fft_result/fft_real_scale_29.mem", expected_re[29]);
            $readmemb("../mem/fft_result/fft_imag_scale_29.mem", expected_im[29]);
            $readmemb("../mem/fft_result/fft_real_scale_30.mem", expected_re[30]);
            $readmemb("../mem/fft_result/fft_imag_scale_30.mem", expected_im[30]);
            $readmemb("../mem/fft_result/fft_real_scale_31.mem", expected_re[31]);
            $readmemb("../mem/fft_result/fft_imag_scale_31.mem", expected_im[31]);
        `endif

        // expected_output[0].data_re = expected_re[0];
        // expected_output[0].data_im = expected_im[0];
        for(int i=0; i<32; i++) begin
            for(int j=0; j<4096; j++) begin
                expected_output[i][j].data_re = expected_re[i][j];
                expected_output[i][j].data_im = expected_im[i][j];
            end
        end
    end

    bit start;
    initial begin
        start = 'b0;
        forever begin
            @(posedge clk) begin
                if(start == 'b0) begin
                    if(o_vld) begin
                        start = 'b1;
                    end
                end
                else begin
                    if(~o_vld) begin
                        start = 'b0;
                        -> simulation_end;
                    end
                end
            end
        end
    end

    logic   [4:0]   id;
    logic   [11:0]  counter;
    data_t  temp;
    initial begin
        counter = 12'b0;
        id = 5'b0;
        forever begin
            @(posedge clk) begin
                if(o_vld) begin
                    if(~(|counter[11:0]) && ~(|id[4:0])) begin
                        $display("First output FFT at time %t",$time);
                    end
                    temp = o_data;
                    actual_output[id].push_back(temp);
                    if(&counter[11:0]) begin
                        id = id + 1'b1;
                    end
                    counter = counter + 1'b1;
                end
            end
        end
    end

    bit signed      [17:0]  difference_re;
    bit signed      [17:0]  difference_im;
    logic           [FRAC_BIT-1:0]  max_diff;
    rec_diff        rec_dif_re [0:31];
    rec_max_diff    rec_max_dif_re;
    rec_diff        rec_dif_im [0:31];
    rec_max_diff    rec_max_dif_im;
    bit simulation_fail;

    genvar i;
    generate
        for(i=0; i<32; i++) begin
            assign rec_dif_re[i].max_diff_current = 0;
            assign rec_dif_re[i].max_diff_id = 0;
            assign rec_dif_im[i].max_diff_current = 0;
            assign rec_dif_im[i].max_diff_id = 0;
        end
    endgenerate
    assign rec_max_dif_re.max_diff_all = 0;
    assign rec_max_dif_re.max_diff_all_id = 0;
    assign rec_max_dif_re.max_diff_all_sat = 0;
    assign rec_max_dif_im.max_diff_all = 0;
    assign rec_max_dif_im.max_diff_all_id = 0;
    assign rec_max_dif_im.max_diff_all_sat = 0;

    real max_diff_all_re;
    real max_diff_all_im;
    real dif_float_re;
    real dif_float_im;
    real sum_squared_error_re = 0.0;
    real sum_squared_error_im = 0.0;
    real rmse_re    [0:31];
    real rmse_im    [0:31];
    real mean_value_re[0:31];
    real mean_value_im[0:31];
    initial @(simulation_end) begin
        
        max_diff = $ceil(0.1 * (2**15));  // 1/4096

        $display("\nmax_diff used: %f", (real'((max_diff))/real'(2**15)));
        for(int i=0; i<32; i++) begin
        // for(int i=0; i<1; i++) begin
            for(int j=0; j<4096; j++) begin
                difference_re = $signed(actual_output[i][j].data_re - expected_output[i][j].data_re);
                difference_im = $signed(actual_output[i][j].data_im - expected_output[i][j].data_im);
                // difference_re = $signed(actual_output[i][j].data_re - expected_output[1][j].data_re);
                // difference_im = $signed(actual_output[i][j].data_im - expected_output[1][j].data_im);
                // difference_re = $signed(actual_output[0][j].data_re - expected_output[0][j].data_re);
                // difference_im = $signed(actual_output[0][j].data_im - expected_output[0][j].data_im);

                if(difference_re < 0) begin
                    difference_re = -difference_re;
                end

                if(difference_im < 0) begin
                    difference_im = -difference_im;
                end

                sum_squared_error_re = sum_squared_error_re + (difference_re / 32768.0) * (difference_re / 32768.0);
                sum_squared_error_im = sum_squared_error_im + (difference_im / 32768.0) * (difference_im / 32768.0);

                if(difference_re > max_diff || difference_im > max_diff) begin
                    simulation_fail = 1;
                    dif_float_re = difference_re / 32768.0;
                    dif_float_im = difference_im / 32768.0;
                    $display("\nWrong OUTPUT: actual_output_re[%0d][%0d] = %b, expected_output_re[%0d][%0d] = %b, diff = %f", i, j,actual_output[i][j].data_re, i, j, expected_output[i][j].data_re, dif_float_re);
                    $display("\nWrong OUTPUT: actual_output_im[%0d][%0d] = %b, expected_output_im[%0d][%0d] = %b, diff = %f", i, j,actual_output[i][j].data_im, i, j, expected_output[i][j].data_im, dif_float_im);
                    // $display("\nWrong OUTPUT: actual_output_re[%0d][%0d] = %b, expected_output_re[%0d][%0d] = %b, diff = %f", i, j, actual_output[0][j].data_re, i, j, expected_output[0][j].data_re, dif_float_re);
                    // $display("\nWrong OUTPUT: actual_output_im[%0d][%0d] = %b, expected_output_im[%0d][%0d] = %b, diff = %f", i, j, actual_output[0][j].data_im, i, j, expected_output[0][j].data_im, dif_float_im);
                    break;
                end

                // Update current max diff (for each satellite)
                if(difference_re >= rec_dif_re[i].max_diff_current) begin
                    rec_dif_re[i].max_diff_current = difference_re;
                    rec_dif_re[i].max_diff_id = j;
                end

                if(difference_im >= rec_dif_im[i].max_diff_current) begin
                    rec_dif_im[i].max_diff_current = difference_im;
                    rec_dif_im[i].max_diff_id = j;
                end
            end

            rmse_re[i] = $sqrt(sum_squared_error_re/4096.0);
            rmse_im[i] = $sqrt(sum_squared_error_im/4096.0);

            sum_squared_error_re = 0.0;
            sum_squared_error_im = 0.0;

            // Update max diff (for all satellites)
            if(rec_dif_re[i].max_diff_current >= rec_max_dif_re.max_diff_all) begin
                rec_max_dif_re.max_diff_all = rec_dif_re[i].max_diff_current;
                rec_max_dif_re.max_diff_all_id = rec_dif_re[i].max_diff_id;
                rec_max_dif_re.max_diff_all_sat = i;
            end

            if(rec_dif_im[i].max_diff_current >= rec_max_dif_im.max_diff_all) begin
                rec_max_dif_im.max_diff_all = rec_dif_im[i].max_diff_current;
                rec_max_dif_im.max_diff_all_id = rec_dif_im[i].max_diff_id;
                rec_max_dif_im.max_diff_all_sat = i;
            end
        end
        for(int i=0; i<32; i++) begin
            mean_value_re[i] = 0.0;
            mean_value_im[i] = 0.0;
            for(int idx=0; idx<4096; idx++) begin
                mean_value_re[i] = mean_value_re[i] + (actual_output[i][idx].data_re<0 ? (-actual_output[i][idx].data_re)/32768.0 : (actual_output[i][idx].data_re)/32768.0);
                mean_value_im[i] = mean_value_im[i] + (actual_output[i][idx].data_im<0 ? (-actual_output[i][idx].data_im)/32768.0 : (actual_output[i][idx].data_im)/32768.0);
            end
            mean_value_re[i] = mean_value_re[i]/4096.0;
            mean_value_im[i] = mean_value_im[i]/4096.0;
        end
        $display("\n######################################################");
        $display("\n---------------- Max diff (for each satellite) ----------------");
        for(int i=0; i<32; i++) begin
        // for(int i=0; i<1; i++) begin
            real float_value_re;
            real float_value_im;
            float_value_re = rec_dif_re[i].max_diff_current / 32768.0;
            float_value_im = rec_dif_im[i].max_diff_current / 32768.0;
            // $display("\nSatellite %0d: %f at index: %0d", i, float_value, rec_diff_re[i].max_diff_id);
            $display("\nSatellite %0d | Max Real: %f at index: %0d | Max Imaginary: %f at index: %0d", i, float_value_re, rec_dif_re[i].max_diff_id, float_value_im, rec_dif_im[i].max_diff_id);
            if(i>=10) begin
                $display("             | RMSE Real: %f | RMSE Imaginary: %f | NRMSE Real: %f | NRMSE Imaginary: %f", rmse_re[i], rmse_im[i], rmse_re[i]/mean_value_re[i], rmse_im[i]/mean_value_im[i]);
            end
            else begin
                $display("            | RMSE Real: %f | RMSE Imaginary: %f | NRMSE Real: %f | NRMSE Imaginary: %f", rmse_re[i], rmse_im[i], rmse_re[i]/mean_value_re[i], rmse_im[i]/mean_value_im[i]);
            end
        end
        $display("\n---------------------------------------------------------------");
        max_diff_all_re = rec_max_dif_re.max_diff_all / 32768.0;
        max_diff_all_im = rec_max_dif_im.max_diff_all / 32768.0;
        $display("\nMax diff all time | Real: %f at index %0d of Satellite %0d | Imaginary: %f at index %0d of Satellite %0d", max_diff_all_re, rec_max_dif_re.max_diff_all_id, rec_max_dif_re.max_diff_all_sat, max_diff_all_im, rec_max_dif_im.max_diff_all_id, rec_max_dif_im.max_diff_all_sat);
        if(simulation_fail) begin
            $display("\nSimulation Failed!");
            $display("\n######################################################");
        end
        else begin
            $display("\nSimulation Success!");
            $display("\n######################################################");
        end
        $finish;
    end

endmodule
