`timescale 1ns/1ps

module gps_tracker_channel_tb;

    localparam data_width = 16;
    localparam chunk_size = 2000000;

    bit aclk;
    bit rst;

    int file;
    shortint iq_data[2 * chunk_size];
    shortint i_samples[chunk_size];
    shortint q_samples[chunk_size];
    bit signed[15 : 0] i_samples_input;
    bit signed[15 : 0] q_samples_input;
    bit iq_valid;
    logic signed[15 : 0] ca_code_rom[0 : 4096 * 8 - 1];
    logic[4 : 0] selected_id[7];
    logic[11 : 0] early_code_addr[7];
    logic[11 : 0] late_code_addr[7];
    logic[11 : 0] prompt_code_addr[7];
    logic signed[15 : 0] early_code[7];
    logic signed[15 : 0] late_code[7];
    logic signed[15 : 0] prompt_code[7];

    logic nav_message;
    logic nav_valid;

    initial begin
        aclk = 0;
        forever begin
            aclk = #10 !aclk;
        end
    end

    initial begin
        //file = $fopen("../matlab_analysis/2013_04_04_GNSS_SIGNAL_at_CTTC_SPAIN.dat", "rb");
        file = $fopen("gps_10s.bin", "rb");
        $fread(iq_data, file, 0, chunk_size * 2);
        $fclose(file);
        for(int i = 0; i < chunk_size; i = i + 1) begin
            i_samples[i] = iq_data[2 * i];
            q_samples[i] = iq_data[2 * i + 1];
        end
    end

    tracker_precomputed_ca tracker_ca(
        .clk(aclk),
        .prn_id(selected_id),
        .ca_code_early_addr(early_code_addr),
        .ca_code_late_addr(late_code_addr),
        .ca_code_prompt_addr(prompt_code_addr),
        .ca_code_early(early_code),
        .ca_code_late(late_code),
        .ca_code_prompt(prompt_code)
    );

    gps_tracker_channel #(
        .DAT_WIDTH(16),
        .SAMPLING_RATE(4096000),
        .CA_CODE_LENGTH(4096),
        .ACC_WIDTH(32),
        .PHASE_WIDTH(32),
        .CODE_NCO_WIDTH(32),
        .CARR_NCO_WIDTH(32)
    ) dut(
        .clk_i(aclk),
        .rst_i(rst),
        .i_valid(iq_valid),
        .i_data_i(i_samples_input),
        .i_data_q(q_samples_input),
        .i_init_code_phase(16'd63781),
        .i_init_doppler(16'd7250),

        .o_valid(),
        .o_prompt_i(),
        .o_prompt_q(),
        .o_nav_bit(nav_message),
        .o_nav_bit_valid(nav_valid),


        .early_code_addr(early_code_addr[0]),
        .late_code_addr(late_code_addr[0]),
        .prompt_code_addr(prompt_code_addr[0]),
        .early_code(early_code[0]),
        .late_code(late_code[0]),
        .prompt_code(prompt_code[0])
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
        selected_id[0] = 8'd0;
        for(int i = 0; i < chunk_size; i = i + 1) begin
            @(posedge aclk);
            i_samples_input = i_samples[i];
            q_samples_input = q_samples[i];
            iq_valid = 1;
        end
        @(posedge aclk);
        iq_valid = 0;
        -> simulation_end;
    end

    always @(nav_valid) begin
        $display("nav_message = %b\n", nav_message);
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
