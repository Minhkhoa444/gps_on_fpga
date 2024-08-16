`timescale 1ns/1ps

module cosine_generator_tb;

    localparam phase_width = 10;
    localparam data_width = 16;

    bit clk;
    bit rst;

    bit[phase_width - 1 : 0] phase;
    
    bit[data_width - 1 : 0] val;

    initial begin
        clk = 0;
        forever begin
            clk = #10 !clk;
        end
    end

    cosine_generator #(
        .phase_width(10),
        .data_width(16)
    ) dut (
        .clk_i(clk),
        .rst_i(rst),

        .phase_i(phase),

        .val_o(val)
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
        repeat(1) begin
            for(int i = 0; i < 2**phase_width - 1; i = i + 1) begin
               @(posedge clk);
               phase = i;
            end
        end
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
