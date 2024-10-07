module cic_filter #(
    parameter data_width = 16,
    parameter filter_N = 5,
    parameter filter_R = 1
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
    localparam extended_width = data_width + $clog2(filter_R**filter_N);
    localparam[63 : 0] filter_gain = 2**31 / (filter_R**filter_N);
    
    integer i;

    reg s_axis_tready_r;
    reg m_axis_tvalid_r;

    reg signed[extended_width - 1 : 0] integrator_r[0 : filter_N - 1];
    reg signed[extended_width - 1 : 0] comb_r[0 : filter_N - 1];
    reg signed[extended_width - 1 : 0] comb_next_r[0 : filter_N - 1];

    reg[31 : 0] counter_r;

    reg[extended_width + 32 - 1 : 0] gain_compensation_r;

    initial begin
        $display("\nfilter_gain = %d", filter_gain);
    end
    
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
            for(i = 0; i < filter_N; i = i + 1) begin
                integrator_r[i] <= 'h0;
            end
        end 
        else if(s_axis_tvalid && s_axis_tready) begin
            integrator_r[0] <= integrator_r[0] + s_axis_tdata;
            for(i = 1; i < filter_N; i = i + 1) begin
                integrator_r[i] <= integrator_r[i] + integrator_r[i - 1];
            end
        end
    end

    //  decimator stage
    
    always @(posedge aclk) begin
        if(rst_i) begin
            counter_r <= 'h0;
        end
        else if(s_axis_tvalid && s_axis_tready) begin
            if(counter_r == filter_R - 1)  begin
                counter_r <= 'h0;
            end
            else begin
                counter_r <= counter_r + 'h1;
            end
        end
        else begin
            counter_r <= 'h0;
        end
    end

    //  comb stage
    
    always @(posedge aclk) begin
        if(rst_i) begin
            for(i = 0; i < filter_N; i = i + 1) begin
                comb_r[i] <= 'h0;
                comb_next_r[i] <= 'h0;
            end
        end 
        else if(m_axis_tvalid && m_axis_tready) begin
            comb_r[0] <= integrator_r[filter_N - 1];
            comb_next_r[0] <= integrator_r[filter_N - 1] - comb_r[0];
            for(i = 1; i < filter_N; i = i + 1) begin
                comb_r[i] <= comb_next_r[i - 1];
                comb_next_r[i] <= comb_next_r[i - 1] - comb_r[i];
            end
        end
    end

    assign gain_compensation_r = comb_next_r[filter_N - 1] * $signed(filter_gain);
    assign m_axis_tvalid = s_axis_tvalid && counter_r == 'h0;
    assign s_axis_tready = s_axis_tready_r;
    assign m_axis_tdata = (m_axis_tvalid && m_axis_tready) ? gain_compensation_r >>> 31 : 'h0;
endmodule
