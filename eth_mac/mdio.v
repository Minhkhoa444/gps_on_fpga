module mdio(
    input                                   clk_i,
    input                                   rst_i,

    output                                  mdc_i,
    input                                   mdio_i,
    output                                  mdio_o,
    output                                  mdio_oe_o,

    input[1 : 0]                            opcode_i,
    input[4 : 0]                            phy_addr_i,
    input[4 : 0]                            reg_addr_i,

    input[15 : 0]                           wreg_data_i,
    output[15 : 0]                          rreg_data_o
);
    localparam[2 : 0] S_PREAMBLE = 'd0,
                    S_START = 'd1,
                    S_OPCODE = 'd2,
                    S_PHYREG = 'd3,
                    S_REGADDR = 'd4,
                    S_TURNAROUND = 'd5,
                    S_WDATA = 'd6,
                    S_RDATA = 'd7;

    reg mdc_r;

    reg[5 : 0] bit_counter_r;
    reg[5 : 0] next_bit_counter_r;

    reg[2 : 0] state_r;
    reg[2 : 0] next_state_r;

    always @(posedge clk_i) begin
        if(rst_i) begin
            state_r <= S_PREAMBLE;
            bit_counter_r <= 'h0;
        end
        else begin
            if(mdc_r) begin
                state_r <= next_state_r;
                bit_counter_r <= next_bit_counter_r;
            end
            else begin
                state_r <= state_r;
            end
        end
    end

endmodule
