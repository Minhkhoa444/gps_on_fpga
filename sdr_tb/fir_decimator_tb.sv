`timescale 1ns/1ps

module fir_decimator_tb;

    localparam data_width = 16;
    localparam fraction_width = 15;
    localparam coeff_width = 16;
    localparam filter_N = 100;
    localparam coeff_file = "../mem/coeff.mem";
    localparam decimation_rate = 4;
    localparam test_input_size = 200;

    bit aclk;
    bit rst_i;

    bit[data_width - 1 : 0] filter_input[test_input_size];

    bit[data_width - 1 : 0] s_axis_tdata;
    bit s_axis_tvalid;
    bit s_axis_tready;

    bit[data_width - 1 : 0] m_axis_tdata;
    bit m_axis_tvalid;
    bit m_axis_tready;

    initial begin
        aclk = 0;
        forever begin
            aclk = #10 !aclk;
        end
    end

    initial begin
        $readmemb("./fir_mem/input.mem", filter_input);
    end

    fir_decimator #(
        .data_width(data_width),
        .fraction_width(fraction_width),
        .coeff_width(coeff_width),
        .filter_N(filter_N),
        .coeff_file(coeff_file),
        .decimation_rate(decimation_rate)
    ) dut (
        .aclk(aclk),
        .rst_i(rst_i),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tready(m_axis_tready),
        .m_axis_tvalid(m_axis_tvalid)
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
        for (int i = 0; i < test_input_size; i++) begin
            @(posedge aclk);
            wait(s_axis_tready);
            s_axis_tdata = filter_input[i];
            s_axis_tvalid = 1;
        end
        -> simulation_end;
    end 

    initial @(simulation_end) begin
        repeat(4) begin
            @(negedge aclk);
        end
        simulation_fail = 0;
       
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