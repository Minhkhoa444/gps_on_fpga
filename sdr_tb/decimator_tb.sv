`timescale 1ns/1ps

module decimator_tb;

    localparam data_width = 16;
    localparam decimation_rate = 2;
    localparam test_input_size = 100;

    bit aclk;
    bit rst_i;

    bit[data_width - 1 : 0] s_axis_tdata;
    bit s_axis_tvalid;
    bit s_axis_tready;

    bit[data_width - 1 : 0] m_axis_tdata;
    bit m_axis_tvalid;
    bit m_axis_tready;

    bit[data_width - 1 : 0] expected_output[$];
    bit[data_width - 1 : 0] real_output[$];

    initial begin
        aclk = 0;
        forever begin
            aclk = #10 !aclk;
        end
    end

    decimator #(
        .data_width(data_width),
        .decimation_rate(decimation_rate)
    ) dut(
        .aclk(aclk),
        .rst_i(rst_i),

        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),

        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready)
    );

    bit simulation_fail;
    event simulation_end;

    initial begin
        #0
        rst_i = 1;
        m_axis_tready = 0;
        repeat(2) begin
            @(negedge aclk);
        end
        rst_i = 0;
        m_axis_tready = 1;
        for(int i = 1; i <= test_input_size; i = i + 1) begin
            @(posedge aclk);
            wait(s_axis_tready);
            s_axis_tdata = i;
            s_axis_tvalid = 1;
            if ((i - 1) % decimation_rate == 0) begin
                expected_output.push_back(i);
            end
        end
        #100;
        -> simulation_end;
    end

    initial begin
        @(negedge rst_i);
        forever begin
            @(posedge aclk);
            if(m_axis_tvalid && m_axis_tready && s_axis_tvalid && s_axis_tready) begin
                real_output.push_back(m_axis_tdata);
            end
        end
    end

    initial @(simulation_end) begin
        simulation_fail = 0;
        for (int i = 0; i < test_input_size / decimation_rate; i++) begin
            if (real_output[i] == expected_output[i]) begin
                $display("\nreal_output[%0d] = %4h, expected_output[%0d] = %4h", i, real_output[i], i, expected_output[i]);
            end
            else begin
                $display("\nWrong result! real_output[%0d] = %4h, expected_output[%0d] = %4h", i, real_output[i], i, expected_output[i]);
                simulation_fail = 1;
                break;
            end
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