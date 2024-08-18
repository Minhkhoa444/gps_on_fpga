`timescale 1ns/1ps

module nco_tb;

    localparam phase_width = 12;
    localparam data_width = 16;

    bit clk;
    bit rst;

    bit[phase_width + 1 : 0] dphase;
    
    bit[data_width - 1 : 0] sine;
    bit[data_width - 1 : 0] cosine;

    initial begin
        clk = 0;
        forever begin
            clk = #10 !clk;
        end
    end

    nco #(
        .phase_width(phase_width),
        .data_width(data_width)
    ) dut (
        .clk_i(clk),
        .rst_i(rst),

        .dphase_i(dphase),

        .sine_o(sine),
        .cosine_o(cosine)
    );

    bit simulation_fail;
    event simulation_end;
    int unsigned frequency;

    initial begin
        #0
        rst = 1;
        repeat(2) begin
            @(negedge clk);
        end
        rst = 0;
        frequency = 5000000;
        repeat(1) begin
            dphase = frequency / (50000000 / (2**phase_width * 4));
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
        repeat(200) begin
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
