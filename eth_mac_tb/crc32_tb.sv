`timescale 1ns/1ps

module crc32_tb;
    bit clk;
    bit rst;
    
    bit[7 : 0] data_in;
    bit crc_en;
    bit[31 : 0] crc;

    bit[7 : 0] test_frame[60];

    initial begin
        clk = 0;
        forever begin
            clk = #10 !clk;
        end
    end

    initial begin
        $readmemh("sample_frame/frame_0.mem", test_frame);
    end

    crc32 dut(
        .clk_i(clk),
        .rst_i(rst),
        .data_in_i(data_in),
        .crc_en_i(crc_en),

        .crc_o(crc)
    );

    bit simulation_fail;
    event simulation_end;

    initial begin
        #0
        rst = 1;
        crc_en = 0;
        repeat(2) begin
            @(negedge clk);
        end
        rst = 0;
        for(int i = 0; i < 60; i = i + 1) begin
            @(posedge clk);
            crc_en = 1;
            data_in = test_frame[i];
        end
        @(posedge clk);
        crc_en = 0;
        data_in = 0;
        -> simulation_end;
    end

    initial begin
        @(negedge rst);
        forever begin
            @(posedge clk);
            $display("t = %t, data_in = %2h, crc = %8h", $time, data_in, crc);
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
