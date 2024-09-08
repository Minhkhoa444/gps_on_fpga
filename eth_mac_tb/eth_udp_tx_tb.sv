`timescale 1ns/1ps

module eth_udp_tx_tb;

    localparam fifo_depth = 1024;
    localparam src_mac = 48'h01_23_45_67_89_0A;
    localparam src_ip = 32'hC0_A8_00_2C;
    localparam src_port = 16'd1024;
    localparam dest_mac = 48'h00_D8_61_05_97_0F;
    localparam dest_ip = 32'hC0_A8_00_04;
    localparam dest_port = 16'd1024;

    bit aclk;
    bit rst;
    
    /*
    bit[data_width - 1 : 0] filter_input[test_input_size];
    bit[data_width - 1 : 0] expected_output[test_input_size];
    bit[data_width - 1: 0] real_output[$];
    */

    bit[7 : 0] s_axis_tdata;
    bit s_axis_tvalid;
    bit s_axis_tready;

    bit[7 : 0] udp_data;
    bit udp_valid;
    bit udp_tx_last;

    initial begin
        aclk = 0;
        forever begin
            aclk = #10 !aclk;
        end
    end

    initial begin
        //$readmemb("./fir_mem/input.mem", filter_input);
        //$readmemb("./fir_mem/expected.mem", expected_output);
    end
    
    eth_udp_tx #(
        .fifo_depth(fifo_depth),
        .src_mac(src_mac),
        .src_ip(src_ip),
        .src_port(src_port),
        .dest_mac(dest_mac),
        .dest_ip(dest_ip),
        .dest_port(dest_port)
    ) dut (
        .aclk(aclk),
        .rst_i(rst),

        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),

        .udp_data_o(udp_data),
        .udp_valid_o(udp_valid),
        .udp_tx_last_o(udp_tx_last)
    );

    bit simulation_fail;
    event simulation_end;

    initial begin
        #0
        rst = 1;
        repeat(2) begin
            @(negedge aclk);
        end
        rst = 0;
        for(int i = 0; i < fifo_depth * 0.75; i = i + 1) begin
            @(posedge aclk);
            wait(s_axis_tready);
            s_axis_tdata = i + 1;
            s_axis_tvalid = 1;
        end
        repeat(2000) begin
            @(posedge aclk);
        end
        -> simulation_end;
    end

    initial @(simulation_end) begin
        repeat(4) begin
            @(negedge aclk);
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
