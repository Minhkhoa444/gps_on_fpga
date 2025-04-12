import acquisition_pkg::*;
import fft_pkg::*;
//import ifft_pkg::*;
`define ADD
module gps_top_2(
    input   logic                           clk,
    input   logic                           rst_n,

    // input data from sdr and output tready to sdr
    input   logic                           s_axis_tvalid,      // tvalid
    input   logic   signed  [15:0]          s_axis_tdata_i,     // gps_i
    input   logic   signed  [15:0]          s_axis_tdata_q,     // gps_q
    output  logic                           s_axis_tready,      // tready

    // input tready, output data from/to gps_dispatcher
    // input   logic                           m_axis_tready,   // tready from dispatcher
    output  logic                           m_axis_tvalid,      // tvalid to dispatcher
    `ifdef ADD
        output  logic   signed  [15:0]      m_axis_tdata,
    `else
        output  logic   signed  [15:0]      m_axis_tdata_im,    // imaginary part of ifft output    (corr result - imaginary)
        output  logic   signed  [15:0]      m_axis_tdata_re,    // real part of ifft output         (corr result - real)
    `endif
    output  logic           [4:0]           m_axis_tprn_id,     // prn id
    output  logic   signed  [14:0]          m_axis_td_shift,    // doppler shift
    output  logic           [11:0]          m_axis_tposition    // code phase delay (just simply the position of the current ifft output
                                                                // from this position, we can compute the code phase delay)
                                                                // formula: (position/4096) * 1023
);

    logic   signed  [DAT_WIDTH-1:0] ca_o_data   [0:31];
    logic   [11:0]  precomputed_ca_rdaddr;

    precomputed_ca ca (
        .clk(clk),
    
        .i_rdaddr(precomputed_ca_rdaddr),
        .o_data(ca_o_data)
    );

    gps_acquisition acq(
        .clk(clk),
        .rst_n(rst_n),

        // input data from precomputed_ca
        .ca_o_data(ca_o_data),
        .precomputed_ca_rdaddr(precomputed_ca_rdaddr),

        // input data from sdr and output tready to sdr
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tdata_i(s_axis_tdata_i),     
        .s_axis_tdata_q(s_axis_tdata_q),     
        .s_axis_tready(s_axis_tready),      

        // input tready, output data from/to gps_dispatcher
        .m_axis_tvalid(m_axis_tvalid),      
        `ifdef ADD
            .m_axis_tdata(m_axis_tdata),
        `else
            .m_axis_tdata_im(m_axis_tdata_im),    
            .m_axis_tdata_re(m_axis_tdata_re),    
        `endif
        .m_axis_tprn_id(m_axis_tprn_id),     
        .m_axis_td_shift(m_axis_td_shift),    
        .m_axis_tposition(m_axis_tposition)    
    );

endmodule