`timescale 1ns/1ps

module eth_tx_tb;

    bit clk;
    bit rst;

    bit[7 : 0] data_in;
    bit tx_valid;
    bit data_last;

    bit tx_ready;

    bit[1 : 0] txd;
    bit txen;

    bit[7 : 0] debug_bytes;

    initial begin
        clk = 0;
        forever begin
            clk = #10 !clk;
        end
    end

    eth_tx #(
    ) dut (
        .clk50_i(clk),
        .rst_i(rst),

        .data_in_i(data_in),
        .tx_valid_i(tx_valid),
        .data_last_i(data_last),

        .tx_ready_o(tx_ready),

        .txd_o(txd),
        .txen_o(txen),

        .debug_bytes_o(debug_bytes)
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
        tx_valid = 1;
        repeat(1) begin
            @(posedge clk);
            wait(tx_ready);
            tx_valid = 1;
            data_in = 'h55;
            @(posedge tx_ready);
            @(posedge clk);
            data_in = 'hD5;
        end
        repeat(200) begin
            @(posedge clk);
        end
        -> simulation_end;
    end

    initial begin
        $monitor("\ncur_byte = %2h", debug_bytes);
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
