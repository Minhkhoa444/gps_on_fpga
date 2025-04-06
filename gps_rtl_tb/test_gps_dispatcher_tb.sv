`timescale 1ns/1ps
module test_gps_dispatcher_tb;
    bit aclk;
    bit aresetn;
    
    bit acquisition_valid;
    bit [15:0] correlation_result;
    bit [15:0] doppler_freq;
    bit [15:0] code_delay;
    bit [4:0]  prn_id;
    bit [4:0]  store_prn_id [0:3];
    localparam DAT_WIDTH = 16;


    bit signed [DAT_WIDTH-1:0] ca_code_expected [0:31][0:4095];
    test_gps_dispatcher dut(
        .aclk(aclk),
        .aresetn(aresetn),
        .prn_id(prn_id),
        .acquisition_valid(acquisition_valid),
        .correlation_result(correlation_result),
        .doppler_freq(doppler_freq),
        .code_delay(code_delay)
    );

    initial begin
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_01.mem", ca_code_expected[0]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_02.mem", ca_code_expected[1]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_03.mem", ca_code_expected[2]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_04.mem", ca_code_expected[3]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_05.mem", ca_code_expected[4]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_06.mem", ca_code_expected[5]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_07.mem", ca_code_expected[6]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_08.mem", ca_code_expected[7]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_09.mem", ca_code_expected[8]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_10.mem", ca_code_expected[9]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_11.mem", ca_code_expected[10]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_12.mem", ca_code_expected[11]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_13.mem", ca_code_expected[12]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_14.mem", ca_code_expected[13]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_15.mem", ca_code_expected[14]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_16.mem", ca_code_expected[15]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_17.mem", ca_code_expected[16]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_18.mem", ca_code_expected[17]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_19.mem", ca_code_expected[18]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_20.mem", ca_code_expected[19]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_21.mem", ca_code_expected[20]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_22.mem", ca_code_expected[21]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_23.mem", ca_code_expected[22]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_24.mem", ca_code_expected[23]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_25.mem", ca_code_expected[24]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_26.mem", ca_code_expected[25]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_27.mem", ca_code_expected[26]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_28.mem", ca_code_expected[27]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_29.mem", ca_code_expected[28]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_30.mem", ca_code_expected[29]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_31.mem", ca_code_expected[30]);
        $readmemb("../gps_rtl/gps_acquisition/mem/CA_PRN_32.mem", ca_code_expected[31]);
    end


    initial begin
        aclk = 0;
        forever begin
            aclk = #10 ~aclk;
        end
    end

    initial begin
        aresetn = 0;
        #20;
        aresetn = 1;
    end

    integer i;
    integer pass;
    initial begin
        pass = 1;
        acquisition_valid = 0;
        @(posedge aresetn);
        for (i = 1;i <= 4;i ++) begin
            @(posedge aclk);
            acquisition_valid = 1;
            prn_id = $urandom;
            store_prn_id[i-1] = prn_id;
            correlation_result = i;
            doppler_freq = i;
            code_delay = i;
        end
        @(posedge aclk);
        acquisition_valid = 0;
        @(posedge aclk);
        @(posedge aclk);
        @(posedge aclk);
        for (i = 0; i < 4096; i++) begin
            @(posedge aclk);
            if (dut.dut1.bram.early_prn_tracker_0[i] != ca_code_expected[store_prn_id[0]][i]) begin
                $display("Tracker 0 Fail at sample %0d, got: %h, expected: %h", i,
                        dut.dut1.bram.early_prn_tracker_0[i],
                        ca_code_expected[store_prn_id[0]-1][i]);
                pass = 0;
                break;
            end else if (dut.dut1.bram.early_prn_tracker_1[i] != ca_code_expected[store_prn_id[1]][i]) begin
                $display("Tracker 1 Fail at sample %0d, got: %h, expected: %h", i,
                        dut.dut1.bram.early_prn_tracker_1[i],
                        ca_code_expected[store_prn_id[1]-1][i]);
                pass = 0;
                break;
            end else if (dut.dut1.bram.early_prn_tracker_2[i] != ca_code_expected[store_prn_id[2]][i]) begin
                $display("Tracker 2 Fail at sample %0d, got: %h, expected: %h", i,
                        dut.dut1.bram.early_prn_tracker_2[i],
                        ca_code_expected[store_prn_id[2]-1][i]);
                pass = 0;
                break;
            end else if (dut.dut1.bram.early_prn_tracker_3[i] != ca_code_expected[store_prn_id[3]][i]) begin
                $display("Tracker 3 Fail at sample %0d, got: %h, expected: %h", i,
                        dut.dut1.bram.early_prn_tracker_3[i],
                        ca_code_expected[store_prn_id[3]-1][i]);
                pass = 0;
                break;
            end
        end
        if (pass) begin
            $display("Passed");
        end else $display ("Failed");
        for (i = 0;i < 4;i ++) begin
            $display(store_prn_id[i]);
        end
        $finish;
    end
endmodule