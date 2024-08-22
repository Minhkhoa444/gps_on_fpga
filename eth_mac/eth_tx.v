module eth_tx(
    input                                   clk50_i,
    input                                   rst_i,

    input[7 : 0]                            data_in_i,
    input                                   tx_valid_i,
    input                                   tx_last_i,

    output[1 : 0]                           txd_o,
    output                                  txen_o
);
    reg txen_temp_r;
    reg txen_temp1_r;
    reg txen_r;
    reg tx_last_temp_r;
    reg tx_last_temp1_r;
    
    reg[1 : 0] txd_r;
    reg[7 : 0] dibit_reg_r;

    always @(posedge clk50_i) begin
        if(rst_i) begin
            txen_temp_r <= 1'h0;
            txen_temp1_r <= 1'h0;
            txen_r <= 1'h0;
            tx_last_temp_r <= 1'h0;
            tx_last_temp1_r <= 1'h0;
            
            txd_r <= 'h0;
            dibit_reg_r <= 'h0;
        end
        else begin
            if(tx_valid_i) begin
                txen_temp_r <= 1'h1;
                dibit_reg_r <= data_in_i;
            end
            else if(tx_last_temp1_r) begin
                txen_temp_r <= 1'h0;
            end
            else begin
                txd_r <= dibit_reg_r[1 : 0];
                dibit_reg_r <= {2'b00, dibit_reg_r[7 : 2]};
            end
            
            tx_last_temp_r <= tx_last_i;
            tx_last_temp1_r <= tx_last_temp_r;
            txen_temp1_r <= txen_temp_r;
            txen_r <= txen_temp1_r;
        end
    end

    assign txd_o = txd_r;
    assign txen_o = txen_r;
endmodule
