module cic_filter #(
    parameter data_width = 16,
    parameter fraction_width = 15,
    parameter filter_R = 10,
    parameter filter_N = 5
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

    reg s_axis_tready_r;
    reg m_axis_tvalid_r;

    reg signed[data_width + $clog2(filter_R**filter_N) - 1 : 0] integrator_r[0 : filter_N];
    
    reg[31 : 0] counter_r;
    reg signed[data_width + $clog2(filter_R**filter_N) - 1 : 0] decimation_out_r; 
    
    reg signed[data_width + $clog2(filter_R**filter_N) - 1 : 0] comb_r[0 : filter_N];
    reg signed[data_width + $clog2(filter_R**filter_N) - 1 : 0] comb_next_r[0 : filter_N];
    
    always @(posedge aclk) begin
        if(rst_i) begin
            s_axis_tready_r <= 1'h0;
        end
        else begin
            s_axis_tready_r <= 1'h1;
        end
    end

    //  integrator stage

    always @(posedge aclk) begin
        if(rst_i) begin
            for(i = 0; i < filter_N + 1; i = i + 1) begin
                integrator_r[i] <= 'h0;
            end
        end 
        else if(s_axis_tvalid) begin
            integrator_r[0] <= s_axis_tdata;
            for(i = 1; i < filter_N + 1; i = i + 1) begin
                integrator_r[i] <= integrator_r[i] + integrator_r[i - 1];
            end
        end
    end

    //  decimation stage

    always @(posedge aclk) begin
        if(rst_i) begin
            counter_r <= 'h0;
            m_axis_tvalid_r <= 1'h0;
            decimation_out_r <= 'h0;
        end
        else if(counter_r == filter_R - 1) begin
            counter_r <= 'h0;
            m_axis_tvalid_r <= 1'h1;
            decimation_out_r <= integrator_r[filter_N];
        end
        else begin
            counter_r <= counter_r + 1'h1;
            m_axis_tvalid_r <= 1'h0;
            decimation_out_r <= 'h0;
        end
    end

    reg m_axis_tvalid_temp_r;

    always @(posedge aclk) begin
        if(rst_i) begin
            m_axis_tvalid_temp_r <= 1'h0;
        end
        else begin
            m_axis_tvalid_temp_r <= m_axis_tvalid_r;
        end
    end

    //  comb stage
    
    always @(posedge aclk) begin
        if(rst_i) begin
            for(i = 0; i < filter_N + 1; i = i + 1) begin
                comb_r[0] <= 'h0;
                //comb_r[i] <= 'h0;
                comb_next_r[i] <= 'h0;
            end
        end 
        else if(m_axis_tvalid_r && m_axis_tready) begin
            comb_r[0] <= decimation_out_r;
            for(i = 0; i < filter_N + 1; i = i + 1) begin
                comb_next_r[i] <= comb_r[i];
            end
        end
    end

    always @(*) begin
        for(i = 1; i < filter_N + 1; i = i + 1) begin
            comb_r[i] = comb_r[i - 1] - comb_next_r[i - 1];
        end
    end

    initial begin
        $display("\nfilter_N * $clog2(filter_R) = %0d\n", $clog2(filter_R**filter_N));
    end

    assign m_axis_tdata = comb_r[filter_N] >>> ($clog2(filter_R**filter_N));   //  gain compensation
    assign m_axis_tvalid = m_axis_tvalid_temp_r;
    assign s_axis_tready = s_axis_tready_r;
endmodule
