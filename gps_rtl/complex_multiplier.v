module complex_multiplier #(
    parameter data_width = 16
) (
    input[data_width - 1 : 0]               in1_re_i,
    input[data_width - 1 : 0]               in1_im_i,

    input[data_width - 1 : 0]               in2_re_i,
    input[data_width - 1 : 0]               in2_im_i,

    output[data_width * 2 - 1 : 0]          out_re_o,
    output[data_width * 2 - 1 : 0]          out_im_o
);

    assign out_re_o = in1_re_i * in2_re_i - in1_im_i * in2_im_i;
    assign out_im_o = in1_re_i * in2_im_i + in1_im_i * in2_re_i;
endmodule
