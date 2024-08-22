`timescale 1ns/1ps

module eth_tx_tb;

    bit clk;
    bit rst;

    bit[7 : 0] data_in;
    bit tx_valid;
    bit tx_last;

    bit[1 : 0] txd;
    bit txen;

    initial begin
        clk = 0;
        forever begin
            clk = #10 !clk;     //  must be 50MHz clock for RMII
        end
    end

    eth_tx dut (
        .clk50_i(clk),
        .rst_i(rst),

        .data_in_i(data_in),
        .tx_valid_i(tx_valid),
        .tx_last_i(tx_last),

        .txd_o(txd),
        .txen_o(txen)
    );

    bit simulation_fail;
    event simulation_end;

    initial begin
        #0
        rst = 1;
        tx_valid = 0;
        repeat(2) begin
            @(negedge clk);
        end
        rst = 0;
        repeat(1) begin
            repeat(7) begin
                @(posedge clk);
                data_in = 'h55;
                tx_valid = 1;
                @(posedge clk);
                tx_valid = 0;
                repeat(2) begin
                    @(posedge clk);
                end
            end
            @(posedge clk);
            data_in = 'hD5;
            tx_valid = 1;
            tx_last = 1;
            @(posedge clk);
            tx_valid = 0;
            tx_last = 0;
        end
        repeat(200) begin
            @(posedge clk);
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
