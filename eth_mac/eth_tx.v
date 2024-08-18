module eth_tx #(
    
) (
    input                                   clk50_i,
    input                                   rst_i,

    input[7 : 0]                            data_in_i,
    input                                   tx_valid_i,
    input                                   data_last_i,

    output                                  tx_ready_o,

    output[1 : 0]                           txd_o,
    output                                  txen_o,

    output[7 : 0]                           debug_bytes_o
);

    /*
        RMII bit ordering:
        D0 D1 D2 D3 D4 D5 D6 D7

        Dibit: TXD = D[1:0], then D[3:2]
    
    */

    reg tx_ready_r;
    reg txen_r;
    reg[1 : 0] dibit_counter;

    reg[7 : 0] debug_bytes_r;

    always @(posedge clk50_i) begin
        if(rst_i) begin
            tx_ready_r <= 1'h0;
            txen_r <= 1'h0;
            dibit_counter <= 'h0;
            debug_byte_r <= 'h0;
        end
        else begin
            if(dibit_counter == 'h0) begin
                tx_ready_r <= 1'h1;
            end
            dibit_counter <= dibit_counter + 1'h1;
        end
    end

    always @(*) begin
        debug_bytes_r = cur_byte_r;
    end

    assign tx_ready_o = tx_ready_r;
    assign txen_o = txen_r;
    assign debug_bytes_o = debug_bytes_r;
endmodule
