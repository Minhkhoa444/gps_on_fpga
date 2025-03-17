`timescale 1ns/1ps

module sdr_top_tb;

    localparam data_width = 16;
    localparam fraction_width = 15;
    localparam coeff_width = 16;
    localparam filter_N = 10;
    localparam coeff_file = "../sdr_tb/fir_decimator_mem/coeff.mem";
    localparam decimation_rate = 12;

    bit[data_width - 1 : 0] raw[4096];
    bit[data_width - 1 : 0] real_output_i[$];
    bit[data_width - 1 : 0] real_output_q[$];

    bit aclk;
    bit rst_i;

    bit[data_width - 1 : 0] s_axis_tdata;
    bit s_axis_tvalid;
    bit s_axis_tready;

    bit[data_width - 1 : 0] i_o;
    bit                     i_valid;
    bit[data_width - 1 : 0] q_o;
    bit                     q_valid;
    bit iq_ready;

    int fd;
    reg [15:0] data;
    int i, r;

    initial begin
        fd = $fopen("gps_upconverted_10MHz.bin", "rb"); // Mở tệp ở chế độ nhị phân
        if (fd == 0) begin
            $display("Error: Cannot open file.");
            $finish;
        end

        for (i = 0; i < 4096; i = i + 1) begin
            if ($feof(fd)) break; // Dừng khi hết tệp
            r = $fread(raw[i], fd);
            if (r == 0) break;
            $display("Byte %0d: %b", i, raw[i]);
        end

        $fclose(fd);
    end

    event simulation_end;

    initial begin
        aclk = 0;
        forever begin
            aclk = #10 !aclk;
        end
    end

    sdr_top #(
        .data_width(data_width),
        .adc_resolution(12),
        .coeff_file(coeff_file)
    ) dut (
        .clk50_i(aclk),
        .rst_i(rst_i),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .i_o(i_o),
        .i_valid(i_valid),
        .q_o(q_o),
        .q_valid(q_valid),
        .iq_ready(iq_ready)
    );

    bit simulation_fail = 0;

    initial begin
        #0
        rst_i = 1;
        iq_ready = 0;
        repeat(2) begin
            @(negedge aclk);
        end
        rst_i = 0;
        iq_ready = 1;
        for (int i = 0; i < 4096; i++) begin
            @(posedge aclk);
            wait(s_axis_tready);
            s_axis_tdata = raw[i];
            s_axis_tvalid = 1;
        end
        -> simulation_end;
    end 

    initial begin
        @(negedge rst_i);
        forever begin
            @(posedge aclk);
            if (i_valid && q_valid && iq_ready && s_axis_tvalid && s_axis_tready) begin
                real_output_i.push_back(i_o);
                real_output_q.push_back(q_o);
            end
        end
    end 

    bit signed[data_width - 1 : 0] difference;
    bit signed[data_width - 1 : 0] max_diff;

    initial @(simulation_end) begin
        repeat(5) begin
            @(negedge aclk);
        end

        max_diff = $ceil(0.001 * (2**fraction_width));
        $display("\nmax_diff used: %0d or %0f", max_diff, real'(max_diff)/ real'(2**fraction_width));

       
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