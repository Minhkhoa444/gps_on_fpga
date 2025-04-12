`timescale 1ns/1ps

module gps_top_wrapper #(
    parameter axil_addr_width = 10,
    parameter axil_data_width = 32,
    parameter num_trackers = 4,
    parameter ACC_WIDTH = 32,
    parameter DAT_WIDTH = 16
)
(
    input wire                              clk,
    input wire                              rst_n,

    input wire                              s_axis_tvalid,
    input wire signed [DAT_WIDTH - 1 : 0]   s_axis_gps_i,
    input wire signed [DAT_WIDTH - 1 : 0]   s_axis_gps_q,
    output wire                             s_axis_tready,

    output wire [7:0]                       nav_tdata,
    output wire                             nav_tvalid
);

gps_top #(
    .axil_addr_width(axil_addr_width),
    .axil_data_width(axil_data_width),
    .num_trackers(num_trackers),
    .ACC_WIDTH(ACC_WIDTH)
) dut (
    .clk(clk),
    .rst_n(rst_n),

    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_gps_i(s_axis_gps_i),
    .s_axis_gps_q(s_axis_gps_q),
    .s_axis_tready(s_axis_tready),

    .nav_tdata(nav_tdata),
    .nav_tvalid(nav_tvalid)
);

endmodule