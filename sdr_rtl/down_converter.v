module down_converter #(
    parameter data_width = 16,
    parameter frequency = 50000000
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

    wire[data_width - 1 : 0] sine_r;
    wire[data_width - 1 : 0] cosine_r;
    reg[data_width * 2 - 1 : 0] m_axis_tdata_r;

    always @(posedge aclk) begin
        if(rst_i) begin

        end
        else begin
           if(s_axis_tvalid && s_axis_tready) begin
                m_axis_tdata_r[data_width * 2 - 1 : data_width] <= s_axis_tdata * sine_r;
                m_axis_tdata_r[data_width - 1 : 0] <= s_axis_tdata * cosine_r;
            end
            else begin

            end
        end
    end

    nco #(
        .phase_width(),
        .data_width()
    ) u_nco (
        .clk_i(aclk),
        .rst_i(rst_i),
        .phase_i(),
        .sine_o(sine_r),
        .cosine_o(cosine_r)
    );

    assign m_axis_tdata = m_axis_tdata_r; 

endmodule
