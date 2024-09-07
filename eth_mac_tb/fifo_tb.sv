`timescale 1ns/1ps

module fifo_tb;

    localparam fifo_depth = 1024;
    localparam data_width = 8;

    bit clk;
    bit rst;

    bit wr_en;
    bit rd_en;

    bit[data_width - 1 : 0] wdata;
    bit[data_width - 1 : 0] rdata;
    bit[data_width - 1 : 0] temp_read;

    bit[$clog2(fifo_depth) : 0] fifo_count;
    bit fifo_empty;
    bit fifo_almost_empty;

    bit fifo_full;
    bit fifo_almost_full;

    bit[data_width - 1 : 0] fifo_model[$];

    initial begin
        clk = 0;
        forever begin
            clk = #10 !clk;
        end
    end
    
    fifo #(
        .fifo_depth(fifo_depth),
        .data_width(data_width)
    ) dut (
        .clk_i(clk),
        .rst_i(rst),

        .wr_en_i(wr_en),
        .rd_en_i(rd_en),

        .wdata_i(wdata),
        .rdata_o(rdata),

        .fifo_count_o(fifo_count),

        .fifo_empty_o(fifo_empty),
        .fifo_almost_empty_o(fifo_almost_empty),

        .fifo_full_o(fifo_full),
        .fifo_almost_full_o(fifo_almost_full)
    );

    bit simulation_fail;
    event simulation_end;

    property fifo_size;
        @(posedge clk) disable iff(rst)
            fifo_count == fifo_model.size();
    endproperty

    assert property(fifo_size)
    else begin
        $error("\nAssertion failed! Expected FIFO size: %0d, Got FIFO size: %0d", fifo_model.size(), fifo_count);
    end

    initial begin
        #0
        rst = 1;
        repeat(2) begin
            @(negedge clk);
        end
        rst = 0;
        for(int i = 0; i < 1024; i = i + 1) begin
            @(posedge clk);
            wdata = $urandom_range(2**data_width - 1, 0);
            wr_en = 1;
            fifo_model.push_back(wdata);
        end
        @(posedge clk);
        wr_en = 0;
        @(posedge clk);
        @(posedge clk);
        rd_en = 1;
        @(posedge clk);
        for(int i = 0; i < 10; i = i + 1) begin
            @(posedge clk);
            temp_read = fifo_model.pop_front();
            if(temp_read != rdata) begin
                $display("\nIn correct! Expected: %h, Got: %h", temp_read, rdata);
                simulation_fail = 1;
                -> simulation_end;
            end
        end
        @(posedge clk);
        rd_en = 0;
        @(posedge clk);
        @(posedge clk);
        for(int i = 0; i < 5; i = i + 1) begin
            @(posedge clk);
            wdata = $urandom_range(2**data_width - 1, 0);
            wr_en = 1;
            fifo_model.push_back(wdata);
        end
        @(posedge clk);
        wr_en = 0;
        simulation_fail = 0;
        -> simulation_end;
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
