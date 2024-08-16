`timescale 1ns/1ps

module crc32_tb;
    bit clk;
    bit rst;
    
    bit[7 : 0] data_in;
    bit[31 : 0] crc_out;

    bit[7 : 0] test_frame[60];

    initial begin
        clk = 0;
        forever begin
            clk = #10 !clk;
        end
    end

    initial begin
        $readmemh("test_frame/frame_0.mem", test_frame);
    end
   
    crc32 dut(

    bit simulation_fail;
    event simulation_end;

    initial begin
        #0
        rst = 1;
        repeat(2) begin
            @(negedge clk);
        end
        rst = 0;
        for(int i = 0; i < 60; i = i + 1) begin
            for(int j = 7; j >= 0; j = j - 1) begin
                @(posedge clk);
                //data_in = test_frame[i][j];
            end
        end
        @(posedge clk);
        //data_in = 0;
        -> simulation_end;
    end

    initial begin
        @(negedge rst);
        forever begin
            @(posedge clk);
        end
    end

    
    initial @(simulation_end) begin
        repeat(4) begin
            @(negedge clk);
        end
        
        $display("\n##########################################################");
        if(simulation_fail) begin
            $display("\nSimulation failed!");
        end
        else begin
            $display("\nSimulation success!");
        end
        $display("\n##########################################################\n");
        $finish;
    end
endmodule
