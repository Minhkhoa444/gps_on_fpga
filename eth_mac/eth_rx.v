module eth_rx(
    input                                   clk50_i,
    input                                   rst_i,


    output[7 : 0]                           data_out_o,
    output                                  rx_valid_o,
    output                                  rx_last_o,

    input[1 : 0]                            rxd_i,
    input                                   crs_dv_i
);

    reg[7 : 0] data_out_r;

    always @(posedge clk50_i) begin
        if(rst_i) begin

        end
        else begin
            if(crs_dv_i) begin

            end
        end
    end
    
    assign data_out_o = data_out_r;
endmodule
