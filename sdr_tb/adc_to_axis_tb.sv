`timescale 1ns/1ps

class packet #(parameter adc_resolution = 12);
    rand bit[adc_resolution - 1 : 0] adc_i;

    constraint valid_resolution {
        adc_i inside {[0 : (2 ** adc_resolution - 1)]};
    }

    function new();
    endfunction
endclass

module adc_to_axis_tb;

    localparam adc_resolution = 12;
    localparam data_width = 16;
    localparam decimal_width = 15;

    packet #(
        .adc_resolution(adc_resolution)
    ) pkt = new();

    bit aclk;
    bit[data_width - 1 : 0] m_axis_tdata;
    bit m_axis_tvalid;
    bit m_axis_tready;

    initial begin
        aclk = 0;
        forever begin
            aclk = #10 !aclk;
        end
    end
    
    bit[adc_resolution - 1 : 0] adc_i;
    bit[data_width - 1 : 0] expected_adc_val;
    bit rst_i;

    adc_to_axis #(
        .adc_resolution(adc_resolution),
        .data_width(data_width),
        .decimal_width(decimal_width)
    ) dut (
        .adc_i(adc_i),
        .rst_i(rst_i),

        .aclk(aclk),

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
        @(negedge aclk);
        repeat(100) begin
            @(posedge aclk);
            void'(pkt.randomize());
            adc_i = pkt.adc_i;
        end
        -> simulation_end;
    end

    always @(posedge aclk) begin
        if(rst_i == 0) begin
            expected_adc_val <= adc_i << (decimal_width - adc_resolution);
            $display("t :%t, adc_i: %h, expected: %h, got: %h", $time, adc_i, expected_adc_val, m_axis_tdata);
            if(expected_adc_val != m_axis_tdata) begin
                simulation_fail = 1;
            end
            else begin
                simulation_fail = 0;
            end
        end
    end

    initial @(simulation_end) begin
        repeat(2) begin
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
