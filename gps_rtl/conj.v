module conj #(
    parameter data_width = 16
) (
    input                                   aclk,
    input                                   rst_i,

    input signed[data_width - 1 : 0]        s_axis_tdata_real,
    input                                   s_axis_tvalid_real,
    output                                  s_axis_tready_real,

    input signed[data_width - 1 : 0]        s_axis_tdata_img,
    input                                   s_axis_tvalid_img,
    output                                  s_axis_tready_img,

    output signed[data_width - 1 : 0]       m_axis_tdata_real,
    output                                  m_axis_tvalid_real,
    input                                   m_axis_tready_real,

    output signed[data_width - 1 : 0]       m_axis_tdata_img,
    output                                  m_axis_tvalid_img,
    input                                   m_axis_tready_img
);
    reg signed[data_width - 1 : 0] m_axis_tdata_real_r;
    reg m_axis_tvalid_real_r;
    reg signed[data_width - 1 : 0] m_axis_tdata_img_r;
    reg m_axis_tvalid_img_r;

    always @(posedge aclk) begin
        if(rst_i) begin
            m_axis_tdata_real_r <= 'h0;
            m_axis_tvalid_real_r <= 1'h0;
            m_axis_tdata_img_r <= 'h0;
            m_axis_tvalid_img_r <= 1'h0;
        end
        else begin
            if(s_axis_tvalid_real && s_axis_tready_real) begin
                m_axis_tdata_real_r <= s_axis_tdata_real;
                m_axis_tvalid_real_r <= s_axis_tvalid_real;
            end
            if(s_axis_tvalid_img && s_axis_tready_img) begin
                m_axis_tdata_img_r <= -s_axis_tdata_img;
                m_axis_tvalid_img_r <= s_axis_tvalid_img;
            end
        end
    end

    assign m_axis_tdata_real = m_axis_tdata_real_r;
    assign m_axis_tvalid_real = m_axis_tvalid_real_r;
    assign m_axis_tdata_img = m_axis_tdata_img_r;
    assign m_axis_tvalid_img = m_axis_tvalid_img_r;
    assign s_axis_tready_real = m_axis_tready_real;
    assign s_axis_tready_img = m_axis_tready_img;
endmodule
