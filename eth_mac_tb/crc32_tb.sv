`timescale 1ns/1ps

module crc32_tb;
    bit clk;
    bit rst;
    
    bit[7 : 0] data_in;
    bit[31 : 0] crc_in;
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
        .crc_in(crc_in),
        .data_in_i(data_in),
        .crc_out(crc_out)
    );

    bit simulation_fail;
    event simulation_end;

    initial begin
        #0
        rst = 1;
        repeat(2) begin
            @(negedge clk);
        end
        rst = 0;
        crc_in = 'hFFFF_FFFF;
        for(int i = 0; i < 60; i = i + 1) begin
            @(posedge clk);
            data_in = test_frame[i];
        end
        @(posedge clk);
        //data_in = 0;
        -> simulation_end;
    end

    initial begin
        @(negedge rst);
        forever begin
            @(posedge clk);
            $display("t = %t, crc_in = %8h, data_in = %2h, crc_out = %8h", $time, crc_in, data_in, crc_out);
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
