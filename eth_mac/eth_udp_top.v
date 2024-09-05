module eth_udp_top #(
    parameter fifo_depth
) (
    
    input[1 : 0]                            rxd_i,
    input                                   loop_back_i
);

    wire[1 : 0] rxd_w;

    assign rxd_w = loop_back_i ? txd_o : rxd_i;

endmodule
