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
    input logic[DAT_WIDTH - 1 : 0]          i_init_code_phase,
    input logic signed[DAT_WIDTH - 1 : 0]   i_init_doppler,

    output logic                            o_valid,
    output logic signed[DAT_WIDTH - 1 : 0]  o_prompt_i,
    output logic signed[DAT_WIDTH - 1 : 0]  o_prompt_q,
    output logic                            o_pll_lock,
    output logic                            o_dll_lock,
    output logic                            o_nav_bit,
    output logic                            o_nav_bit_valid,

    input logic signed[DAT_WIDTH - 1 : 0]   i_prn_rom[0 : 4095]
);
    //  PLL BW 15 Hz
    //  DLL BW 2 Hz
    //  Q16.16 format
    localparam signed[31 : 0] PLL_K1 = 32'h0027_bace;  // Proportional
    localparam signed[31 : 0] PLL_K2 = 32'h0325_5518;  // Integral
    localparam signed[31 : 0] DLL_K1 = 32'h0005_4c1c;  // Proportional
    localparam signed[31 : 0] DLL_K2 = 32'h000e_5127;  // Integral

    localparam EARLY_LATE_SAMPLES = 2;

    logic signed[CODE_NCO_WIDTH - 1 : 0] code_nco_phase_inc;   // Phase increment for code NCO
    logic[CODE_NCO_WIDTH - 1 : 0] code_nco_phase;       // Code NCO phase accumulator
    logic[11 : 0] code_phase_int;       // Integer part of code phase
    logic[DAT_WIDTH - 1 : 0] code_phase_frac;      // Fractional part for interpolation
    // Early/Prompt/Late code addresses
    logic[11 : 0] early_code_addr;
    logic[11 : 0] late_code_addr;
    logic[11 : 0] prompt_code_addr;
    // Early/Prompt/Late code values
    logic signed[DAT_WIDTH - 1 : 0] early_code;
    logic signed[DAT_WIDTH - 1 : 0] late_code;
    logic signed[DAT_WIDTH - 1 : 0] prompt_code;
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
    // PLL filter states
    logic signed[2* ACC_WIDTH - 1 : 0] pll_error;
    logic signed[CARR_NCO_WIDTH - 1 : 0] pll_integrator;
    logic signed[CARR_NCO_WIDTH - 1 : 0] pll_filter_out;
    // DLL filter states
    logic signed[2* ACC_WIDTH - 1 : 0] dll_error;
    logic signed[CODE_NCO_WIDTH - 1 : 0] dll_integrator;
    logic signed[CODE_NCO_WIDTH - 1 : 0] dll_filter_out;
    // Timing signals
    logic[31 : 0] sample_counter;
    logic dump_correlators;
    // Navigation bit extraction
    logic[15 : 0] bit_counter;
    logic[7 : 0] pll_lock_counter;
    logic[7 : 0] dll_lock_counter;

    always_comb begin
        prompt_code_addr = code_phase_int;
        early_code_addr = (prompt_code_addr + CA_CODE_LENGTH - EARLY_LATE_SAMPLES) % CA_CODE_LENGTH;
        late_code_addr = (prompt_code_addr + EARLY_LATE_SAMPLES) % CA_CODE_LENGTH;
    end

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            early_code <= '0;
            late_code <= '0;
            prompt_code <= '0;
        end
        else if(i_valid) begin
            early_code <= i_prn_rom[early_code_addr];
            late_code <= i_prn_rom[late_code_addr];
            prompt_code <= i_prn_rom[prompt_code_addr];
        end
    end

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            code_nco_phase <= '0;
            code_phase_int <= i_init_code_phase[15 : 4]; // Extract integer part
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

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            mixed_i <= '0;
            mixed_q <= '0;
        end 
        else if(i_valid) begin
            mixed_i <= (((i_data_i * carr_cos) - (i_data_q * carr_sin)) >> (DAT_WIDTH - 1));
            mixed_q <= (((i_data_q * carr_cos) + (i_data_i * carr_sin)) >> (DAT_WIDTH - 1));
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
            early_corr_i <= (mixed_i * early_code) >>>  (DAT_WIDTH - 1);
            early_corr_q <= (mixed_q * early_code) >>> (DAT_WIDTH - 1);
            late_corr_i <= (mixed_i * late_code) >>> (DAT_WIDTH - 1);
            late_corr_q <= (mixed_q * late_code) >>> (DAT_WIDTH - 1);
            prompt_corr_i <= (mixed_i * prompt_code) >>> (DAT_WIDTH - 1);
            prompt_corr_q <= (mixed_q * prompt_code) >>> (DAT_WIDTH - 1);
        end
    end

    // Integrate and dump control
    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            sample_counter <= '0;
            dump_correlators <= 1'b0;
        end
        else if(i_valid) begin
            // One millisecond is 4096 samples at 4.096 MSPS
            if(sample_counter >= CA_CODE_LENGTH - 1) begin
                sample_counter <= '0;
                dump_correlators <= 1'b1;
            end
            else begin
                sample_counter <= sample_counter + 1;
                dump_correlators <= 1'b0;
            end
        end
        else begin
            dump_correlators <= 1'b0;
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
            o_valid <= 1'b0;
        end
        else if(dump_correlators) begin
            early_acc_i <= '0;
            early_acc_q <= '0;
            late_acc_i <= '0;
            late_acc_q <= '0;
            prompt_acc_i <= '0;
            prompt_acc_q <= '0;
            o_valid <= 1'b1;
            o_prompt_i <= prompt_acc_i[15 : 0];
            o_prompt_q <= prompt_acc_q[15 : 0];
        end
        else if(i_valid) begin
            early_acc_i <= early_acc_i + {{(ACC_WIDTH - DAT_WIDTH){early_corr_i[DAT_WIDTH - 1]}}, early_corr_i};
            early_acc_q <= early_acc_q + {{(ACC_WIDTH - DAT_WIDTH){early_corr_q[DAT_WIDTH - 1]}}, early_corr_q};
            late_acc_i <= late_acc_i + {{(ACC_WIDTH - DAT_WIDTH){late_corr_i[DAT_WIDTH - 1]}}, late_corr_i};
            late_acc_q <= late_acc_q + {{(ACC_WIDTH - DAT_WIDTH){late_corr_q[DAT_WIDTH - 1]}}, late_corr_q};
            prompt_acc_i <= prompt_acc_i + {{(ACC_WIDTH - DAT_WIDTH){prompt_corr_i[DAT_WIDTH - 1]}}, prompt_corr_i};
            prompt_acc_q <= prompt_acc_q + {{(ACC_WIDTH - DAT_WIDTH){prompt_corr_q[DAT_WIDTH - 1]}}, prompt_corr_q};
            o_valid <= 1'b0;
        end else begin
            o_valid <= 1'b0;
        end
    end

    // PLL discriminator and loop filter
    localparam signed[63 :0] PLL_TEMP = 2**CARR_NCO_WIDTH / SAMPLING_RATE;

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            pll_error <= '0;
            pll_integrator <= '0;
            pll_filter_out <= i_init_doppler * PLL_TEMP;
            carr_nco_phase_inc <= i_init_doppler * PLL_TEMP;
        end
        else if(dump_correlators) begin
            // PLL discriminator (arctangent discriminator approximation)
            pll_error <= (prompt_acc_i * prompt_acc_q) >> (DAT_WIDTH - 1);
            pll_integrator <= pll_integrator + ((pll_error * PLL_K2) >>> 16);
            pll_filter_out <= ((pll_error * PLL_K1) >>> 16) + pll_integrator;
            carr_nco_phase_inc <= i_init_doppler * PLL_TEMP + pll_filter_out;
        end
    end

    // DLL discriminator and loop filter
    localparam signed[63 : 0] DLL_TEMP = 1023000 * 2**CODE_NCO_WIDTH / SAMPLING_RATE;

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            dll_error <= '0;
            dll_integrator <= '0;
            dll_filter_out <= '0;
            // Base code rate (1.023 MHz / 4.096 MHz * 2^CODE_NCO_WIDTH)
            code_nco_phase_inc <= DLL_TEMP;
        end
        else if(dump_correlators) begin
            // DLL discriminator (early-late envelope)
            dll_error <= ((((early_acc_i * early_acc_i) + (early_acc_q * early_acc_q)) -
                        ((late_acc_i * late_acc_i) + (late_acc_q * late_acc_q))) >>> (DAT_WIDTH - 1));
            dll_integrator <= dll_integrator + ((dll_error * DLL_K2) >>> 16);
            dll_filter_out <= ((dll_error * DLL_K1) >>> 16) + dll_integrator;
            // Base rate + adjustment from loop filter
            code_nco_phase_inc <= DLL_TEMP + dll_filter_out;
        end
    end

    logic current_bit_sign;
    assign current_bit_sign = prompt_acc_i[ACC_WIDTH - 1];

    // Navigation bit extraction
    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            o_nav_bit <= 1'b0;
            o_nav_bit_valid <= 1'b0;
            bit_counter <= '0;
        end
        else if(dump_correlators) begin
            bit_counter <= bit_counter + 1;
            if(bit_counter >= 20) begin
                // Output bit (inverted since 1 is positive correlation, 0 is negative)
                o_nav_bit <= ~current_bit_sign;
                o_nav_bit_valid <= 1'b1;
                bit_counter <= '0;
            end
            else begin
                o_nav_bit_valid <= 1'b0;
            end
        end else begin
            o_nav_bit_valid <= 1'b0;
        end
    end

    // PLL lock detector
    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            pll_lock_counter <= '0;
            o_pll_lock <= 1'b0;
        end
        else if(dump_correlators) begin
            if((prompt_acc_i * prompt_acc_i) > ((prompt_acc_q * prompt_acc_q) << 2)) begin
                // I power > 4*Q power indicates good phase lock
                if(pll_lock_counter < 8'hFF) begin
                    pll_lock_counter <= pll_lock_counter + 1;
                end
            end
            else begin
                if(pll_lock_counter > 8'h00) begin
                    pll_lock_counter <= pll_lock_counter - 1;
                end
            end
            o_pll_lock <= (pll_lock_counter > 8'h80);
        end
    end

    // DLL lock detector
    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            dll_lock_counter <= '0;
            o_dll_lock <= 1'b0;
        end
        else if(dump_correlators) begin
            if(((prompt_acc_i * prompt_acc_i) + (prompt_acc_q * prompt_acc_q)) > 
                ((early_acc_i * early_acc_i + early_acc_q * early_acc_q) + 
                 (late_acc_i * late_acc_i + late_acc_q * late_acc_q))) begin
                // Prompt power > early + late power indicates good code lock
                if(dll_lock_counter < 8'hFF) begin
                    dll_lock_counter <= dll_lock_counter + 1;
                end
            end
            else begin
                if(dll_lock_counter > 8'h00) begin
                    dll_lock_counter <= dll_lock_counter - 1;
                end
            end
            o_dll_lock <= (dll_lock_counter > 8'h80);
        end
    end
endmodule
