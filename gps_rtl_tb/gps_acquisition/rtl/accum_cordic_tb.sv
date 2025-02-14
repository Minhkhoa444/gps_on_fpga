`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/13/2025 06:49:54 PM
// Design Name: 
// Module Name: accum_cordic_tb
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


module accum_cordic_tb;
    logic                   clk;
    logic                   rst_n;

    logic                   i_start;
    logic   [5:0]           i_doppler_id;

    logic                   o_vld;
    logic   signed  [15:0]  o_cosine;
    logic   signed  [15:0]  o_sine;

    task c1;
        @(posedge clk);
        #0.3;
    endtask

    accum_cordic dut(.*);

    initial begin
        #0 clk = 1'b1;
        forever #5 clk = ~clk; 
    end

    event simulation_end;
    logic   signed  [31:0]  expected_output [0:40][0:3999];
    logic   signed  [31:0]  actual_output   [0:40][$];

    initial begin
        $readmemb("./../mem/doppler_10000Hz.mem", expected_output[0]);
        $readmemb("./../mem/doppler_9750Hz.mem", expected_output[1]);
        $readmemb("./../mem/doppler_9500Hz.mem", expected_output[2]);
        $readmemb("./../mem/doppler_9250Hz.mem", expected_output[3]);
        $readmemb("./../mem/doppler_9000Hz.mem", expected_output[4]);
        $readmemb("./../mem/doppler_8750Hz.mem", expected_output[5]);
        $readmemb("./../mem/doppler_8500Hz.mem", expected_output[6]);
        $readmemb("./../mem/doppler_8250Hz.mem", expected_output[7]);
        $readmemb("./../mem/doppler_8000Hz.mem", expected_output[8]);
        $readmemb("./../mem/doppler_7750Hz.mem", expected_output[9]);
        $readmemb("./../mem/doppler_7500Hz.mem", expected_output[10]);
        $readmemb("./../mem/doppler_7250Hz.mem", expected_output[11]);
        $readmemb("./../mem/doppler_7000Hz.mem", expected_output[12]);
        $readmemb("./../mem/doppler_6750Hz.mem", expected_output[13]);
        $readmemb("./../mem/doppler_6500Hz.mem", expected_output[14]);
        $readmemb("./../mem/doppler_6250Hz.mem", expected_output[15]);
        $readmemb("./../mem/doppler_6000Hz.mem", expected_output[16]);
        $readmemb("./../mem/doppler_5750Hz.mem", expected_output[17]);
        $readmemb("./../mem/doppler_5500Hz.mem", expected_output[18]);
        $readmemb("./../mem/doppler_5250Hz.mem", expected_output[19]);
        $readmemb("./../mem/doppler_5000Hz.mem", expected_output[20]);
        $readmemb("./../mem/doppler_4750Hz.mem", expected_output[21]);
        $readmemb("./../mem/doppler_4500Hz.mem", expected_output[22]);
        $readmemb("./../mem/doppler_4250Hz.mem", expected_output[23]);
        $readmemb("./../mem/doppler_4000Hz.mem", expected_output[24]);
        $readmemb("./../mem/doppler_3750Hz.mem", expected_output[25]);
        $readmemb("./../mem/doppler_3500Hz.mem", expected_output[26]);
        $readmemb("./../mem/doppler_3250Hz.mem", expected_output[27]);
        $readmemb("./../mem/doppler_3000Hz.mem", expected_output[28]);
        $readmemb("./../mem/doppler_2750Hz.mem", expected_output[29]);
        $readmemb("./../mem/doppler_2500Hz.mem", expected_output[30]);
        $readmemb("./../mem/doppler_2250Hz.mem", expected_output[31]);
        $readmemb("./../mem/doppler_2000Hz.mem", expected_output[32]);
        $readmemb("./../mem/doppler_1750Hz.mem", expected_output[33]);
        $readmemb("./../mem/doppler_1500Hz.mem", expected_output[34]);
        $readmemb("./../mem/doppler_1250Hz.mem", expected_output[35]);
        $readmemb("./../mem/doppler_1000Hz.mem", expected_output[36]);
        $readmemb("./../mem/doppler_750Hz.mem", expected_output[37]);
        $readmemb("./../mem/doppler_500Hz.mem", expected_output[38]);
        $readmemb("./../mem/doppler_250Hz.mem", expected_output[39]);
        $readmemb("./../mem/doppler_0Hz.mem", expected_output[40]);
    end

    int dopp_id = 0;    // doppler_id init = 10kHz

    initial begin
        #3400000
        // #50000
        $display("HAHAHA");
        -> simulation_end;
    end

    initial begin
        #0 rst_n = 1'b0;
        i_start = 1'b0;
        i_doppler_id = 5'b00000;
        #20 rst_n = 1'b1;
        for(int i = 0; i < 41; i++) begin
            c1;
            i_start = 1'b1;
            i_doppler_id = i;
            // i_doppler_id = 39;
            c1;
            i_start = 1'b0;
            repeat(4009) c1;
        end
    end

    int flag=0;
    int counter=0;
    int doppler_id=0;
    logic   [31:0]  temp;

    initial begin
        forever begin
            @(posedge clk) begin
                if(o_vld) begin
                    temp = {o_cosine, o_sine};
                    actual_output[doppler_id].push_back(temp);
                    counter = counter + 1;
                    if(counter==4000) begin
                        doppler_id = doppler_id + 1;
                        counter = 0;
                    end
                end
            end
        end
    end

    bit signed      [15:0]  difference_cos;
    bit signed      [15:0]  difference_sin;
    logic           [15:0]  max_diff;
    bit                     simulation_fail;
    real                    dif_float_cos;
    real                    dif_float_sin;
    real                    max_diff_all_cos;
    real                    max_diff_all_sin;
    logic           [15:0]  max_diff_all_cos_bin;
    logic           [5:0]   max_diff_all_cos_dopid;
    logic           [11:0]  max_diff_all_cos_id;
    logic           [15:0]  max_diff_all_sin_bin;
    logic           [5:0]   max_diff_all_sin_dopid;
    logic           [11:0]  max_diff_all_sin_id;
    logic           [15:0]  max_diff_each_cos       [0:40];
    logic           [5:0]   max_diff_each_cos_id    [0:40];
    logic           [15:0]  max_diff_each_sin       [0:40];
    logic           [5:0]   max_diff_each_sin_id    [0:40];

    genvar i;
    generate
        for(i=0; i<41; i++) begin
            assign max_diff_each_cos[i] = 0;
            assign max_diff_each_cos_id[i]= 0;
            assign max_diff_each_sin[i] = 0;
            assign max_diff_each_sin_id[i]= 0;
        end
    endgenerate

    assign max_diff_all_cos_bin = 0;
    assign max_diff_all_cos_dopid = 0;
    assign max_diff_all_cos_id = 0;
    assign max_diff_all_sin_bin = 0;
    assign max_diff_all_sin_dopid = 0;
    assign max_diff_all_sin_id = 0;

    initial @(simulation_end) begin
        max_diff = $ceil(0.001 * (2**15));  // 1/4096
        $display("\nmax_diff used: %f", (real'((max_diff))/real'(2**15)));
        for(int i = 0; i<41; i++) begin
        // for(int i = 0; i<1; i++) begin
            for(int j = 0; j<4000; j++) begin
                difference_cos = $signed(actual_output[i][j][31:16] - expected_output[i][j][31:16]);
                difference_sin = $signed(actual_output[i][j][15:0] - expected_output[i][j][15:0]);
                // difference_cos = $signed(actual_output[i][j][31:16] - expected_output[39][j][31:16]);
                // difference_sin = $signed(actual_output[i][j][15:0] - expected_output[39][j][15:0]);
                
                if(difference_cos < 0) begin
                    difference_cos = -difference_cos;
                end

                if(difference_sin < 0) begin
                    difference_sin = -difference_sin;
                end

                if(difference_cos > max_diff || difference_sin > max_diff) begin
                    simulation_fail = 1;
                    dif_float_cos = difference_cos / 32768.0;
                    dif_float_sin = difference_sin / 32768.0;
                    $display("\nWrong OUTPUT: actual_output_cos[%0d][%0d] = %b, expected_output_cos[%0d][%0d] = %b, diff = %0d", i, j,actual_output[i][j][31:16], i, j, expected_output[i][j][31:16], dif_float_cos);
                    $display("\nWrong OUTPUT: actual_output_sin[%0d][%0d] = %b, expected_output_sin[%0d][%0d] = %b, diff = %0d", i, j,actual_output[i][j][15:0], i, j, expected_output[i][j][15:0], dif_float_sin);
                    // $display("\nWrong OUTPUT: actual_output_re[%0d][%0d] = %b, expected_output_re[%0d][%0d] = %b, diff = %f", i, j, actual_output[i][j][31:16], i, j, expected_output[39][j][31:16], dif_float_cos);
                    // $display("\nWrong OUTPUT: actual_output_im[%0d][%0d] = %b, expected_output_im[%0d][%0d] = %b, diff = %f", i, j, actual_output[i][j][15:0], i, j, expected_output[39][j][15:0], dif_float_sin);
                    break;
                end

                // Update current max diff (for each satellite)
                if(difference_cos >= max_diff_each_cos[i]) begin
                    max_diff_each_cos[i] = difference_cos;
                    max_diff_each_cos_id[i] = j;
                end

                if(difference_sin >= max_diff_each_sin[i]) begin
                    max_diff_each_sin[i] = difference_sin;
                    max_diff_each_sin_id[i] = j;
                end
            end
            // Update max diff all time
            if(max_diff_each_cos[i] >= max_diff_all_cos_bin) begin
                max_diff_all_cos_bin = max_diff_each_cos[i];
                max_diff_all_cos_dopid = i;
                max_diff_all_cos_id = max_diff_each_cos_id[i];
            end

            if(max_diff_each_sin[i] >= max_diff_all_sin_bin) begin
                max_diff_all_sin_bin = max_diff_each_sin[i];
                max_diff_all_sin_dopid = i;
                max_diff_all_sin_id = max_diff_each_sin_id[i];
            end
            if(simulation_fail) break;
        end
        $display("\n######################################################");
        $display("\n---------------- Max diff (for each satellite) ----------------");
        for(int i=0; i<41; i++) begin
        // for(int i=0; i<1; i++) begin
            real float_value_cos;
            real float_value_sin;
            float_value_cos = max_diff_each_cos[i] / 32768.0;
            float_value_sin = max_diff_each_sin[i] / 32768.0;
            // $display("\nSatellite %0d: %f at index: %0d", i, float_value, rec_diff_re[i].max_diff_id);
            $display("\nDoppler ID %0d | Max Cos: %f at index: %0d | Max Sin: %f at index: %0d", i, float_value_cos, max_diff_each_cos[i], float_value_sin, max_diff_each_sin[i]);
        end
        $display("\n---------------------------------------------------------------");
        max_diff_all_cos = max_diff_all_cos_bin / 32768.0;
        max_diff_all_sin = max_diff_all_sin_bin / 32768.0;
        $display("\nMax diff all time | Cos: %f at index %0d of Doppler ID %0d | Sin: %f at index %0d of Doppler ID %0d", max_diff_all_cos, max_diff_all_cos_id, max_diff_all_cos_dopid, max_diff_all_sin, max_diff_all_sin_id, max_diff_all_sin_dopid);
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
