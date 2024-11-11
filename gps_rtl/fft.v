module fft #(
    parameter data_width = 16,
    parameter fft_point = 1024
) (
    input                                   aclk,
    
    //  INPUT {real, img}
    input[2 * data_width - 1 : 0]           s_axis_tdata,
    input                                   s_axis_tvalid,
    output                                  s_axis_tready,

    //  OUTPUT {real, img}
    
);

endmodule
