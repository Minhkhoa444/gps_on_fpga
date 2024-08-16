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

    localparam[2 : 0] S_IDLE = 'h0,
                    S_TRANSFER = 'h1;

    reg[2 : 0] state_r, next_state_r;
    reg[7 : 0] cur_byte_r;
    reg[1 : 0] dibit_counter_r;
    
    reg tx_ready_r;

    reg txen_r;

    reg[7 : 0] debug_bytes_r;

    always @(posedge clk50_i) begin
        if(rst_i) begin
            state_r <= S_IDLE;
            next_state_r <= S_IDLE;
            dibit_counter_r <= 'h0;
            txen_r <= 1'h0;
        end
        else begin
            state_r <= next_state_r;
            dibit_counter_r <= dibit_counter_r + 1'h1;
            if(dibit_counter_r > 'h0) begin
                cur_byte_r <= {2'b00, cur_byte_r[7 : 2]};
            end
        end
    end

    always @(*) begin
        case(state_r)
            S_IDLE:
            begin
                tx_ready_r = 1'h1;
                if(tx_valid_i && tx_ready_o && dibit_counter_r == 'h0) begin
                    next_state_r = S_TRANSFER;
                end
                txen_r = 1'h0;
                cur_byte_r = 'h0;
            end
            S_TRANSFER:
            begin
                if(data_last_i && dibit_counter_r == 'h0) begin
                    next_state_r = S_IDLE;
                end
                if(dibit_counter_r > 'h0) begin
                    tx_ready_r = 1'h0;
                end
                if(dibit_counter_r == 'h0) begin
                    tx_ready_r = 1'h1;
                end
                if(dibit_counter_r == 'h0) begin
                    cur_byte_r = data_in_i;
                end
                txen_r = 1'h1;
            end
        endcase
        debug_bytes_r = cur_byte_r;
    end

    assign tx_ready_o = tx_ready_r;
    assign txd_o = cur_byte_r[1 : 0];
    assign txen_o = txen_r;
    assign debug_bytes_o = debug_bytes_r;
endmodule
