module fir_filter #(
    parameter data_width = 16,
    parameter fraction_width = 15,
    parameter coeff_width = 16,
    parameter filter_N = 100,
    parameter coeff_file = "../mem/coeff.mem"
) (    
    input                                   aclk,
    input                                   rst_i,

    input signed[data_width - 1 : 0]        s_axis_tdata,
    input                                   s_axis_tvalid,
    output                                  s_axis_tready,

    output signed[data_width - 1 : 0]       m_axis_tdata,
    output                                  m_axis_tvalid,
    input                                   m_axis_tready
);
    integer i;

    reg signed[data_width - 1 : 0] pipe_r[0 : filter_N];
    reg signed[coeff_width - 1 : 0] coeff_mem[0 : filter_N];
    reg signed[coeff_width + data_width : 0] acc_r[0 : filter_N];
    
    reg signed[data_width + coeff_width : 0] m_axis_tdata_r[0 : filter_N + 1];
    reg m_axis_tvalid_r;
    reg m_axis_tvalid_temp_r;
    reg s_axis_tready_r;

    //  Read coefficients.
    initial begin
        $readmemb(coeff_file, coeff_mem);
    end
    
    //  Valid output only appears when acc_r[] changed, or 1 cycle
    //  after pipe_r[] changed.
    //  However pipe_r[] only changed 1 cycle after input data is valid.
    //  Therefore we need to delay valid output signal by 2 cycle.
    always @(posedge aclk) begin
        if(rst_i) begin
            m_axis_tvalid_temp_r <= 1'h0;
            m_axis_tvalid_r <= 1'h0;
            s_axis_tready_r <= 1'h0;
        end
        else begin
            m_axis_tvalid_temp_r <= s_axis_tvalid;
            m_axis_tvalid_r <= m_axis_tvalid_temp_r;
            s_axis_tready_r <= 1'h1;
        end
    end

    //  Pipelining logic, only accept input when handshake occurs at
    //  the data input side.
    always @(posedge aclk) begin
        if(rst_i) begin 
            for(i = 0; i < filter_N + 1; i = i + 1) begin
                pipe_r[i] <= 'h0;
            end
        end
        else if(s_axis_tvalid && s_axis_tready) begin
            pipe_r[0] <= s_axis_tdata;
            for(i = 1; i < filter_N + 1; i = i + 1) begin
                pipe_r[i] <= pipe_r[i - 1];
            end
        end
        else begin
            for(i = 0; i < filter_N + 1; i = i + 1) begin
                pipe_r[i] <= 'h0;
            end
        end
    end

    //  Data accumulation stage, take advantage of FPGA multiplier
    //  block (this is not well optimized for newer FPGA that has
    //  MAC block).
    always @(posedge aclk) begin
        if(rst_i) begin
            for(i = 0; i < filter_N + 1; i = i + 1) begin
                acc_r[i] <= 'h0;
            end
        end
        else if(s_axis_tvalid && s_axis_tready) begin
            for(i = 0; i < filter_N + 1; i = i + 1) begin
                acc_r[i] <= pipe_r[i] * coeff_mem[i];
            end
        end
        else begin
            for(i = 0; i < filter_N + 1; i = i + 1) begin
                acc_r[i] <= 'h0;
            end
        end
    end
    
    //  Serial adder stage, this will serially add from acc_r[0] to
    //  acc_r[filter_N].
    //  However, this structure is not efficient in term of resource
    //  usage, please note to improve it in the future.
    always @(*) begin
        if(rst_i) begin
            for(i = 0; i < filter_N + 2; i = i + 1) begin
                m_axis_tdata_r[i] = 'h0;
            end
        end
        else if(s_axis_tvalid && s_axis_tready) begin
            m_axis_tdata_r[0] = 'h0;
            for(i = 0; i < filter_N + 1; i = i + 1) begin
                m_axis_tdata_r[i + 1] = m_axis_tdata_r[i] + acc_r[i];
            end
        end
        else begin
            for(i = 0; i < filter_N + 2; i = i + 1) begin
                m_axis_tdata_r[i] = 'h0;
            end
        end
    end

    //  Only ouput data when data output handshake occurs.
    assign m_axis_tvalid = m_axis_tvalid_r;
    assign s_axis_tready = s_axis_tready_r;
    assign m_axis_tdata = (m_axis_tvalid && m_axis_tready) ? m_axis_tdata_r[filter_N + 1] >> fraction_width : 'h0;
endmodule
