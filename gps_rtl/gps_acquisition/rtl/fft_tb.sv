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
    // logic           i_sync;
    // logic           o_sync;
    `ifdef ADDITION
    logic           i_sync_rst;
    `endif

    `ifdef  Q1530
        logic   [63:0]  ca_code [0:4095];
    `else
        `ifdef SIMPLE_TEST
            logic   [31:0]  ca_code [0:4095];
        `else
            logic signed [15:0]  ca_code [0:31][0:4095];
            // logic signed [33:0]  ca_code [0:31][0:4095];
        `endif
    `endif

    task c1;
        @(posedge clk);
        #0.3;
    endtask

    fft_top dut(.*);

    
    initial begin
        #0 clk = 1'b1;
        forever #5 clk = ~clk; 
    end

    `ifdef SIMPLE_TEST
        initial begin
            `ifdef  Q1530
                $readmemb("D:/Capstone Project/fft/fftgen4096/mem/ca_sat_1.mem", ca_code);
            `else
                $readmemb("D:/Capstone Project/fft/fftgen4096/mem/ca_sat_1_q2_14.mem", ca_code);
            `endif
        end

        initial begin
            #0
            rst_n = 1'b0;
            i_vld = 1'b0;
            // i_sync = 1'b0;
            c1;
            rst_n = 1'b1;
            #99
            for(int i=0; i<FFT_SIZE; i++) begin
                c1;
                // if(i==0) begin
                //     i_sync = 1'b1;
                // end
                // else begin
                //     i_sync = 1'b0;
                // end
                i_vld = 1'b1;
                `ifdef  Q1530
                    i_data.data_re = {ca_code[i][63] ? {12{1'b1}} : {12{1'b0}}, ca_code[i][63:32]};
                    i_data.data_im = {ca_code[i][31] ? {12{1'b1}} : {12{1'b0}}, ca_code[i][31:0]};
                `else
                    `ifdef  NON_SCALE
                        i_data.data_re = {ca_code[i][31] ? {12{1'b1}} : {12{1'b0}}, ca_code[i][31:16]};
                        i_data.data_im = {ca_code[i][15] ? {12{1'b1}} : {12{1'b0}}, ca_code[i][15:0]};
                    `else
                        i_data.data_re = {ca_code[i][31], ca_code[i][31:16]};
                        i_data.data_im = {ca_code[i][15], ca_code[i][15:0]};
                    `endif
                `endif
            end
            c1;
            i_vld = 1'b0;
            #10000000
            $finish;
        end
    `else
        event simulation_end;
        data_t  expected_output [0:32][0:4095];
        data_t  actual_output   [0:32][$];
        initial begin
            $readmemb("D:/Capstone Project/Matlab/CA_MEM_FILES/CA_PRN_10.mem", ca_code[0]);
            // $readmemb("D:/Capstone Project/Matlab/CA_MEM_FILES_SHIFTED/CA_SHIFTED_PRN_1.mem", ca_code[0]);
            // for(int i=4000; i<4096; i++) begin
            //     ca_code[0][i] = 34'b0;
            // end
            // $readmemb("./../mem/CA_PRN_02.mem", ca_code[1]);
            // $readmemb("./../mem/CA_PRN_03.mem", ca_code[2]);
            // $readmemb("./../mem/CA_PRN_04.mem", ca_code[3]);
            // $readmemb("./../mem/CA_PRN_05.mem", ca_code[4]);
            // $readmemb("./../mem/CA_PRN_06.mem", ca_code[5]);
            // $readmemb("./../mem/CA_PRN_07.mem", ca_code[6]);
            // $readmemb("./../mem/CA_PRN_08.mem", ca_code[7]);
            // $readmemb("./../mem/CA_PRN_09.mem", ca_code[8]);
            // $readmemb("./../mem/CA_PRN_10.mem", ca_code[9]);
            // $readmemb("./../mem/CA_PRN_11.mem", ca_code[10]);
            // $readmemb("./../mem/CA_PRN_12.mem", ca_code[11]);
            // $readmemb("./../mem/CA_PRN_13.mem", ca_code[12]);
            // $readmemb("./../mem/CA_PRN_14.mem", ca_code[13]);
            // $readmemb("./../mem/CA_PRN_15.mem", ca_code[14]);
            // $readmemb("./../mem/CA_PRN_16.mem", ca_code[15]);
            // $readmemb("./../mem/CA_PRN_17.mem", ca_code[16]);
            // $readmemb("./../mem/CA_PRN_18.mem", ca_code[17]);
            // $readmemb("./../mem/CA_PRN_19.mem", ca_code[18]);
            // $readmemb("./../mem/CA_PRN_20.mem", ca_code[19]);
            // $readmemb("./../mem/CA_PRN_21.mem", ca_code[20]);
            // $readmemb("./../mem/CA_PRN_22.mem", ca_code[21]);
            // $readmemb("./../mem/CA_PRN_23.mem", ca_code[22]);
            // $readmemb("./../mem/CA_PRN_24.mem", ca_code[23]);
            // $readmemb("./../mem/CA_PRN_25.mem", ca_code[24]);
            // $readmemb("./../mem/CA_PRN_26.mem", ca_code[25]);
            // $readmemb("./../mem/CA_PRN_27.mem", ca_code[26]);
            // $readmemb("./../mem/CA_PRN_28.mem", ca_code[27]);
            // $readmemb("./../mem/CA_PRN_29.mem", ca_code[28]);
            // $readmemb("./../mem/CA_PRN_30.mem", ca_code[29]);
            // $readmemb("./../mem/CA_PRN_31.mem", ca_code[30]);
            // $readmemb("./../mem/CA_PRN_32.mem", ca_code[31]);
        end

        initial begin
            $readmemb("./../mem/CA_FFT_PRN_01.mem", expected_output[0]);
            $readmemb("./../mem/CA_FFT_PRN_02.mem", expected_output[1]);
            $readmemb("./../mem/CA_FFT_PRN_03.mem", expected_output[2]);
            $readmemb("./../mem/CA_FFT_PRN_04.mem", expected_output[3]);
            $readmemb("./../mem/CA_FFT_PRN_05.mem", expected_output[4]);
            $readmemb("./../mem/CA_FFT_PRN_06.mem", expected_output[5]);
            $readmemb("./../mem/CA_FFT_PRN_07.mem", expected_output[6]);
            $readmemb("./../mem/CA_FFT_PRN_08.mem", expected_output[7]);
            $readmemb("./../mem/CA_FFT_PRN_09.mem", expected_output[8]);
            $readmemb("./../mem/CA_FFT_PRN_10.mem", expected_output[9]);
            $readmemb("./../mem/CA_FFT_PRN_11.mem", expected_output[10]);
            $readmemb("./../mem/CA_FFT_PRN_12.mem", expected_output[11]);
            $readmemb("./../mem/CA_FFT_PRN_13.mem", expected_output[12]);
            $readmemb("./../mem/CA_FFT_PRN_14.mem", expected_output[13]);
            $readmemb("./../mem/CA_FFT_PRN_15.mem", expected_output[14]);
            $readmemb("./../mem/CA_FFT_PRN_16.mem", expected_output[15]);
            $readmemb("./../mem/CA_FFT_PRN_17.mem", expected_output[16]);
            $readmemb("./../mem/CA_FFT_PRN_18.mem", expected_output[17]);
            $readmemb("./../mem/CA_FFT_PRN_19.mem", expected_output[18]);
            $readmemb("./../mem/CA_FFT_PRN_20.mem", expected_output[19]);
            $readmemb("./../mem/CA_FFT_PRN_21.mem", expected_output[20]);
            $readmemb("./../mem/CA_FFT_PRN_22.mem", expected_output[21]);
            $readmemb("./../mem/CA_FFT_PRN_23.mem", expected_output[22]);
            $readmemb("./../mem/CA_FFT_PRN_24.mem", expected_output[23]);
            $readmemb("./../mem/CA_FFT_PRN_25.mem", expected_output[24]);
            $readmemb("./../mem/CA_FFT_PRN_26.mem", expected_output[25]);
            $readmemb("./../mem/CA_FFT_PRN_27.mem", expected_output[26]);
            $readmemb("./../mem/CA_FFT_PRN_28.mem", expected_output[27]);
            $readmemb("./../mem/CA_FFT_PRN_29.mem", expected_output[28]);
            $readmemb("./../mem/CA_FFT_PRN_30.mem", expected_output[29]);
            $readmemb("./../mem/CA_FFT_PRN_31.mem", expected_output[30]);
            $readmemb("./../mem/CA_FFT_PRN_32.mem", expected_output[31]);
            $readmemb("./../mem/CA_FFT_PRN_01.mem", expected_output[32]);

        end

        task inp_assignment (input index);
            for(int i=0; i<FFT_SIZE; i++) begin
                c1;
                // if(i==0) begin
                //     i_sync = 1'b1;
                // end
                // else begin
                //     i_sync = 1'b0;
                // end
                i_vld = 1'b1;
                i_data.data_re = ca_code[index][i];
                i_data.data_im =  17'b0;
            end
        endtask

        initial begin
            // #1800000
            #200000
            $display("HAHAHA\n");
            -> simulation_end;
        end

        initial begin
            #0
            $display("HAHA\n");
            i_sync_rst = 1'b0;
            rst_n = 1'b0;
            i_vld = 1'b0;
            // i_sync = 1'b0;
            c1;
            rst_n = 1'b1;
            #9
            // for(int k=0; k<32; k++) begin
            for(int k=0; k<1; k++) begin
                for(int i=0; i<FFT_SIZE; i++) begin
                    c1;
                    // if(i==0) begin
                    //     i_sync = 1'b1;
                    // end
                    // else begin
                    //     i_sync = 1'b0;
                    // end
                    i_vld = 1'b1;
                    // i_data.data_re = ca_code[k][i];
                    // i_data.data_re = ca_code[0][i];
                    // i_data.data_im =  17'b0;
                    // i_data.data_re = {{11{ca_code[0][i][33]}},ca_code[0][i][33:17]};
                    i_data.data_re = {{12{ca_code[0][i][15]}},ca_code[0][i]};
                    i_data.data_im =  28'b0;
                    // i_data.data_im = {{11{ca_code[0][i][16]}},ca_code[0][i][16:0]};
                end
            end
            c1;
            i_vld = 1'b0;
        end


        int counter = 0;
        data_t temp;
        int flag = 0;

        bit flag_1m4;
        initial begin
            #1406900
            flag=0;
            flag_1m4 = 1'b1;
            i_sync_rst = 1'b1;
            c1;
            i_sync_rst = 1'b0;
            for(int i=0; i<FFT_SIZE; i++) begin
                c1;
                // if(i==0) begin
                //     i_sync = 1'b1;
                // end
                // else begin
                //     i_sync = 1'b0;
                // end
                i_vld = 1'b1;
                i_data.data_re = ca_code[0][i];
                // i_data.data_re = ca_code[1][i];
                i_data.data_im =  17'b0;
            end
            c1;
            i_vld=1'b0;
        end

        initial begin
            forever begin
                @(posedge clk) begin
                    if(flag_1m4) begin
                        // if(o_sync) begin
                        //     if(flag==0) begin
                        //         flag = 1;
                        //     end
                        //     else begin
                        //         counter = counter + 1;
                        //     end
                        // end
                        if(o_vld) begin
                            temp.data_re = o_data.data_re;
                            temp.data_im = o_data.data_im;
                            actual_output[counter].push_back(temp);
                        end
                    end
                    else begin
                        // if(o_sync) begin
                        //     if(flag==0) begin
                        //         flag = 1;
                        //     end
                        //     else begin
                        //         counter = counter + 1;
                        //     end
                        // end
                        if(o_vld) begin
                            temp.data_re = o_data.data_re;
                            temp.data_im = o_data.data_im;
                            actual_output[counter].push_back(temp);
                        end
                    end
                end
            end
        end

        bit signed      [17:0]  difference_re;
        bit signed      [17:0]  difference_im;
        logic           [FRAC_BIT-1:0]  max_diff;
        rec_diff_re     rec_dif_re [0:31];
        rec_max_diff_re rec_max_dif_re;
        rec_diff_im     rec_dif_im [0:31];
        rec_max_diff_im rec_max_dif_im;
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
        initial @(simulation_end) begin
            
            max_diff = $ceil(0.00024 * (2**FRAC_BIT));  // 1/4096

            $display("\nmax_diff used: %f", (real'((max_diff))/real'(2**FRAC_BIT)));
            // for(int i=0; i<32; i++) begin
            // for(int i=0; i<33; i++) begin
            for(int i=0; i<1; i++) begin
                for(int j=0; j<4096; j++) begin
                    // difference_re = $signed(actual_output[i][j].data_re - expected_output[i][j].data_re);
                    // difference_im = $signed(actual_output[i][j].data_im - expected_output[i][j].data_im);
                    difference_re = $signed(actual_output[i][j].data_re - expected_output[0][j].data_re);
                    difference_im = $signed(actual_output[i][j].data_im - expected_output[0][j].data_im);

                    if(difference_re < 0) begin
                        difference_re = -difference_re;
                    end

                    if(difference_im < 0) begin
                        difference_im = -difference_im;
                    end

                    if(difference_re > max_diff || difference_im > max_diff) begin
                        simulation_fail = 1;
                        dif_float_re = difference_re / 32768.0;
                        dif_float_re = difference_im / 32768.0;
                        // $display("\nWrong OUTPUT: actual_output_re[%0d][%0d] = %b, expected_output_re[%0d][%0d] = %b, diff = %f", i, j,actual_output[i][j].data_re, i, j, expected_output[i][j].data_re, dif_float_re);
                        // $display("\nWrong OUTPUT: actual_output_im[%0d][%0d] = %b, expected_output_im[%0d][%0d] = %b, diff = %f", i, j,actual_output[i][j].data_im, i, j, expected_output[i][j].data_im, dif_float_im);
                        $display("\nWrong OUTPUT: actual_output_re[%0d][%0d] = %b, expected_output_re[%0d][%0d] = %b, diff = %f", i, j, actual_output[i][j].data_re, i, j, expected_output[0][j].data_re, dif_float_re);
                        $display("\nWrong OUTPUT: actual_output_im[%0d][%0d] = %b, expected_output_im[%0d][%0d] = %b, diff = %f", i, j, actual_output[i][j].data_im, i, j, expected_output[0][j].data_im, dif_float_im);
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
            $display("\n######################################################");
            $display("\n---------------- Max diff (for each satellite) ----------------");
            // for(int i=0; i<32; i++) begin
            // for(int i=0; i<33; i++) begin
            for(int i=0; i<1; i++) begin
                real float_value_re;
                real float_value_im;
                float_value_re = rec_dif_re[i].max_diff_current / 32768.0;
                float_value_im = rec_dif_im[i].max_diff_current / 32768.0;
                // $display("\nSatellite %0d: %f at index: %0d", i, float_value, rec_diff_re[i].max_diff_id);
                $display("\nSatellite %0d | Max Real: %f at index: %0d | Max Imaginary: %f at index: %0d", i, float_value_re, rec_dif_re[i].max_diff_id, float_value_im, rec_dif_im[i].max_diff_id);
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
    `endif

endmodule
