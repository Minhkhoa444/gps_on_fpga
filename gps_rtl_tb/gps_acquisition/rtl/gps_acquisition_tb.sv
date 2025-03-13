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
module gps_acquisition_tb;
    logic                   clk;
    logic                   rst_n;

    // input data from sdr and output tready to sdr
    logic                   s_axis_tvalid;      // tvalid
    logic   signed  [15:0]  s_axis_tdata_i;     // gps_i
    logic   signed  [15:0]  s_axis_tdata_q;     // gps_q
    // logic                   m_axis_tready;      // tready from dispatcher
    
    // input tready, output data from/to gps_dispatcher
    logic                   s_axis_tready;      // tready
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

    gps_acquisition dut(.*);

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
        $readmemb("./../mem/gps_i_4096.mem",gps_i);
        $readmemb("./../mem/gps_q_4096.mem",gps_q);
        // Ha Noi gps
        // $readmemb("./../mem/hanoi/gps_q_4096.mem",gps_q);
        // $readmemb("./../mem/hanoi/gps_q_4096.mem",gps_q);
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

    initial begin
        forever begin
            @(posedge clk) begin
                if(m_axis_td_shift == -2000 && m_axis_tposition == 4095 && m_axis_tprn_id == 31) begin
                    -> simulation_end;
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

    initial begin
        forever begin
            @(posedge clk) begin
                if(m_axis_tvalid) begin
                    `ifdef ADD
                        if(m_axis_tdata > max_each[m_axis_tprn_id].correlation_result) begin
                            max_each[m_axis_tprn_id] = '{m_axis_tdata, m_axis_td_shift, m_axis_tposition, m_axis_tprn_id};
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
        $finish;
    end

endmodule
