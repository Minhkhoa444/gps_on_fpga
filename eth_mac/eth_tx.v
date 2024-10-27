module eth_tx(
    input                                   clk50_i,
    input                                   rst_i,

    input[7 : 0]                            data_in_i,
    input                                   tx_valid_i,

    output[1 : 0]                           txd_o,
    output                                  txen_o
);
    reg[1 : 0] txd_r;
    reg txen_r;
    reg[1 : 0] dibit_counter_r;

    always @(posedge clk50_i) begin
        if(rst_i) begin
            dibit_counter_r <= 'h0;
        end
        else begin
            if(tx_valid_i) begin
                dibit_counter_r <= dibit_counter_r + 'h1;
            end
            else begin
                dibit_counter_r <= 'h0;
            end
        end
    end

    always @(posedge clk50_i) begin
        if(rst_i) begin
            txd_r <= 'h0;
            txen_r <= 1'h0;
        end
        else begin
            if(tx_valid_i) begin
                case(dibit_counter_r)
                    2'h0:
                    begin
                        txd_r <= data_in_i[1 : 0];
                    end
                    2'h1:
                    begin
                        txd_r <= data_in_i[3 : 2];
                    end
                    2'h2:
                    begin
                        txd_r <= data_in_i[5 : 4];
                    end
                    2'h3:
                    begin
                        txd_r <= data_in_i[7 : 6];
                    end
                endcase
                txen_r <= 1'h1;
            end
            else begin
                txd_r <= 'h0;
                txen_r <= 1'h0;
            end
        end
    end

    assign txd_o = txd_r;
    assign txen_o = txen_r;
endmodule
