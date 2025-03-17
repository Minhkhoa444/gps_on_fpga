module down_converter #(
    parameter data_width = 16,
    parameter phase_width = 12,
    parameter LO_frequency = 10000000,
    parameter phase_incr = LO_frequency / (50000000 / 2**(phase_width + 2))
) (
    input                                   aclk,
    input                                   rst_i,

    input[data_width - 1 : 0]               s_axis_tdata,
    input                                   s_axis_tvalid,
    output                                  s_axis_tready,

    output[data_width * 2 - 1 : 0]          m_axis_tdata,
    output                                  m_axis_tvalid,
    input                                   m_axis_tready
);

    reg[data_width - 1 : 0] sine_r;
    reg[data_width - 1 : 0] cosine_r;
    reg[data_width * 2 - 1 : 0] m_axis_tdata_r;
    reg s_axis_tready_r;

    reg[phase_width + 1 : 0] dphase_r;

    // always @(*) begin
    //     dphase_r <= phase_incr;
    // end

    always @(posedge aclk) begin
        if(rst_i) begin
            s_axis_tready_r <= 1'h0;
            dphase_r <= 0;
        end
        else begin
            s_axis_tready_r <= m_axis_tready;
            dphase_r <= phase_incr;
        end
    end

    always @(posedge aclk) begin
        if(rst_i) begin
            m_axis_tdata_r <= 'h0;
        end
        else begin
           if(s_axis_tvalid && s_axis_tready) begin
                m_axis_tdata_r[data_width * 2 - 1 : data_width] <= s_axis_tdata * sine_r;
                m_axis_tdata_r[data_width - 1 : 0] <= s_axis_tdata * cosine_r;
            end
            else begin
                m_axis_tdata_r <= 'h0;
            end
        end
    end

    nco #(
        .phase_width(),
        .data_width()
    ) u_nco (
        .clk_i(aclk),
        .rst_i(rst_i),
        .dphase_i(dphase_r),

        .sine_o(sine_r),
        .cosine_o(cosine_r)
    );

    assign m_axis_tdata = m_axis_tdata_r;
    assign m_axis_tvalid = (s_axis_tvalid && s_axis_tready);
    assign s_axis_tready = s_axis_tready_r;

endmodule
