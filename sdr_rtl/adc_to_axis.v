module adc_to_axis #(
    parameter adc_resolution = 12,
    parameter data_width = 16,  //  Must be greater than or equal adc_resolution
    parameter decimal_width = 15
) (
    input                                   aclk,
    input                                   rst_i,
    
    input[adc_resolution - 1 : 0]           adc_i,

    output[data_width - 1 : 0]              m_axis_tdata,
    output                                  m_axis_tvalid,
    input                                   m_axis_tready
);

    reg[data_width - 1 : 0] m_axis_tdata_r; 
    reg m_axis_tvalid_r;

    always @(posedge aclk) begin
        if(rst_i) begin
            m_axis_tvalid_r <= 1'h0;
        end else begin
            m_axis_tvalid_r <= 1'h1;
        end
    end

    always @(posedge aclk) begin
        if(rst_i) begin
            m_axis_tdata_r <= 'h0;
        end 
        else begin
            if(m_axis_tvalid_r && m_axis_tready) begin
                m_axis_tdata_r <= adc_i << (decimal_width - adc_resolution);
            end
            else begin
                m_axis_tdata_r <= 'h0;
            end
        end
    end
    
    assign m_axis_tdata = m_axis_tdata_r;
    assign m_axis_tvalid = m_axis_tvalid_r;
endmodule
