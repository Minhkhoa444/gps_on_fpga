module sdr_top #(
    parameter	adc_resolution = 12,
    parameter	data_width = 16,
	parameter 	coeff_file = "../sdr_tb/fir_decimator_mem/coeff.mem"
) (
    input[data_width - 1 : 0]	s_axis_tdata,
    input                       s_axis_tvalid,
    output                      s_axis_tready,
    input				clk50_i,
    input				rst_i,

    output[data_width - 1 : 0]		i_o,
    output                          i_valid,
    output[data_width - 1 : 0]		q_o,
    output                          q_valid,
    input                           iq_ready
);


    // ------------------------------------------------- Downconverter  ------------------------------------------------- //
    	wire				downconverter_vld_i;		// still unknown, connect to s_axis_tvalid
    	wire[data_width*2 - 1 : 0]	downconverter_d_i;		// still unknown, connect to s_axis_tdata
    	wire				downconverter_rdy_i;		// connect to output s_axis_tready of 1 of 2 cicfilter
    
    	wire				downconverter_rdy_o;		// still unknown
    	wire				downconverter_vld_o;		// connect to input s_axis_tvalid of cicfilter
    	wire[data_width*2 - 1 : 0]	downconverter_d_o;		// connect to input s_axis_tdata of cicfilter: 16-bit MSB for one filter and the 16-bit LSB for the remaining filter
    // ------------------------------------------------------------------------------------------------------------------ //
	
	    
    // --------------------------------------------------- CIC Filter  -------------------------------------------------- //
	wire				cicfilter_vld_i[1:0];		// connect to output m_axis_tvalid of downconverter
        wire[data_width - 1 : 0]	cicfilter_d_i[1:0];		// connect to output m_axis_tdata of downconverter
        wire				cicfilter_rdy_i[1:0];		// connect to output s_axis_tready of fir decimator
    
        wire				cicfilter_rdy_o[1:0];		// connect to input m_axis_tready of downconverter
        wire				cicfilter_vld_o[1:0];		// connect to input s_axis_tvalid of fir decimator
        wire[data_width - 1 : 0]	cicfilter_d_o[1:0];		// connect to input s_axis_tdata of fir decimator
    // ------------------------------------------------------------------------------------------------------------------ //

		
    // -------------------------------------------------- FIR Decimator  ------------------------------------------------ //
	wire				firdecimator_vld_i[1:0];	// connect to output m_axis_tvalid of cic filter
        wire[data_width - 1 : 0]	firdecimator_d_i[1:0];		// connect to output m_axis_tdata of cic filter
        wire				firdecimator_rdy_i[1:0];	// still unknown
    
        wire				firdecimator_rdy_o[1:0];	// connect to input m_axis_tready of cic filter
        wire				firdecimator_vld_o[1:0];	// still unknown
        wire[data_width - 1 : 0]	firdecimator_d_o[1:0];		// still unknown
    // ------------------------------------------------------------------------------------------------------------------ //


    	
    // ######################### downconverter initialization ######################### //
	down_converter #(
    	//.data_width(),
		//.phase_width(),
		//.LO_frequency(),
		//.phase_incr()
    	) dc (
    	.aclk(clk50_i),
		.rst_i(rst_i),

		// ----------------- INPUT ----------------- //
		// input from slave
		.s_axis_tvalid(s_axis_tvalid),
		.s_axis_tdata(s_axis_tdata),

		// input from master
		.m_axis_tready(downconverter_rdy_i),
		// ----------------------------------------- //
	

		// ----------------- OUTPUT ---------------- //
		// output to slave
		.s_axis_tready(s_axis_tready),
	
		// output to master	
		.m_axis_tvalid(downconverter_vld_o),
		.m_axis_tdata(downconverter_d_o)
		// ----------------------------------------- //
        );
    // ################################################################################ //



    // ########################### cic filter initialization ########################## //
    // cic_filter 0 initialization - 16-bit MSB I
	cic_filter #(
		//.data_width(),
		//.filter_N(),
		//.filter_R()
	) cicfil0 (
		.aclk(clk50_i),
		.rst_i(rst_i),

		// ----------------- INPUT ----------------- //
		// input from slave
		.s_axis_tvalid(downconverter_vld_o),
		.s_axis_tdata(downconverter_d_o[2 * data_width - 1 : data_width]),

		// input from master
		.m_axis_tready(cicfilter_rdy_i[0]),
		// ----------------------------------------- //
	

		// ----------------- OUTPUT ---------------- //
		// output to slave
		.s_axis_tready(downconverter_rdy_i),
	
		// output to master	
		.m_axis_tvalid(cicfilter_vld_o[0]),
		.m_axis_tdata(cicfilter_d_o[0])
		// ----------------------------------------- //
	);



    // cic_filter 1 initialization - 16-bit MSB Q
	cic_filter #(
		//.data_width(),
		//.filter_N(),
		//.filter_R()
	) cicfil1 (
		.aclk(clk50_i),
		.rst_i(rst_i),

		// ----------------- INPUT ----------------- //
		// input from slave
		.s_axis_tvalid(downconverter_vld_o),
		.s_axis_tdata(downconverter_d_o[data_width - 1 : 0]),

		// input from master
		.m_axis_tready(cicfilter_rdy_i[1]),
		// ----------------------------------------- //
	

		// ----------------- OUTPUT ---------------- //
		// output to slave
		.s_axis_tready(downconverter_rdy_i),
	
		// output to master	
		.m_axis_tvalid(cicfilter_vld_o[1]),
		.m_axis_tdata(cicfilter_d_o[1])
		// ----------------------------------------- //
	);
    // ################################################################################ //


    // ########################## fir decimator initialization ######################## //   	
    // fir_decimator 0 initialization - 16-bit LSB
    	fir_decimator #(
		//.data_width(),
		//.fraction_width(),
		//.coeff_width(),
		//.filter_N(),
		//.coeff_file(coeff_file),
		//.decimation_rate()	
	) firdeci0 (
		.aclk(clk50_i),
		.rst_i(rst_i),

		// ----------------- INPUT -------------DSP Report: Generating DSP acc_r_reg[2], operation Mode is: (A''*(B:0x3fff5))'.---- //
		// input from slave
		.s_axis_tvalid(cicfilter_vld_o[0]),
		.s_axis_tdata(cicfilter_d_o[0]),

		// input from master
		.m_axis_tready(iq_ready),
		// ----------------------------------------- //
	

		// ----------------- OUTPUT ---------------- //
		// output to slave
		.s_axis_tready(cicfilter_rdy_i[0]),
	
		// output to master	
		.m_axis_tvalid(i_valid),
		.m_axis_tdata(i_o)
		// ----------------------------------------- //
	);

    // fir_decimator 1 initialization - 16-bit LSB
    fir_decimator #(
		    //.data_width(),
		    //.fraction_width(),
		    //.coeff_width(),
		    //.filter_N(),
		    //.coeff_file(coeff_file),
		    //.decimation_rate()	
	) firdeci1 (
		.aclk(clk50_i),
		.rst_i(rst_i),

		// ----------------- INPUT ----------------- //
		// input from slave
		.s_axis_tvalid(cicfilter_vld_o[1]),
		.s_axis_tdata(cicfilter_d_o[1]),

		// input from master
		.m_axis_tready(iq_ready),
		// ----------------------------------------- //
	

		// ----------------- OUTPUT ---------------- //
		// output to slave
		.s_axis_tready(cicfilter_rdy_i[1]),
	
		// output to master	
		.m_axis_tvalid(q_valid),
		.m_axis_tdata(q_o)
		// ----------------------------------------- //
	);
    // ################################################################################ //
endmodule
