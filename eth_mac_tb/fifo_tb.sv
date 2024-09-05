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

    initial begin
        #0
        rst = 1;
        repeat(2) begin
            @(negedge clk);
        end
        rst = 0;
        for(int i = 0; i < 1024; i = i + 1) begin
            @(posedge clk);
            wdata <= (i + 1) % (2**data_width);
            wr_en <= 1;
        end
        @(posedge clk);
        wr_en = 0;
        @(posedge clk);
        @(posedge clk);
        for(int i = 0; i < 10; i = i + 1) begin
            @(posedge clk);
            rd_en = 1;
        end
        @(posedge clk);
        rd_en = 0;
        @(posedge clk);
        @(posedge clk);
        //for(int i = 0; i < 5; i = i + 1) begin
        //    @(posedge clk);
        //    wdata = (5 - i);
        //    wr_en = 1;
        //end
        //@(posedge clk);
        //wr_en = 0;
        -> simulation_end;
    end

    bit[data_width - 1 : 0] temp_read;

    initial begin
        @(negedge rst);
        forever begin
            if(wr_en) begin
                fifo_model.push_back(wdata);
                @(posedge clk);
            end
            else if(rd_en) begin
                @(posedge clk);
                temp_read = fifo_model.pop_front();
                if(rdata != temp_read) begin
                    $display("\nt = %t ERROR! Expected: %h, Got: %h", $time, temp_read, rdata);
                    simulation_fail = 1;
                    //-> simulation_end;
                end
            end
            else begin
                @(posedge clk);
            end
        end
    end

    initial @(simulation_end) begin
        repeat(4) begin
            @(negedge clk);
        end
        
        for(int i = 0; i < fifo_model.size(); i = i + 1) begin
            $display("\nfifo_model[%0d] = %h", i, fifo_model[i]);
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
