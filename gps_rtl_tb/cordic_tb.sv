`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Ho Chi Minh City University of Technology
// Engineer: Vu Nam Binh
// 
// Create Date: 11/26/2024 01:37:11 PM
// Design Name: Testbench CORDIC Algorithm
// Module Name: cordic_tb
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

`define RANDOM
`define TEST_1K
module cordic_tb;
    parameter WII           =   3;  // # bits of integer part of input angle, an angle from 0 -> 2pi maximum 6.abc -> use 3 bits integer
    parameter WIF           =   31; // # bits of fraction part of input angle
    parameter DAT_WIDTH     =   32; // # bits output cosine and sine
    parameter NUM_STG       =   32; // # stages in pipeline
    
    `ifdef TEST_1K
    parameter NUM_OF_TEST   =   1000;
    `else
    parameter NUM_OF_TEST   =   1000;
    `endif
    
    parameter FRACTION_WIDTH=   31;
    logic                       clk;
    logic                       m_axis_tvalid_i;
    
    `ifdef RANDOM
    bit [WII+WIF:0]             angle_input     [NUM_OF_TEST];  // 35 bits: Q3.31 + signed bit
    bit [DAT_WIDTH-1:0]           expected_cosine [NUM_OF_TEST];
    bit [DAT_WIDTH-1:0]           expected_sine   [NUM_OF_TEST];
    bit [DAT_WIDTH-1:0]           real_cosine [$];
    bit [DAT_WIDTH-1:0]           real_sine   [$];
    `endif
    
    bit [WII+WIF:0]             angle_i;
    
    `ifdef RANDOM
    bit simulation_fail;
    event simulation_end;
    `endif
    
    // output cosine and sine resultss
    logic  [DAT_WIDTH-1:0]       cosine_o;
    logic  [DAT_WIDTH-1:0]       sine_o;
    logic                      s_axis_tvalid_o;

    cordic dut(.*);

    initial begin
        clk = 1'b1;
        forever #5 clk = ~clk;
    end

    `ifdef RANDOM
    initial begin
        `ifdef TEST_1K
            $readmemb("D:/Capstone Project/RTL Coding/data_cordic/angles_fixed_point_1K.mem", angle_input);
            $readmemb("D:/Capstone Project/RTL Coding/data_cordic/angles_cosine_1K.mem", expected_cosine);
            $readmemb("D:/Capstone Project/RTL Coding/data_cordic/angles_sine_1K.mem", expected_sine);
        `else
            $readmemb("D:/Capstone Project/RTL Coding/data_cordic/angles_fixed_point.mem", angle_input);
            $readmemb("D:/Capstone Project/RTL Coding/data_cordic/angles_cosine.mem", expected_cosine);
            $readmemb("D:/Capstone Project/RTL Coding/data_cordic/angles_sine.mem", expected_sine);
        `endif
    end
    
    task c1;
        @(posedge clk);
        #0.3;
    endtask

    task c2;
        for(int i=0; i<(32 + NUM_OF_TEST + 10); i++) begin
            @(posedge clk);
        end
    endtask

    initial begin
    $display("Test haha");
        for(int i=0; i < NUM_OF_TEST; i++) begin
            c1;
            m_axis_tvalid_i = 'b1;
            angle_i = angle_input[i];
        end
        c1;
        m_axis_tvalid_i = 'b0;
        c2;     //delay 32*NUM_OF_TEST cycles for output
        $display("Test haha");
        -> simulation_end;
    end

    initial begin
        forever begin
            @(posedge clk);
            if(s_axis_tvalid_o) begin
                real_cosine.push_back(cosine_o);
                real_sine.push_back(sine_o);
            end
        end
    end

    bit signed  [DAT_WIDTH:0]    difference_cosine;
    bit signed  [DAT_WIDTH:0]    difference_sine;
    bit         [FRACTION_WIDTH-1:0]    max_diff;
    
    initial @(simulation_end) begin
        max_diff = $ceil(0.001 * (2**FRACTION_WIDTH));

        $display("\nmax_diff used: %0d or %0f", max_diff, (real'($signed(max_diff))/real'(2**FRACTION_WIDTH)));
        for(int i=0; i<NUM_OF_TEST; i++) begin
            difference_cosine   = $signed(real_cosine[i] - expected_cosine[i]);
            difference_sine     = $signed(real_sine[i] - expected_sine[i]);
            
            if(difference_cosine < 0) begin
                difference_cosine = -difference_cosine;
            end

            if(difference_sine < 0) begin
                difference_sine = -difference_sine;
            end

            if(difference_cosine < max_diff || difference_sine < max_diff) begin
                simulation_fail = 0;
                $display("\nreal_cosine[%0d] = %b, expected_cosine[%0d] = %b, diff = %0d", i, real_cosine[i], i, expected_cosine[i], difference_cosine);
                $display("\nreal_sine[%0d] = %b, expected_sine[%0d] = %b, diff = %0d", i, real_sine[i], i, expected_sine[i], difference_sine);
            end
            else begin
                simulation_fail = 1;
                $display("\nWRONG OUTPUT: real_cosine[%0d] = %b, expected_cosine[%0d] = %b, diff = %0d", i, real_cosine[i], i, expected_cosine[i], difference_cosine);
                $display("\nWRONG OUTPUT: real_sine[%0d] = %b, expected_sine[%0d] = %b, diff = %0d", i, real_sine[i], i, expected_sine[i], difference_sine);
                break;
            end
        end

        $display("\n######################################################");
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
    

    `ifndef RANDOM
     initial begin;
         #90.3 angle_i = 'b00011000100111101011011000101011101;    // pi/6
         m_axis_tvalid_i = 'b1;
         #10 m_axis_tvalid_i = 'b0;
         #1000 $finish;
     end
     `endif

endmodule
