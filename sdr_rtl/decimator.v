module decimator #(
    parameter data_width = 16,
    parameter decimation_rate = 2 
) ( 
    input								aclk,
    input								rst_i,
    input signed[data_width - 1 : 0]	s_axis_tdata,
    input								s_axis_tvalid,
    output signed						s_axis_tready,
    output signed[data_width - 1 : 0]	m_axis_tdata,
    output								m_axis_tvalid,
    input								m_axis_tready
);

    integer count;
    reg got_data;

    reg signed[data_width - 1 : 0] m_axis_tdata_r;
    reg m_axis_tvalid_r;
    reg s_axis_tready_r;
    reg signed[data_width - 1 : 0] s_axis_tdata_temp;

    always @(posedge aclk) begin
        if (rst_i) begin
            m_axis_tvalid_r <= 0;
            s_axis_tready_r <= 0;
            count <= 0;
            got_data <= 0;
        end 
        else begin
            // got_data <= 0;
            s_axis_tready_r <= 1;
        end
    end

    always @(posedge aclk) begin
        // Case the decimation rate is 1 which means the frequency output is the same as the frequency input
        if (decimation_rate == 1 && s_axis_tvalid && s_axis_tready) begin
            s_axis_tdata_temp <= s_axis_tdata;
            got_data <= 1;
            m_axis_tvalid_r <= 1;
        end
        // Else perform algorithm to calculate right data to store in the s_axis_tdata_temp to transfer to the output's side
        else if (s_axis_tvalid && s_axis_tready && count == 0 && got_data == 0) begin
            s_axis_tdata_temp <= s_axis_tdata;
            count <= count + 1;
            got_data <= 1;
        end
        // This is the case when the data is sent to the output then we reset the counter
        else if (count == decimation_rate - 1) begin
            count <= 0;
            got_data <= 0;
        end 
        // This is the case when s_axis_tdata_temp is occupied and we are in the middle of the process
        else if (count > 0) begin
            count <= count + 1;
        end
    end

    // When got_data is on then we will send data out in next cycle (in total we need 2 cycles from the input to the output)
    always @(posedge aclk) begin
        if (got_data) begin
            m_axis_tvalid_r <= 1;
            got_data <= 0;
        end 
        else m_axis_tvalid_r <= 0;
    end

    assign m_axis_tvalid = m_axis_tvalid_r;
    assign s_axis_tready = s_axis_tready_r;
    assign m_axis_tdata = (m_axis_tready && m_axis_tvalid) ? s_axis_tdata_temp : 0;
endmodule