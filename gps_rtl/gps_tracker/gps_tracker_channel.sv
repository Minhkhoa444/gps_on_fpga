module gps_tracker_channel #(
    parameter DAT_WIDTH = 16,
    parameter SAMPLING_RATE = 4096000,
    parameter CA_CODE_LENGTH = 4096,
    parameter ACC_WIDTH = 32,
    parameter PHASE_WIDTH = 32,
    parameter CODE_NCO_WIDTH = 32,
    parameter CARR_NCO_WIDTH = 32
) (
    input logic                             clk_i,
    input logic                             rst_i,
    input logic                             i_valid,
    input logic signed[DAT_WIDTH - 1 : 0]   i_data_i,
    input logic signed[DAT_WIDTH - 1 : 0]   i_data_q,
    input logic[4 : 0]                      i_prn_id,
    input logic[11 : 0]                     i_init_code_phase,
    input logic signed[DAT_WIDTH - 1 : 0]   i_init_doppler,

    output logic                            o_valid,
    output logic signed[DAT_WIDTH - 1 : 0]  o_prompt_i,
    output logic signed[DAT_WIDTH - 1 : 0]  o_prompt_q,
    output logic                            o_nav_bit,
    output logic                            o_nav_bit_valid
);
    //  PLL BW 15 Hz
    //  DLL BW 2 Hz
    //  Q16.16 format
    //localparam signed[31 : 0] PLL_K1 = 32'h0027_bace;  // Proportional
    //localparam signed[31 : 0] PLL_K2 = 32'h0325_5518;  // Integral
    //localparam signed[31 : 0] DLL_K1 = 32'h0005_4c1c;  // Proportional
    //localparam signed[31 : 0] DLL_K2 = 32'h000e_5127;  // Integral

    localparam signed[31 : 0] PLL_K1 = 32'd32768;  // Proportional
    localparam signed[31 : 0] PLL_K2 = 32'd1966;  // Integral
    localparam signed[31 : 0] DLL_K1 = 32'd0;  // Proportional
    localparam signed[31 : 0] DLL_K2 = 32'd66;  // Integral

    localparam EARLY_LATE_SAMPLES = 2;

    logic[11 : 0] early_code_addr;
    logic[11 : 0] early_code_addr_reg;
    logic[11 : 0] late_code_addr;
    logic[11 : 0] late_code_addr_reg;
    logic[11 : 0] prompt_code_addr;
    logic[11 : 0] prompt_code_addr_reg;
    logic signed[CODE_NCO_WIDTH - 1 : 0] code_nco_phase_inc;   // Phase increment for code NCO
    logic[CODE_NCO_WIDTH - 1 : 0] code_nco_phase;       // Code NCO phase accumulator
    logic[11 : 0] code_phase_int;       // Integer part of code phase
    logic[DAT_WIDTH - 1 : 0] code_phase_frac;      // Fractional part for interpolation
    // Carrier NCO signals
    logic signed[CARR_NCO_WIDTH - 1 : 0] carr_nco_phase_inc;   // Phase increment for carrier NCO
    logic[CARR_NCO_WIDTH - 1 : 0] carr_nco_phase;       // Carrier NCO phase accumulator
    logic signed[DAT_WIDTH - 1 : 0] carr_sin;
    logic signed[DAT_WIDTH - 1 : 0] carr_cos;
    // Mixer outputs
    logic signed[DAT_WIDTH - 1 : 0] mixed_i, mixed_q;
    logic signed[DAT_WIDTH - 1 : 0] early_corr_i, early_corr_q;
    logic signed[DAT_WIDTH - 1 : 0] prompt_corr_i, prompt_corr_q;
    logic signed[DAT_WIDTH - 1 : 0] late_corr_i, late_corr_q;
    logic signed[ACC_WIDTH - 1 : 0] early_acc_i, early_acc_q;
    logic signed[ACC_WIDTH - 1 : 0] late_acc_i, late_acc_q;
    logic signed[ACC_WIDTH - 1 : 0] prompt_acc_i, prompt_acc_q;
    logic signed[ACC_WIDTH - 1 : 0] early_acc_i_reg, early_acc_q_reg;
    logic signed[ACC_WIDTH - 1 : 0] late_acc_i_reg, late_acc_q_reg;
    logic signed[ACC_WIDTH - 1 : 0] prompt_acc_i_reg, prompt_acc_q_reg;
    // PLL filter states
    logic signed[2 * ACC_WIDTH : 0] pll_error;
    logic signed[2 * CARR_NCO_WIDTH : 0] pll_integrator;
    logic signed[2 * CARR_NCO_WIDTH : 0] pll_filter_out;
    // DLL filter states
    logic signed[2 * ACC_WIDTH : 0] dll_error;
    logic signed[2 * CODE_NCO_WIDTH : 0] dll_integrator;
    logic signed[2 * CODE_NCO_WIDTH : 0] dll_filter_out;
    // Timing signals
    logic[31 : 0] sample_counter;
    logic[31 : 0] sample_counter_next;
    logic dump_correlators;
    logic dump_correlators_d1;
    logic dump_correlators_d2;
    logic dump_correlators_d3;
    logic dump_correlators_d4;
    // Navigation bit extraction
    logic[4 : 0] bit_counter;
    logic[4 : 0] bit_counter_next;

    always_comb begin
        prompt_code_addr = code_phase_int;
        early_code_addr = (prompt_code_addr + CA_CODE_LENGTH - EARLY_LATE_SAMPLES) % CA_CODE_LENGTH;
        late_code_addr = (prompt_code_addr + EARLY_LATE_SAMPLES) % CA_CODE_LENGTH;
    end

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            early_code_addr_reg <= '0;
            late_code_addr_reg <= '0;
            prompt_code_addr_reg <= '0;
        end
        else if(i_valid) begin
            early_code_addr_reg <= early_code_addr;
            late_code_addr_reg <= late_code_addr;
            prompt_code_addr_reg <= prompt_code_addr;
        end
    end

    logic[0 : 31] prompt_code;
    logic[0 : 31] early_code;
    logic[0 : 31] late_code;

    ca_generator early_gen(
        .clk_i(clk_i),
        .addr_i(early_code_addr_reg),
        .code_o(early_code)
    );

    ca_generator late_gen(
        .clk_i(clk_i),
        .addr_i(late_code_addr_reg),
        .code_o(late_code)
    );

    ca_generator prompt_gen(
        .clk_i(clk_i),
        .addr_i(prompt_code_addr_reg),
        .code_o(prompt_code)
    );

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            code_nco_phase <= '0;
            code_phase_int <= i_init_code_phase;
        end 
        else if(i_valid) begin
            code_nco_phase <= code_nco_phase + code_nco_phase_inc;
            code_phase_int <= (code_phase_int + (code_nco_phase[CODE_NCO_WIDTH - 1 : CODE_NCO_WIDTH - 4])) % CA_CODE_LENGTH;
        end
    end

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            carr_nco_phase <= '0;
        end
        else if(i_valid) begin
            carr_nco_phase <= carr_nco_phase + carr_nco_phase_inc;
        end
    end

    sin_cos_lut #(
        .PHASE_WIDTH(CARR_NCO_WIDTH),
        .DAT_WIDTH(DAT_WIDTH),
        .LUT_SIZE(256)
    ) u_carrier_wipeoff_nco(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .i_phase(carr_nco_phase),
        .o_sin(carr_sin),
        .o_cos(carr_cos)
    );

    logic signed[DAT_WIDTH - 1 : 0] i_data_i_reg;
    logic signed[DAT_WIDTH - 1 : 0] i_data_q_reg;
    logic signed[DAT_WIDTH - 1 : 0] carr_sin_reg;
    logic signed[DAT_WIDTH - 1 : 0] carr_cos_reg;
    logic signed[2 * DAT_WIDTH - 1 : 0] mix_prod_ii;
    logic signed[2 * DAT_WIDTH - 1 : 0] mix_prod_iq;
    logic signed[2 * DAT_WIDTH - 1 : 0] mix_prod_qi;
    logic signed[2 * DAT_WIDTH - 1 : 0] mix_prod_qq;

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            i_data_i_reg <= '0;
            i_data_q_reg <= '0;
            carr_sin_reg <= '0;
            carr_cos_reg <= '0;
        end
        else if(i_valid) begin
            i_data_i_reg <= i_data_i;
            i_data_q_reg <= i_data_q;
            carr_sin_reg <= carr_sin;
            carr_cos_reg <= carr_cos;
        end
    end

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            mix_prod_ii <= '0;
            mix_prod_iq <= '0;
            mix_prod_qi <= '0;
            mix_prod_qq <= '0;
        end
        else if(i_valid) begin
            mix_prod_ii <= i_data_i_reg * carr_cos_reg;
            mix_prod_iq <= i_data_i_reg * carr_sin_reg;
            mix_prod_qi <= i_data_q_reg * carr_sin_reg;
            mix_prod_qq <= i_data_q_reg * carr_cos_reg;
        end
    end

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            mixed_i <= '0;
            mixed_q <= '0;
        end 
        else if(i_valid) begin
            mixed_i <= (mix_prod_ii - mix_prod_qi) >>> (DAT_WIDTH - 1);
            mixed_q <= (mix_prod_qq + mix_prod_iq) >>> (DAT_WIDTH - 1);
        end
    end

    logic[0 : 31] early_code_reg;
    logic[0 : 31] late_code_reg;
    logic[0 : 31] prompt_code_reg;

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            early_code_reg <= '0;
            late_code_reg <= '0;
            prompt_code_reg <= '0;
        end
        else if(i_valid) begin
            early_code_reg <= early_code;
            late_code_reg <= late_code;
            prompt_code_reg <= prompt_code;
        end
    end

    // Early, prompt, and late correlation
    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            early_corr_i <= '0;
            early_corr_q <= '0;
            late_corr_i <= '0;
            late_corr_q <= '0;
            prompt_corr_i <= '0;
            prompt_corr_q <= '0;
        end
        else if(i_valid) begin
            //  EARLY CORRLEATION
            if(!early_code_reg[i_prn_id] && mixed_i == 16'h8000) begin
                early_corr_i <= 16'h7FFF;
            end
            else if(!early_code_reg[i_prn_id]) begin
                early_corr_i <= -mixed_i;
            end
            else begin
                early_corr_i <= mixed_i;
            end
            if(!early_code_reg[i_prn_id] && mixed_q == 16'h8000) begin
                early_corr_q <= 16'h7FFF;
            end
            else if(!early_code_reg[i_prn_id]) begin
                early_corr_q <= -mixed_q;
            end
            else begin
                early_corr_q <= mixed_q;
            end
            //  LATE CORRELATION
            if(!late_code_reg[i_prn_id] && mixed_i == 16'h8000) begin
                late_corr_i <= 16'h7FFF;
            end
            else if(!late_code_reg[i_prn_id]) begin
                late_corr_i <= -mixed_i;
            end
            else begin
                late_corr_i <= mixed_i;
            end
            if(!late_code_reg[i_prn_id] && mixed_q == 16'h8000) begin
                late_corr_q <= 16'h7FFF;
            end
            else if(!late_code_reg[i_prn_id]) begin
                late_corr_q <= -mixed_q;
            end
            else begin
                late_corr_q <= mixed_q;
            end
            //  PROMPT CORRELATION
            if(!prompt_code_reg[i_prn_id] && mixed_i == 16'h8000) begin
                prompt_corr_i <= 16'h7FFF;
            end
            else if(!prompt_code_reg[i_prn_id]) begin
                prompt_corr_i <= -mixed_i;
            end
            else begin
                prompt_corr_i <= mixed_i;
            end
            if(!prompt_code_reg[i_prn_id] && mixed_q == 16'h8000) begin
                prompt_corr_q <= 16'h7FFF;
            end
            else if(!prompt_code_reg[i_prn_id]) begin
                prompt_corr_q <= -mixed_q;
            end
            else begin
                prompt_corr_q <= mixed_q;
            end
        end
    end

    // Integrate and dump control
    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            sample_counter <= '0;
            sample_counter_next <= '0;
            dump_correlators <= 1'b0;
            dump_correlators_d1 <= 1'b0;
            dump_correlators_d2 <= 1'b0;
            dump_correlators_d3 <= 1'b0;
            dump_correlators_d4 <= 1'b0;
        end
        else if(i_valid) begin
            // One millisecond is 4096 samples at 4.096 MSPS
            if(sample_counter == CA_CODE_LENGTH - 1) begin
                sample_counter_next <= '0;
                dump_correlators <= 1'b1;
            end
            else begin
                sample_counter_next <= sample_counter + 1;
                dump_correlators <= 1'b0;
            end
            sample_counter <= sample_counter_next;
            dump_correlators_d1 <= dump_correlators;
            dump_correlators_d2 <= dump_correlators_d1;
            dump_correlators_d3 <= dump_correlators_d2;
            dump_correlators_d4 <= dump_correlators_d3;
        end
        else begin
            dump_correlators <= 1'b0;
            dump_correlators_d1 <= dump_correlators;
            dump_correlators_d2 <= dump_correlators_d1;
            dump_correlators_d3 <= dump_correlators_d2;
            dump_correlators_d4 <= dump_correlators_d3;
        end
    end

    // Integrate and dump accumulators
    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            early_acc_i <= '0;
            early_acc_q <= '0;
            late_acc_i <= '0;
            late_acc_q <= '0;
            prompt_acc_i <= '0;
            prompt_acc_q <= '0;
            early_acc_i_reg <= '0;
            early_acc_q_reg <= '0;
            late_acc_i_reg <= '0;
            late_acc_q_reg <= '0;
            prompt_acc_i_reg <= '0;
            prompt_acc_q_reg <= '0;
            o_valid <= 1'b0;
        end
        else if(dump_correlators) begin
            early_acc_i <= '0;
            early_acc_q <= '0;
            late_acc_i <= '0;
            late_acc_q <= '0;
            prompt_acc_i <= '0;
            prompt_acc_q <= '0;
            early_acc_i_reg <= early_acc_i;
            early_acc_q_reg <= early_acc_q;
            late_acc_i_reg <= late_acc_i;
            late_acc_q_reg <= late_acc_q;
            prompt_acc_i_reg <= prompt_acc_i;
            prompt_acc_q_reg <= prompt_acc_q;
            o_valid <= 1'b1;
            o_prompt_i <= prompt_acc_i[15 : 0];
            o_prompt_q <= prompt_acc_q[15 : 0];
        end
        else if(i_valid) begin
            early_acc_i <= early_acc_i + early_corr_i;
            early_acc_q <= early_acc_q + early_corr_q;
            late_acc_i <= late_acc_i + late_corr_i;
            late_acc_q <= late_acc_q + late_corr_q;
            prompt_acc_i <= prompt_acc_i + prompt_corr_i;
            prompt_acc_q <= prompt_acc_q + prompt_corr_q;
            o_valid <= 1'b0;
        end else begin
            o_valid <= 1'b0;
        end
    end

    // PLL discriminator and loop filter
    //localparam signed[63 :0] PLL_TEMP = 2**CARR_NCO_WIDTH / SAMPLING_RATE;
    localparam signed[31 : 0] PLL_TEMP = 1049;

    logic signed[2 * ACC_WIDTH - 1 : 0] pll_error_next;

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            pll_error_next <= '0;
        end
        else if(dump_correlators_d1) begin
            //pll_error_next <= prompt_acc_i_reg * prompt_acc_q_reg;
            pll_error_next <= (prompt_acc_i_reg * prompt_acc_q_reg) >>> 1;
        end
    end

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            pll_error <= '0;
            pll_integrator <= '0;
            pll_filter_out <= i_init_doppler * PLL_TEMP;
            carr_nco_phase_inc <= i_init_doppler * PLL_TEMP;
        end
        else if(dump_correlators_d2) begin
            // PLL discriminator (arctangent discriminator approximation)
            pll_error <= pll_error_next >>> (DAT_WIDTH - 1);
            pll_integrator <= pll_integrator + ((pll_error * PLL_K2) >>> 16);
            pll_filter_out <= ((pll_error * PLL_K1) >>> 16) + pll_integrator;
            //  Base rate + adjustment from PLL
            carr_nco_phase_inc <= i_init_doppler * PLL_TEMP + pll_filter_out;
        end
    end

    // DLL discriminator and loop filter
    logic signed[2 * DAT_WIDTH - 1 : 0] early_i_sq;
    logic signed[2 * DAT_WIDTH - 1 : 0] early_q_sq;
    logic signed[2 * DAT_WIDTH - 1 : 0] late_i_sq;
    logic signed[2 * DAT_WIDTH - 1 : 0] late_q_sq;
    logic signed[2 * DAT_WIDTH - 1 : 0] dll_error_next;
    logic signed[2 * DAT_WIDTH - 1 : 0] early_i_shift;
    logic signed[2 * DAT_WIDTH - 1 : 0] early_q_shift;
    logic signed[2 * DAT_WIDTH - 1 : 0] late_i_shift;
    logic signed[2 * DAT_WIDTH - 1 : 0] late_q_shift;


    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            early_i_sq <= '0;
            early_q_sq <= '0;
            late_i_sq <= '0;
            late_q_sq <= '0;
        end
        else if(dump_correlators_d1) begin
            early_i_sq <= early_acc_i_reg * early_acc_i_reg;
            early_q_sq <= early_acc_q_reg * early_acc_q_reg;
            late_i_sq <= late_acc_i_reg * late_acc_i_reg;
            late_q_sq <= late_acc_q_reg * late_acc_q_reg;
        end
    end

    logic signed[31 : 0] dll_term_k1;
    logic signed[31 : 0] dll_term_k2;

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            early_i_shift <= '0;
            early_q_shift <= '0;
            late_i_shift <= '0;
            late_q_shift <= '0;
            dll_term_k1 <= '0;
            dll_term_k2 <= '0;
        end
        else if(dump_correlators_d2) begin
            early_i_shift <= early_i_sq >>> (DAT_WIDTH);
            early_q_shift <= early_q_sq >>> (DAT_WIDTH);
            late_i_shift <= late_i_sq >>> (DAT_WIDTH);
            late_q_shift <= late_q_sq >>> (DAT_WIDTH);
        end
    end

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            dll_error_next <= '0;
        end
        else if(dump_correlators_d3) begin
            dll_error_next <= early_i_shift + early_q_shift - late_i_shift - late_q_shift;
        end
    end

    //localparam signed[63 : 0] DLL_TEMP = 1023000 * 2**CODE_NCO_WIDTH / SAMPLING_RATE;
    localparam signed[31 : 0] DLL_TEMP = 1072693248;

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            dll_error <= '0;
            dll_integrator <= '0;
            dll_filter_out <= '0;
            // Base code rate (1.023 MHz / 4.096 MHz * 2^CODE_NCO_WIDTH)
            code_nco_phase_inc <= DLL_TEMP;
        end
        else if(dump_correlators_d4) begin
            // DLL discriminator (early-late envelope)
            //dll_term_k1 <= (dll_error_next * DLL_K1) >>> 16;
            //dll_term_k2 <= (dll_error_next * DLL_K2) >>> 16;
            dll_error <= dll_error_next;
            //dll_integrator <= dll_integrator + dll_term_k2;
            dll_integrator <= dll_integrator + (dll_error_next * DLL_K2) >>> 16;
            //dll_filter_out <= dll_term_k1 + dll_integrator;
            dll_filter_out <= ((dll_error_next * DLL_K1) >>> 16) + dll_integrator;
            // Base rate + adjustment from loop filter
            code_nco_phase_inc <= DLL_TEMP + dll_filter_out;
        end
    end

    // Navigation bit extraction
    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            o_nav_bit <= 1'b0;
            o_nav_bit_valid <= 1'b0;
            bit_counter <= '0;
            bit_counter_next <= '0;
        end
        else if(dump_correlators_d1) begin
            if(bit_counter == 19) begin
                // Output bit (inverted since 1 is positive correlation, 0 is negative)
                o_nav_bit <= ~prompt_acc_i_reg[ACC_WIDTH - 1];
                o_nav_bit_valid <= 1'b1;
                bit_counter_next <= '0;
            end
            else begin
                o_nav_bit_valid <= 1'b0;
                bit_counter_next <= bit_counter + 1;
            end
        end
        else begin
            o_nav_bit_valid <= 1'b0;
            bit_counter <= bit_counter_next;
        end
    end
endmodule
