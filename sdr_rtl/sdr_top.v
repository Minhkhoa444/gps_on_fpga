module sdr_top #(
    parameter	adc_resolution = 12,
    parameter	data_width = 16
) (
    input[adc_resolution - 1 : 0]	adc_i,
    input				clk50_i,
    input				rst_i,

    output[data_width - 1 : 0]		i_o,
    output[data_width - 1 : 0]		q_o
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
    		.data_width(),
		.phase_width(),
		.LO_frequency(),
		.phase_incr()
    	) dc (
    		.aclk(clk50_i),
		.rst_i(rst_i),

		// ----------------- INPUT ----------------- //
		// input from slave
		.s_axis_tvalid(downconverter_vld_i),
		.s_axis_tdata(downconverter_d_i),

		// input from master
		.m_axis_tready(downconverter_rdy_i),
		// ----------------------------------------- //
	

		// ----------------- OUTPUT ---------------- //
		// output to slave
		.s_axis_tready(downconverter_rdy_o),
	
		// output to master	
		.m_axis_tvalid(downconverter_vld_o),
		.m_axis_tdata(downconverter_d_o)
		// ----------------------------------------- //
        );
	// assign downconverter_vld_i = ;		// still not known
	// assign downconverter_d_i = ;			// still not known
	assign downconverter_rdy_i = cicfilter_rdy_o[0];	// pick one of 2 cic filters, ask Khoa and Trung again here
    // ################################################################################ //



    // ########################### cic filter initialization ########################## //
    // cic_filter 0 initialization - 16-bit LSB
	cic_filter #(
		.data_width(),
		.filter_N(),
		.filter_R()
	) cicfil0 (
		.aclk(clk50_i),
		.rst_i(rst_i),

		// ----------------- INPUT ----------------- //
		// input from slave
		.s_axis_tvalid(cicfilter_vld_i[0]),
		.s_axis_tdata(cicfilter_d_i[0]),

		// input from master
		.m_axis_tready(cicfilter_rdy_i[0]),
		// ----------------------------------------- //
	

		// ----------------- OUTPUT ---------------- //
		// output to slave
		.s_axis_tready(cicfilter_rdy_o[0]),
	
		// output to master	
		.m_axis_tvalid(cicfilter_vld_o[0]),
		.m_axis_tdata(cicfilter_d_o[0])
		// ----------------------------------------- //
	);
	assign cicfilter_vld_i[0] = downconverter_vld_o;
	assign cicfilter_d_i[0] = downconverter_d_o[data_width - 1 : 0];	// 16 bit LSB
	assign cicfilter_rdy_i[0] = firdecimator_rdy_o[0];



    // cic_filter 1 initialization - 16-bit MSB
	cic_filter #(
		.data_width(),
		.filter_N(),
		.filter_R()
	) cicfil1 (
		.aclk(clk50_i),
		.rst_i(rst_i),

		// ----------------- INPUT ----------------- //
		// input from slave
		.s_axis_tvalid(cicfilter_vld_i[1]),
		.s_axis_tdata(cicfilter_d_i[1]),

		// input from master
		.m_axis_tready(cicfilter_rdy_i[1]),
		// ----------------------------------------- //
	

		// ----------------- OUTPUT ---------------- //
		// output to slave
		.s_axis_tready(cicfilter_rdy_o[1]),
	
		// output to master	
		.m_axis_tvalid(cicfilter_vld_o[1]),
		.m_axis_tdata(cicfilter_d_o[1])
		// ----------------------------------------- //
	);
	assign cicfilter_vld_i[1] = downconverter_vld_o;
	assign cicfilter_d_i[1] = downconverter_d_o[data_width*2 - 1 : data_width];	// 16 bit MSB
	assign cicfilter_rdy_i[1] = firdecimator_rdy_o[1];
    // ################################################################################ //




    // ########################## fir decimator initialization ######################## //   	
    // fir_decimator 0 initialization - 16-bit LSB
    	fir_decimator #(
		.data_width(),
		.fraction_width(),
		.coeff_width(),
		.filter_N(),
		.coeff_file(coeff_file),
		.decimation_rate()	
	) firdeci0 (
		.aclk(clk50_i),
		.rst_i(rst_i),

		// ----------------- INPUT ----------------- //
		// input from slave
		.s_axis_tvalid(firdecimator_vld_i[0]),
		.s_axis_tdata(firdecimator_d_i[0]),

		// input from master
		.m_axis_tready(firdecimator_rdy_i[0]),
		// ----------------------------------------- //
	

		// ----------------- OUTPUT ---------------- //
		// output to slave
		.s_axis_tready(firdecimator_rdy_o[0]),
	
		// output to master	
		.m_axis_tvalid(firdecimator_vld_o[0]),
		.m_axis_tdata(firdecimator_d_o[0])
		// ----------------------------------------- //
	);
	assign firdecimator_vld_i[0] = cicfilter_vld_o[0];
	assign firdecimator_d_i[0] = cicfilter_d_o[0];
	// assign firdecimator_rdy_i[0] = ;	// still unknown




    // fir_decimator 1 initialization - 16-bit LSB
    	fir_decimator #(
		.data_width(),
		.fraction_width(),
		.coeff_width(),
		.filter_N(),
		.coeff_file(coeff_file),
		.decimation_rate()	
	) firdeci0 (
		.aclk(clk50_i),
		.rst_i(rst_i),

		// ----------------- INPUT ----------------- //
		// input from slave
		.s_axis_tvalid(firdecimator_vld_i[1]),
		.s_axis_tdata(firdecimator_d_i[1]),

		// input from master
		.m_axis_tready(firdecimator_rdy_i[1]),
		// ----------------------------------------- //
	

		// ----------------- OUTPUT ---------------- //
		// output to slave
		.s_axis_tready(firdecimator_rdy_o[1]),
	
		// output to master	
		.m_axis_tvalid(firdecimator_vld_o[1]),
		.m_axis_tdata(firdecimator_d_o[1])
		// ----------------------------------------- //
	);
	assign firdecimator_vld_i[1] = cicfilter_vld_o[1];
	assign firdecimator_d_i[1] = cicfilter_d_o[1];
	// assign firdecimator_rdy_i[1] = ;	// still unknown
    // ################################################################################ //   	   
endmodule
