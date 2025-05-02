`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/24/2025 07:34:24 PM
// Design Name: 
// Module Name: gps_acquisition_tb
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

`define ADD
module gps_acquisition_pick_tb;
    logic                   clk;
    logic                   rst_n;

    // input data from sdr and output tready to sdr
    logic                   s_axis_tvalid;      // tvalid
    logic   signed  [15:0]  s_axis_tdata_i;     // gps_i
    logic   signed  [15:0]  s_axis_tdata_q;     // gps_q
    // logic                   m_axis_tready;      // tready from dispatcher
    
    // input tready, output data from/to gps_dispatcher
    logic                   s_axis_tready;      // tready

    logic                   o_vld;
    logic   signed  [15:0]  o_corr_result;
    logic   signed  [14:0]  o_doppler_shift;
    logic   [11:0]          o_code_phase_delay;
    logic   [4:0]           o_prn_id;
    // logic                   o_vld;
    // logic   signed  [14:0]  o_doppler_shift_0;
    // logic           [11:0]  o_code_phase_delay_0;
    // logic           [4:0]   o_prn_id_0;

    // logic   signed  [14:0]  o_doppler_shift_1;
    // logic           [11:0]  o_code_phase_delay_1;
    // logic           [4:0]   o_prn_id_1;

    // logic   signed  [14:0]  o_doppler_shift_2;
    // logic           [11:0]  o_code_phase_delay_2;
    // logic           [4:0]   o_prn_id_2;

    // logic   signed  [14:0]  o_doppler_shift_3;
    // logic           [11:0]  o_code_phase_delay_3;
    // logic           [4:0]   o_prn_id_3;


    logic                   m_axis_tvalid;      // tvalid to dispatcher
    `ifdef ADD
        logic   signed  [15:0]  m_axis_tdata;
    `else
        logic   signed  [15:0]  m_axis_tdata_im;    // imaginary part of ifft output    (corr result - imaginary)
        logic   signed  [15:0]  m_axis_tdata_re;    // real part of ifft output         (corr result - real)
    `endif
    logic           [4:0]   m_axis_tprn_id;     // prn id
    logic   signed  [14:0]  m_axis_td_shift;    // doppler shift
    logic           [11:0]  m_axis_tposition;   // code phase delay (just simply the position of the current ifft output
                                                // from this position, we can compute the code phase delay)
                                                // formula: (position/4096) * 1023

    gps_acquisition_wrapper_sv dut(.*);

    task c1;
        @(posedge clk);
        #0.3;
    endtask

    initial begin
        clk = 1'b1;
        forever begin
            #5 clk = ~clk;
        end
    end

    logic   signed  [15:0]  gps_i  [0:4095];
    logic   signed  [15:0]  gps_q  [0:4095];
    initial begin
        // spain gps
        $readmemb("../mem/gps_i_4096.mem",gps_i);
        $readmemb("../mem/gps_q_4096.mem",gps_q);

        // hanoi gps
        // $readmemb("../mem/hanoi/gps_i_4096.mem",gps_i);
        // $readmemb("../mem/hanoi/gps_q_4096.mem",gps_q);
    end

    initial begin
        #0 rst_n = 1'b0;
        s_axis_tvalid = 1'b0;
        c1;
        rst_n = 1'b1;
        for(int i=0; i<4096; i++) begin
            c1;
            if(i==0) begin
                $display("Start input at %t\n",$time);
            end
            s_axis_tvalid = 1'b1;
            s_axis_tdata_i = gps_i[i];
            s_axis_tdata_q = gps_q[i];
        end
        c1;
        s_axis_tvalid = 1'b0;
    end

    logic   [2:0]   counter;
    logic   [31:0]  timer;  
    initial begin
        timer=0;
        counter = 2'b00;
        forever begin
            @(posedge clk) begin
                // if(dut.acq.m_axis_td_shift == -2500 && dut.acq.m_axis_tposition == 4095 && dut.acq.m_axis_tprn_id == 31) begin
                //     -> simulation_end;
                // end
                if(~s_axis_tready) begin
                    timer = timer + 1'b1;
                end
                if(o_vld) begin
                    counter = counter + 1'b1;
                end
                if(counter >= 4) begin
                    -> simulation_end;
                end
                // if(o_vld) begin
                //     -> simulation_end;
                // end
            end
        end
    end

    bit start_ibuf_o_full;
    initial begin
        start_ibuf_o_full=0;
        forever begin
            @(posedge clk) begin
                if(dut.acq.ibuf_o_full && start_ibuf_o_full==0) begin
                    $display("Input Buffer Full At Time %t\r\n",$time);
                    start_ibuf_o_full = 1;
                end
            end
        end
    end

    bit flag_start;
    bit flag_end;
    // time starting;
    // time ending;
    initial begin
        flag_start = 'b0;
        flag_end = 'b0;
        forever begin
            @(posedge clk) begin
                if(dut.acq.ifft.i_vld && ~flag_start) begin
                    flag_start = 'b1;
                    $display("Starting input ifft: %t",$time);
                end
                
                if(dut.acq.ifft.o_vld && ~flag_end) begin
                    flag_end = 'b1;
                    $display("Starting output ifft: %t",$time);
                end
            end
        end
    end

    event simulation_end;
    typedef struct {
        `ifdef ADD
            logic   signed [15:0] correlation_result;
        `else
            real    correlation_result;
        `endif
        logic   signed [14:0] doppler_shift;
        logic   [11:0] code_phase_delay;
        logic   [4:0] prn_id;
    } result_t;

    typedef struct {
        logic   signed [14:0] doppler_shift;
        logic   [11:0] code_phase_delay;
        logic   [4:0] prn_id;
    } res_no_corr_t;

    logic   [1:0] counter_1;
    res_no_corr_t    top_4[0:3];
    initial begin
        counter_1 = 'b0;
        forever begin
            @(posedge clk) begin
                if(o_vld) begin
                    top_4[counter_1] = '{o_doppler_shift, o_code_phase_delay, o_prn_id};
                    // if(o_corr_result != sorted_mem[counter_1]) begin
                    //     $error("Mismatch at o_corr_result[%0d]: Expected %0d (%f), but got %0d(%f)", counter_1, sorted_mem[3],sorted_mem[3]/32768.0, o_corr_result, o_corr_result/32768.0);
                    // end
                    // else begin
                    //     $display("Correct: o_corr_result[%0d] = %0d(%f)", counter_1, o_corr_result, o_corr_result/32768.0);
                    // end
                    counter_1 = counter_1 + 1'b1;
                end
            end
        end
    end

    result_t max_each[0:31];
    result_t top_5[0:4];

    initial begin
        for(int i=0; i<32; i++) begin
            max_each[i] = '{0, 0, 0, 0};
        end
        for(int i=0; i<5; i++) begin
            top_5[i] = '{0, 0, 0, 0};
        end
    end

    real max_corr_abs_each[0:80][0:31];
    initial begin
        for(int i=0; i<81; i++) begin
            for(int j=0; j<32; j++) begin
                max_corr_abs_each[i][j] = 0;
            end
        end
    end
    logic signed [14:0] max_corr_d_shift_each[0:80][0:31];
    logic [11:0] max_corr_code_phase_each[0:80][0:31];
    logic [4:0] max_corr_prn_id_each[0:80][0:31];

    initial begin
        for(int i=0; i<81; i++) begin
            for(int j=0; j<32; j++) begin
                max_corr_d_shift_each[i][j] = 0;
                max_corr_code_phase_each[i][j] = 0;
                max_corr_prn_id_each[i][j] = 0;
            end
        end
    end

    real magnitude;

    logic   signed  [15:0]  corr_result [0:31][0:80][0:4095];
    int count_doppler;  // count_doppler = 0 -> d_shift = 10kHz

    initial begin
        count_doppler = 0;
        forever begin
            @(posedge clk) begin
                if(dut.acq.m_axis_tvalid) begin
                    `ifdef ADD
                        if(dut.acq.m_axis_tdata > max_each[dut.acq.m_axis_tprn_id].correlation_result) begin
                            max_each[dut.acq.m_axis_tprn_id] = '{dut.acq.m_axis_tdata, dut.acq.m_axis_td_shift, dut.acq.m_axis_tposition, dut.acq.m_axis_tprn_id};
                        end
                        corr_result[dut.acq.m_axis_tprn_id][count_doppler][dut.acq.m_axis_tposition] = dut.acq.m_axis_tdata;
                        if(dut.acq.m_axis_tposition == 4095 && dut.acq.m_axis_tprn_id == 31) begin
                            count_doppler = count_doppler + 1;
                        end
                    `else
                        real data_re;
                        real data_im;
                        data_re = $signed(m_axis_tdata_re) / (2.0**15);
                        data_re = data_re * data_re;
                        data_im = $signed(m_axis_tdata_im) / (2.0**15);
                        data_im = data_im * data_im;
                        magnitude = $sqrt(data_re + data_im);
                        if(magnitude > max_each[m_axis_tprn_id].correlation_result) begin
                            max_each[m_axis_tprn_id] = '{magnitude, m_axis_td_shift, m_axis_tposition, m_axis_tprn_id};
                        end
                    `endif
                end
            end
        end
    end

    int max_idx;
    result_t temp;
    real tmp;
    integer file_array[0:31];

    initial @(simulation_end) begin
        $display("############### RESULT ###############\n");
        $display("MATCHED PRN ID");
        for(int i=0; i<32; i++) begin
            $display("[========== PRN ID %d ==========]\n", i+1);
            `ifdef ADD
                tmp = $signed(max_each[i].correlation_result)/(2.0**15);
                $display("Peak correlation value: %f\n", tmp);
            `else
                $display("Peak correlation value: %f\n", max_each[i].correlation_result);
            `endif
            $display("Peak doppler shift: %0d\n", max_each[i].doppler_shift);
            $display("Peak code phase delay: %0d\n", max_each[i].code_phase_delay);
            $display("Peak prn id: %0d\n", (max_each[i].prn_id + 1));
            $display("[============================]\n");
        end
        for(int i=0; i<5; i++) begin
            max_idx = i;
            
            for(int j=i+1; j<32; j++) begin
                if(max_each[j].correlation_result > max_each[max_idx].correlation_result) begin
                    max_idx = j;
                end
            end

            temp = max_each[i];
            max_each[i] = max_each[max_idx];
            max_each[max_idx] = temp;

            top_5[i] = max_each[i];
        end
        $display("############### TOP 5 PEAK ###############\n");
        for(int i=0; i<5; i++) begin
            $display("[========== TOP %0d ==========]\n", i+1);
            `ifdef ADD
                tmp = (top_5[i].correlation_result)/(2.0**15);
                $display("PRN ID: %0d - Doppler Shift: %0d - Code Phase Delay: %0d - Correlation Result: %f\n", (top_5[i].prn_id + 1), top_5[i].doppler_shift, top_5[i].code_phase_delay, tmp);
            `else
                $display("PRN ID: %0d - Doppler Shift: %0d - Code Phase Delay: %0d - Correlation Result: %f\n", (top_5[i].prn_id + 1), top_5[i].doppler_shift, top_5[i].code_phase_delay, top_5[i].correlation_result);
            `endif
        end
        $display("Complete acquisition at %t\n", $time);

        $display("TOP 4 FROM PEAK_TOP_4");
        for(int i=0; i<4; i++) begin
            $display("PRN ID: %0d - Doppler Shift: %0d - Code Phase Delay: %0d", (top_4[i].prn_id + 1), top_4[i].doppler_shift, top_4[i].code_phase_delay);
        end
        // $display("PRN ID: %0d - Doppler Shift: %0d - Code Phase Delay: %0d", (o_prn_id_0 + 1), o_doppler_shift_0, o_code_phase_delay_0);
        // $display("PRN ID: %0d - Doppler Shift: %0d - Code Phase Delay: %0d", (o_prn_id_1 + 1), o_doppler_shift_1, o_code_phase_delay_1);
        // $display("PRN ID: %0d - Doppler Shift: %0d - Code Phase Delay: %0d", (o_prn_id_2 + 1), o_doppler_shift_2, o_code_phase_delay_2);
        // $display("PRN ID: %0d - Doppler Shift: %0d - Code Phase Delay: %0d", (o_prn_id_3 + 1), o_doppler_shift_3, o_code_phase_delay_3);
        $display("Cycles to complete GPS Acquisition Phase (since enough input data) is %d",timer);


        for (int sat=0; sat < 32; sat++) begin
            `ifdef NON_SCALE
                file_array[sat] = $fopen($sformatf("..mem/corr_result_%0d.txt",sat),"w");
            `else
                file_array[sat] = $fopen($sformatf("..mem/corr_result_scale_%0d.txt",sat),"w");
            `endif
        end

        for (int sat = 0; sat < 32; sat = sat + 1) begin
            if(sat!=0 && sat != 31 && sat != 16 && sat != 10 && sat != 19) begin
                continue;
            end
            for (int i = 0; i < 81; i = i + 1) begin
                for(int j=0; j < 4096; j = j + 1) begin
                    $fwrite(file_array[sat], "%d\n", corr_result[sat][i][j]);
                end
            end
        end

        for (int sat = 0; sat < 32; sat = sat + 1) begin
            $fclose(file_array[sat]);
        end

        $finish;
    end

endmodule
