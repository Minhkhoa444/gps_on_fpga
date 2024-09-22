module sdr_top #(
    parameter adc_resolution = 12,
    parameter data_width = 16
) (
    input[adc_resolution - 1 : 0]           adc_i,
    input                                   clk50_i,
    input                                   rst_i,

    output[data_width - 1 : 0]              i_o,
    output[data_width - 1 : 0]              q_o
);

endmodule
