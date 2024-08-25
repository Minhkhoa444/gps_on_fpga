module crc32(
    input                                   clk_i,
    input                                   rst_i,
    input[7 : 0]                            data_in_i,
    input                                   crc_en_i,

    output[31 : 0]                          crc_o
);
    reg[31 : 0] crc_r;
    reg[31 : 0] next_crc_r;
    
    reg[7 : 0] data_in_r;

    assign data_in_r = {data_in_i[0], data_in_i[1], data_in_i[2], data_in_i[3], data_in_i[4], data_in_i[5], data_in_i[6], data_in_i[7]};

    assign next_crc_r[0] = crc_r[24] ^ crc_r[30] ^ data_in_r[0] ^ data_in_r[6];
    assign next_crc_r[1] = crc_r[24] ^ crc_r[25] ^ crc_r[30] ^ crc_r[31] ^ data_in_r[0] ^ data_in_r[1] ^ data_in_r[6] ^ data_in_r[7];
    assign next_crc_r[2] = crc_r[24] ^ crc_r[25] ^ crc_r[26] ^ crc_r[30] ^ crc_r[31] ^ data_in_r[0] ^ data_in_r[1] ^ data_in_r[2] ^ data_in_r[6] ^ data_in_r[7];
    assign next_crc_r[3] = crc_r[25] ^ crc_r[26] ^ crc_r[27] ^ crc_r[31] ^ data_in_r[1] ^ data_in_r[2] ^ data_in_r[3] ^ data_in_r[7];
    assign next_crc_r[4] = crc_r[24] ^ crc_r[26] ^ crc_r[27] ^ crc_r[28] ^ crc_r[30] ^ data_in_r[0] ^ data_in_r[2] ^ data_in_r[3] ^ data_in_r[4] ^ data_in_r[6];
    assign next_crc_r[5] = crc_r[24] ^ crc_r[25] ^ crc_r[27] ^ crc_r[28] ^ crc_r[29] ^ crc_r[30] ^ crc_r[31] ^ data_in_r[0] ^ data_in_r[1] ^ data_in_r[3] ^ data_in_r[4] ^ data_in_r[5] ^ data_in_r[6] ^ data_in_r[7];
    assign next_crc_r[6] = crc_r[25] ^ crc_r[26] ^ crc_r[28] ^ crc_r[29] ^ crc_r[30] ^ crc_r[31] ^ data_in_r[1] ^ data_in_r[2] ^ data_in_r[4] ^ data_in_r[5] ^ data_in_r[6] ^ data_in_r[7];
    assign next_crc_r[7] = crc_r[24] ^ crc_r[26] ^ crc_r[27] ^ crc_r[29] ^ crc_r[31] ^ data_in_r[0] ^ data_in_r[2] ^ data_in_r[3] ^ data_in_r[5] ^ data_in_r[7];
    assign next_crc_r[8] = crc_r[0] ^ crc_r[24] ^ crc_r[25] ^ crc_r[27] ^ crc_r[28] ^ data_in_r[0] ^ data_in_r[1] ^ data_in_r[3] ^ data_in_r[4];
    assign next_crc_r[9] = crc_r[1] ^ crc_r[25] ^ crc_r[26] ^ crc_r[28] ^ crc_r[29] ^ data_in_r[1] ^ data_in_r[2] ^ data_in_r[4] ^ data_in_r[5];
    assign next_crc_r[10] = crc_r[2] ^ crc_r[24] ^ crc_r[26] ^ crc_r[27] ^ crc_r[29] ^ data_in_r[0] ^ data_in_r[2] ^ data_in_r[3] ^ data_in_r[5];
    assign next_crc_r[11] = crc_r[3] ^ crc_r[24] ^ crc_r[25] ^ crc_r[27] ^ crc_r[28] ^ data_in_r[0] ^ data_in_r[1] ^ data_in_r[3] ^ data_in_r[4];
    assign next_crc_r[12] = crc_r[4] ^ crc_r[24] ^ crc_r[25] ^ crc_r[26] ^ crc_r[28] ^ crc_r[29] ^ crc_r[30] ^ data_in_r[0] ^ data_in_r[1] ^ data_in_r[2] ^ data_in_r[4] ^ data_in_r[5] ^ data_in_r[6];
    assign next_crc_r[13] = crc_r[5] ^ crc_r[25] ^ crc_r[26] ^ crc_r[27] ^ crc_r[29] ^ crc_r[30] ^ crc_r[31] ^ data_in_r[1] ^ data_in_r[2] ^ data_in_r[3] ^ data_in_r[5] ^ data_in_r[6] ^ data_in_r[7];
    assign next_crc_r[14] = crc_r[6] ^ crc_r[26] ^ crc_r[27] ^ crc_r[28] ^ crc_r[30] ^ crc_r[31] ^ data_in_r[2] ^ data_in_r[3] ^ data_in_r[4] ^ data_in_r[6] ^ data_in_r[7];
    assign next_crc_r[15] = crc_r[7] ^ crc_r[27] ^ crc_r[28] ^ crc_r[29] ^ crc_r[31] ^ data_in_r[3] ^ data_in_r[4] ^ data_in_r[5] ^ data_in_r[7];
    assign next_crc_r[16] = crc_r[8] ^ crc_r[24] ^ crc_r[28] ^ crc_r[29] ^ data_in_r[0] ^ data_in_r[4] ^ data_in_r[5];
    assign next_crc_r[17] = crc_r[9] ^ crc_r[25] ^ crc_r[29] ^ crc_r[30] ^ data_in_r[1] ^ data_in_r[5] ^ data_in_r[6];
    assign next_crc_r[18] = crc_r[10] ^ crc_r[26] ^ crc_r[30] ^ crc_r[31] ^ data_in_r[2] ^ data_in_r[6] ^ data_in_r[7];
    assign next_crc_r[19] = crc_r[11] ^ crc_r[27] ^ crc_r[31] ^ data_in_r[3] ^ data_in_r[7];
    assign next_crc_r[20] = crc_r[12] ^ crc_r[28] ^ data_in_r[4];
    assign next_crc_r[21] = crc_r[13] ^ crc_r[29] ^ data_in_r[5];
    assign next_crc_r[22] = crc_r[14] ^ crc_r[24] ^ data_in_r[0];
    assign next_crc_r[23] = crc_r[15] ^ crc_r[24] ^ crc_r[25] ^ crc_r[30] ^ data_in_r[0] ^ data_in_r[1] ^ data_in_r[6];
    assign next_crc_r[24] = crc_r[16] ^ crc_r[25] ^ crc_r[26] ^ crc_r[31] ^ data_in_r[1] ^ data_in_r[2] ^ data_in_r[7];
    assign next_crc_r[25] = crc_r[17] ^ crc_r[26] ^ crc_r[27] ^ data_in_r[2] ^ data_in_r[3];
    assign next_crc_r[26] = crc_r[18] ^ crc_r[24] ^ crc_r[27] ^ crc_r[28] ^ crc_r[30] ^ data_in_r[0] ^ data_in_r[3] ^ data_in_r[4] ^ data_in_r[6];
    assign next_crc_r[27] = crc_r[19] ^ crc_r[25] ^ crc_r[28] ^ crc_r[29] ^ crc_r[31] ^ data_in_r[1] ^ data_in_r[4] ^ data_in_r[5] ^ data_in_r[7];
    assign next_crc_r[28] = crc_r[20] ^ crc_r[26] ^ crc_r[29] ^ crc_r[30] ^ data_in_r[2] ^ data_in_r[5] ^ data_in_r[6];
    assign next_crc_r[29] = crc_r[21] ^ crc_r[27] ^ crc_r[30] ^ crc_r[31] ^ data_in_r[3] ^ data_in_r[6] ^ data_in_r[7];
    assign next_crc_r[30] = crc_r[22] ^ crc_r[28] ^ crc_r[31] ^ data_in_r[4] ^ data_in_r[7];
    assign next_crc_r[31] = crc_r[23] ^ crc_r[29] ^ data_in_r[5];

    always @(posedge clk_i) begin
        if(rst_i) begin
            crc_r <= 'hFFFF_FFFF;
        end
        else begin
            if(crc_en_i) begin
                crc_r <= next_crc_r;
            end
        end
    end

    assign crc_o = {
        crc_r[0], crc_r[1], crc_r[2], crc_r[3], crc_r[4], crc_r[5], crc_r[6], crc_r[7],
        crc_r[8], crc_r[9], crc_r[10], crc_r[11], crc_r[12], crc_r[13], crc_r[14], crc_r[15],
        crc_r[16], crc_r[17], crc_r[18], crc_r[19], crc_r[20], crc_r[21], crc_r[22], crc_r[23],
        crc_r[24], crc_r[25], crc_r[26], crc_r[27], crc_r[28], crc_r[29], crc_r[30], crc_r[31]
    } ^ 'hFFFF_FFFF;
endmodule
