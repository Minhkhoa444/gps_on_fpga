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
    // logic   signed  [31:0]  expected_output [0:40][0:4095];
    // logic   signed  [31:0]  actual_output   [0:40][$];
    logic   signed  [15:0]  expected_cos    [0:40][0:4095];
    logic   signed  [15:0]  expected_sin    [0:40][0:4095];
    logic   signed  [15:0]  actual_cos      [0:40][$];
    logic   signed  [15:0]  actual_sin      [0:40][$];

    initial begin
        $readmemb("../mem/acc_cord_res/doppler_cos_0.mem", expected_cos[40]);
        $readmemb("../mem/acc_cord_res/doppler_cos_250.mem", expected_cos[39]);
        $readmemb("../mem/acc_cord_res/doppler_cos_500.mem", expected_cos[38]);
        $readmemb("../mem/acc_cord_res/doppler_cos_750.mem", expected_cos[37]);
        $readmemb("../mem/acc_cord_res/doppler_cos_1000.mem", expected_cos[36]);
        $readmemb("../mem/acc_cord_res/doppler_cos_1250.mem", expected_cos[35]);
        $readmemb("../mem/acc_cord_res/doppler_cos_1500.mem", expected_cos[34]);
        $readmemb("../mem/acc_cord_res/doppler_cos_1750.mem", expected_cos[33]);
        $readmemb("../mem/acc_cord_res/doppler_cos_2000.mem", expected_cos[32]);
        $readmemb("../mem/acc_cord_res/doppler_cos_2250.mem", expected_cos[31]);
        $readmemb("../mem/acc_cord_res/doppler_cos_2500.mem", expected_cos[30]);
        $readmemb("../mem/acc_cord_res/doppler_cos_2750.mem", expected_cos[29]);
        $readmemb("../mem/acc_cord_res/doppler_cos_3000.mem", expected_cos[28]);
        $readmemb("../mem/acc_cord_res/doppler_cos_3250.mem", expected_cos[27]);
        $readmemb("../mem/acc_cord_res/doppler_cos_3500.mem", expected_cos[26]);
        $readmemb("../mem/acc_cord_res/doppler_cos_3750.mem", expected_cos[25]);
        $readmemb("../mem/acc_cord_res/doppler_cos_4000.mem", expected_cos[24]);
        $readmemb("../mem/acc_cord_res/doppler_cos_4250.mem", expected_cos[23]);
        $readmemb("../mem/acc_cord_res/doppler_cos_4500.mem", expected_cos[22]);
        $readmemb("../mem/acc_cord_res/doppler_cos_4750.mem", expected_cos[21]);
        $readmemb("../mem/acc_cord_res/doppler_cos_5000.mem", expected_cos[20]);
        $readmemb("../mem/acc_cord_res/doppler_cos_5250.mem", expected_cos[19]);
        $readmemb("../mem/acc_cord_res/doppler_cos_5500.mem", expected_cos[18]);
        $readmemb("../mem/acc_cord_res/doppler_cos_5750.mem", expected_cos[17]);
        $readmemb("../mem/acc_cord_res/doppler_cos_6000.mem", expected_cos[16]);
        $readmemb("../mem/acc_cord_res/doppler_cos_6250.mem", expected_cos[15]);
        $readmemb("../mem/acc_cord_res/doppler_cos_6500.mem", expected_cos[14]);
        $readmemb("../mem/acc_cord_res/doppler_cos_6750.mem", expected_cos[13]);
        $readmemb("../mem/acc_cord_res/doppler_cos_7000.mem", expected_cos[12]);
        $readmemb("../mem/acc_cord_res/doppler_cos_7250.mem", expected_cos[11]);
        $readmemb("../mem/acc_cord_res/doppler_cos_7500.mem", expected_cos[10]);
        $readmemb("../mem/acc_cord_res/doppler_cos_7750.mem", expected_cos[9]);
        $readmemb("../mem/acc_cord_res/doppler_cos_8000.mem", expected_cos[8]);
        $readmemb("../mem/acc_cord_res/doppler_cos_8250.mem", expected_cos[7]);
        $readmemb("../mem/acc_cord_res/doppler_cos_8500.mem", expected_cos[6]);
        $readmemb("../mem/acc_cord_res/doppler_cos_8750.mem", expected_cos[5]);
        $readmemb("../mem/acc_cord_res/doppler_cos_9000.mem", expected_cos[4]);
        $readmemb("../mem/acc_cord_res/doppler_cos_9250.mem", expected_cos[3]);
        $readmemb("../mem/acc_cord_res/doppler_cos_9500.mem", expected_cos[2]);
        $readmemb("../mem/acc_cord_res/doppler_cos_9750.mem", expected_cos[1]);
        $readmemb("../mem/acc_cord_res/doppler_cos_10000.mem", expected_cos[0]);

        $readmemb("../mem/acc_cord_res/doppler_sin_0.mem", expected_sin[40]);
        $readmemb("../mem/acc_cord_res/doppler_sin_250.mem", expected_sin[39]);
        $readmemb("../mem/acc_cord_res/doppler_sin_500.mem", expected_sin[38]);
        $readmemb("../mem/acc_cord_res/doppler_sin_750.mem", expected_sin[37]);
        $readmemb("../mem/acc_cord_res/doppler_sin_1000.mem", expected_sin[36]);
        $readmemb("../mem/acc_cord_res/doppler_sin_1250.mem", expected_sin[35]);
        $readmemb("../mem/acc_cord_res/doppler_sin_1500.mem", expected_sin[34]);
        $readmemb("../mem/acc_cord_res/doppler_sin_1750.mem", expected_sin[33]);
        $readmemb("../mem/acc_cord_res/doppler_sin_2000.mem", expected_sin[32]);
        $readmemb("../mem/acc_cord_res/doppler_sin_2250.mem", expected_sin[31]);
        $readmemb("../mem/acc_cord_res/doppler_sin_2500.mem", expected_sin[30]);
        $readmemb("../mem/acc_cord_res/doppler_sin_2750.mem", expected_sin[29]);
        $readmemb("../mem/acc_cord_res/doppler_sin_3000.mem", expected_sin[28]);
        $readmemb("../mem/acc_cord_res/doppler_sin_3250.mem", expected_sin[27]);
        $readmemb("../mem/acc_cord_res/doppler_sin_3500.mem", expected_sin[26]);
        $readmemb("../mem/acc_cord_res/doppler_sin_3750.mem", expected_sin[25]);
        $readmemb("../mem/acc_cord_res/doppler_sin_4000.mem", expected_sin[24]);
        $readmemb("../mem/acc_cord_res/doppler_sin_4250.mem", expected_sin[23]);
        $readmemb("../mem/acc_cord_res/doppler_sin_4500.mem", expected_sin[22]);
        $readmemb("../mem/acc_cord_res/doppler_sin_4750.mem", expected_sin[21]);
        $readmemb("../mem/acc_cord_res/doppler_sin_5000.mem", expected_sin[20]);
        $readmemb("../mem/acc_cord_res/doppler_sin_5250.mem", expected_sin[19]);
        $readmemb("../mem/acc_cord_res/doppler_sin_5500.mem", expected_sin[18]);
        $readmemb("../mem/acc_cord_res/doppler_sin_5750.mem", expected_sin[17]);
        $readmemb("../mem/acc_cord_res/doppler_sin_6000.mem", expected_sin[16]);
        $readmemb("../mem/acc_cord_res/doppler_sin_6250.mem", expected_sin[15]);
        $readmemb("../mem/acc_cord_res/doppler_sin_6500.mem", expected_sin[14]);
        $readmemb("../mem/acc_cord_res/doppler_sin_6750.mem", expected_sin[13]);
        $readmemb("../mem/acc_cord_res/doppler_sin_7000.mem", expected_sin[12]);
        $readmemb("../mem/acc_cord_res/doppler_sin_7250.mem", expected_sin[11]);
        $readmemb("../mem/acc_cord_res/doppler_sin_7500.mem", expected_sin[10]);
        $readmemb("../mem/acc_cord_res/doppler_sin_7750.mem", expected_sin[9]);
        $readmemb("../mem/acc_cord_res/doppler_sin_8000.mem", expected_sin[8]);
        $readmemb("../mem/acc_cord_res/doppler_sin_8250.mem", expected_sin[7]);
        $readmemb("../mem/acc_cord_res/doppler_sin_8500.mem", expected_sin[6]);
        $readmemb("../mem/acc_cord_res/doppler_sin_8750.mem", expected_sin[5]);
        $readmemb("../mem/acc_cord_res/doppler_sin_9000.mem", expected_sin[4]);
        $readmemb("../mem/acc_cord_res/doppler_sin_9250.mem", expected_sin[3]);
        $readmemb("../mem/acc_cord_res/doppler_sin_9500.mem", expected_sin[2]);
        $readmemb("../mem/acc_cord_res/doppler_sin_9750.mem", expected_sin[1]);
        $readmemb("../mem/acc_cord_res/doppler_sin_10000.mem", expected_sin[0]);
    end

    int dopp_id = 0;    // doppler_id init = 10kHz

    // initial begin
    //     #3400000
    //     // #50000
    //     $display("HAHAHA");
    //     -> simulation_end;
    // end

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
            repeat(4096) c1;
        end
    end

    int flag=0;
    logic   [11:0] counter;
    int doppler_id=0;
    logic   [31:0]  temp;

    initial begin
        counter = 12'b0;
        forever begin
            @(posedge clk) begin
                if(o_vld) begin
                    actual_cos[doppler_id].push_back(o_cosine);
                    actual_sin[doppler_id].push_back(o_sine);
                    if(&counter[11:0]) begin
                        doppler_id = doppler_id + 1'b1;
                        if(doppler_id==40) begin
                            -> simulation_end;
                        end
                    end
                    counter = counter + 1'b1;
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

    real sum_squared_error_cos = 0.0;
    real sum_squared_error_sin = 0.0;
    real rmse_cos    [0:40];
    real rmse_sin    [0:40];
    real mean_value_cos[0:40];
    real mean_value_sin[0:40];

    initial @(simulation_end) begin
        max_diff = $ceil(0.001 * (2**15));  // 1/4096
        $display("\nmax_diff used: %f", (real'((max_diff))/real'(2**15)));
        for(int i = 0; i<41; i++) begin
        // for(int i = 0; i<1; i++) begin
            for(int j = 0; j<4096; j++) begin
                difference_cos = $signed(actual_cos[i][j] - expected_cos[i][j]);
                difference_sin = $signed(actual_sin[i][j] - expected_sin[i][j]);
                // difference_cos = $signed(actual_output[i][j][31:16] - expected_output[39][j][31:16]);
                // difference_sin = $signed(actual_output[i][j][15:0] - expected_output[39][j][15:0]);
                
                if(difference_cos < 0) begin
                    difference_cos = -difference_cos;
                end

                if(difference_sin < 0) begin
                    difference_sin = -difference_sin;
                end

                sum_squared_error_cos = sum_squared_error_cos + (difference_cos / 32768.0) * (difference_cos / 32768.0);
                sum_squared_error_sin = sum_squared_error_sin + (difference_sin / 32768.0) * (difference_sin / 32768.0);

                if(difference_cos > max_diff || difference_sin > max_diff) begin
                    simulation_fail = 1;
                    dif_float_cos = difference_cos / 32768.0;
                    dif_float_sin = difference_sin / 32768.0;
                    $display("\nWrong OUTPUT: actual_output_cos[%0d][%0d] = %b, expected_output_cos[%0d][%0d] = %b, diff = %f", i, j,actual_cos[i][j], i, j, expected_cos[i][j], dif_float_cos);
                    $display("\nWrong OUTPUT: actual_output_sin[%0d][%0d] = %b, expected_output_sin[%0d][%0d] = %b, diff = %f", i, j,actual_sin[i][j], i, j, expected_sin[i][j], dif_float_sin);
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

            rmse_cos[i] = $sqrt(sum_squared_error_cos/4096.0);
            rmse_sin[i] = $sqrt(sum_squared_error_sin/4096.0);

            sum_squared_error_cos = 0.0;
            sum_squared_error_sin = 0.0;

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

        for(int i=0; i<41; i++) begin
            mean_value_cos[i] = 0.0;
            mean_value_sin[i] = 0.0;
            for(int idx=0; idx<4096; idx++) begin
                mean_value_cos[i] = mean_value_cos[i] + (actual_cos[i][idx]<0 ? (-actual_cos[i][idx])/32768.0 : (actual_cos[i][idx])/32768.0);
                mean_value_sin[i] = mean_value_sin[i] + (actual_sin[i][idx]<0 ? (-actual_sin[i][idx])/32768.0 : (actual_sin[i][idx])/32768.0);
            end
            mean_value_cos[i] = mean_value_cos[i]/4096.0;
            mean_value_sin[i] = mean_value_sin[i]/4096.0;
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
            if(i>=10) begin
                $display("              | RMSE Cos: %f | RMSE Sin: %f | NRMSE Cos: %f | NRMSE Sin: %f", rmse_cos[i], rmse_sin[i], rmse_cos[i]/mean_value_cos[i], rmse_sin[i]/mean_value_sin[i]);
            end
            else begin
                $display("             | RMSE Cos: %f | RMSE Sin: %f | NRMSE Cos: %f | NRMSE Sin: %f", rmse_cos[i], rmse_sin[i], rmse_cos[i]/mean_value_cos[i], rmse_sin[i]/mean_value_sin[i]);
            end
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
