module eth_udp_tx #(
    parameter fifo_depth = 1024,
    parameter src_mac = 48'h01_23_45_67_89_0A,
    parameter src_ip = 32'hC0_A8_00_2C,
    parameter src_port = 16'd1024,
    parameter dest_mac = 48'h00_D8_61_05_97_0F,
    parameter dest_ip = 32'hC0_A8_00_04,
    parameter dest_port = 16'd1024
) (
    input                                   aclk,     //  must be 50MHz
    input                                   rst_i,

    input[7 : 0]                            s_axis_tdata,
    input                                   s_axis_tvalid,
    output                                  s_axis_tready,

    output[7 : 0]                           udp_data_o,
    output                                  udp_valid_o,
    output                                  udp_tx_last_o
);
    integer i;

    localparam threshold_size = fifo_depth * 0.75;
    localparam payload_max_counter = threshold_size * 4;
    
    localparam[2 : 0] S_IDLE = 'd0,
                    S_HEADER = 'd1,
                    S_PAYLOAD = 'h2,
                    S_CRC32 = 'h3,
                    S_IPG = 'h4;

    localparam[15 : 0] UDP_SIZE = threshold_size + 8;   //  8 bytes UDP Header + Payload Size
    localparam[15 : 0] IP_SIZE = UDP_SIZE + 20;     //  20 bytes IPv4 Header + Payload Size (UDP total size)

    reg[31 : 0] ip_checksum_r;
    reg[31 : 0] udp_checksum_r;
    
    reg[2 : 0] state_r;
    reg[2 : 0] next_state_r;

    reg s_axis_tready_r;
    reg[7 : 0] udp_data_r;
    reg udp_valid_r;
    reg udp_tx_last_r;

    //  This transmit module will transmit the frame when the FIFO is 50% full
    //
    //  Each byte needs 4 cycles to transfer => it took 200 cycles to transfer
    //  the header. The transfer time between 2 packets will be:
    //          12 * 4 cycles IPG + 200 cycles next header = 248 cycles
    //  Therefore, for maximum efficiency, please use fifo depth greater than
    //  248 entries
    //  In addition, due to the minimum size requirement of Ethernet frame,
    //  the fifo size minimum must be greater than 36 enties (minimum 18 bytes
    //  payload data)
    reg[7 : 0] frame_header_r[50];
    reg[7 : 0] ipg_r[12];

    reg[15 : 0] bytes_counter_r;

    reg[31 : 0] crc_r;
    
    //  FIFO pins
    reg wr_en_r;
    reg rd_en_r;

    reg[7 : 0] wdata_r;
    reg[7 : 0] rdata_r;

    reg[$clog2(fifo_depth) : 0] fifo_count_r;
    reg fifo_empty_r;
    reg fifo_almost_empty_r;
    reg fifo_full_r;
    reg fifo_almost_full_r;

    initial begin
        //  Ethernet Preamble
        for(i = 0; i < 7; i = i + 1) begin
            frame_header_r[i] = 'h55;
        end
        //  Ethernet SFD
        frame_header_r[7] = 'hD5;
        //  Ethernet Destination Address
        frame_header_r[8] = (dest_mac & 'hFF00_0000_0000) >> 40;
        frame_header_r[9] = (dest_mac & 'h00FF_0000_0000) >> 32;
        frame_header_r[10] = (dest_mac & 'h0000_FF00_0000) >> 24;
        frame_header_r[11] = (dest_mac & 'h0000_00FF_0000) >> 16;
        frame_header_r[12] = (dest_mac & 'h0000_0000_FF00) >> 8;
        frame_header_r[13] = (dest_mac & 'h0000_0000_00FF) >> 0;
        //  Ethernet Source Address
        frame_header_r[14] = (src_mac & 'hFF00_0000_0000) >> 40;
        frame_header_r[15] = (src_mac & 'h00FF_0000_0000) >> 32;
        frame_header_r[16] = (src_mac & 'h0000_FF00_0000) >> 24;
        frame_header_r[17] = (src_mac & 'h0000_00FF_0000) >> 16;
        frame_header_r[18] = (src_mac & 'h0000_0000_FF00) >> 8;
        frame_header_r[19] = (src_mac & 'h0000_0000_00FF) >> 0;
        //  Ethernet Type IPv4
        frame_header_r[20] = 'h80;
        frame_header_r[21] = 'h00;
        //  IP Version 4, Header Size is 5 * 4 bytes = 20 bytes
        frame_header_r[22] = 'h45;
        //  DSCP and ECN unused
        frame_header_r[23] = 'h00;
        //  Total IPv4 Payload Size (included header and data)
        frame_header_r[24] = (IP_SIZE & 'hFF00) >> 8;
        frame_header_r[25] = (IP_SIZE & 'h00FF) >> 0;
        //  Identification
        frame_header_r[26] = 'hB3;
        frame_header_r[27] = 'hFE;
        //  Flag Reserved, No Fragment Offset
        frame_header_r[28] = 'h00;
        frame_header_r[29] = 'h00;
        //  Time to Live
        frame_header_r[30] = 'h80;
        //  UDP Transport Protocol
        frame_header_r[31] = 'h11;
        //  IPv4 Source IP address
        frame_header_r[34] = (src_ip & 'hFF00_0000) >> 24;
        frame_header_r[35] = (src_ip & 'h00FF_0000) >> 16;
        frame_header_r[36] = (src_ip & 'h0000_FF00) >> 8;
        frame_header_r[37] = (src_ip & 'h0000_00FF) >> 0;
        //  IPv4 Destination IP address
        frame_header_r[38] = (dest_ip & 'hFF00_0000) >> 24;
        frame_header_r[39] = (dest_ip & 'h00FF_0000) >> 16;
        frame_header_r[40] = (dest_ip & 'h0000_FF00) >> 8;
        frame_header_r[41] = (dest_ip & 'h0000_00FF) >> 0;
        //  IPv4 Header Checksum
        ip_checksum_r = (frame_header_r[22] + frame_header_r[23] + frame_header_r[24] +
                        frame_header_r[25] + frame_header_r[26] + frame_header_r[27] +
                        frame_header_r[28] + frame_header_r[29] + frame_header_r[30] +
                        frame_header_r[31] + frame_header_r[34] + frame_header_r[35] +
                        frame_header_r[36] + frame_header_r[37] + frame_header_r[38] +
                        frame_header_r[39] + frame_header_r[40] + frame_header_r[41]);
        ip_checksum_r = ip_checksum_r[31 : 16] + ip_checksum_r[15 : 0];
        ip_checksum_r = ~ip_checksum_r;
        frame_header_r[32] = (ip_checksum_r & 'hFF00) >> 8;
        frame_header_r[33] = (ip_checksum_r * 'h00FF) >> 0;
        //  UDP Source Port
        frame_header_r[42] = (src_port & 'hFF00) >> 8;
        frame_header_r[43] = (src_port & 'h00FF) >> 0;
        //  UDP Destination Port
        frame_header_r[44] = (dest_port & 'hFF00) >> 8;
        frame_header_r[45] = (dest_port & 'h00FF) >> 0;
        //  UDP Payload Length (included header and data)
        frame_header_r[46] = (UDP_SIZE & 'hFF00) >> 8;
        frame_header_r[47] = (UDP_SIZE & 'h00FF) >> 0;
        //  UDP Checksum
        udp_checksum_r = 'h0;
        frame_header_r[48] = (udp_checksum_r & 'hFF00) >> 8;
        frame_header_r[49] = (udp_checksum_r & 'h00FF) >> 0;
    end

    initial begin
        for(i = 0; i < 12; i = i + 1) begin
            ipg_r[i] = 'h0;
        end
    end

    always @(posedge aclk) begin
        if(rst_i) begin
            state_r <= S_IDLE;
        end
        else begin
            state_r <= next_state_r;
        end
    end

    always @(*) begin
        next_state_r = state_r;
        case(state_r)
            S_IDLE:
            begin
                if(fifo_count_r >= threshold_size) begin
                    next_state_r = S_HEADER;
                end
            end
            S_HEADER:
            begin
                if(bytes_counter_r == 'd200) begin
                    next_state_r = S_PAYLOAD;
                end
            end
            S_PAYLOAD:
            begin
                if(bytes_counter_r == payload_max_counter) begin
                    next_state_r = S_CRC32;
                end
            end
            S_CRC32:
            begin
                if(bytes_counter_r == 'd16) begin
                    next_state_r = S_IPG;
                end
            end
            S_IPG:
            begin
                if(fifo_count_r >= threshold_size) begin
                    next_state_r = S_HEADER;
                end
                else if(bytes_counter_r == 'd0) begin
                    next_state_r = S_IDLE;
                end
            end
        endcase
    end

    always @(posedge aclk) begin
        if(rst_i) begin
            bytes_counter_r <= 'h0;
        end
        else begin
            case(state_r)
                S_IDLE:
                begin
                    udp_data_r <= 'h0;
                    udp_valid_r <= 1'h0;
                    udp_tx_last_r <= 1'h0;
                end
                S_HEADER:
                begin
                    bytes_counter_r <= bytes_counter_r + 1'd1;
                    udp_data_r <= frame_header_r[bytes_counter_r[15 : 2]];
                    if(bytes_counter_r[1 : 0] == 2'd0) begin
                        udp_valid_r <= 1'h1;
                        udp_tx_last_r <= 1'h0;
                    end
                    else begin
                        udp_valid_r <= 1'h0;
                        udp_tx_last_r <= 1'h0;
                    end
                end
                S_PAYLOAD:
                begin
                    bytes_counter_r <= bytes_counter_r + 1'd1;
                    udp_data_r <= rdata_r;
                    if(bytes_counter_r[1 : 0] == 2'd0) begin
                        udp_valid_r <= 1'h1;
                        rd_en_r <= 1'h1;
                        udp_tx_last_r <= 1'h0;
                    end
                    else begin
                        udp_valid_r <= 1'h0;
                        rd_en_r <= 1'h0;
                        udp_tx_last_r <= 1'h0;
                    end
                end
                S_CRC32:
                begin
                    bytes_counter_r <= bytes_counter_r + 1'd1;
                    udp_data_r <= 'h0;
                    if(bytes_counter_r[1 : 0] == 2'd0) begin
                        udp_valid_r <= 1'h1;
                        udp_tx_last_r <= 1'h0;
                    end
                    else begin
                        udp_valid_r <= 1'h0;
                        udp_tx_last_r <= 1'h0;
                    end
                end
                S_IPG:
                begin
                    bytes_counter_r <= bytes_counter_r + 1'd1;
                    udp_data_r <= ipg_r[bytes_counter_r[15 : 2]];
                    if(bytes_counter_r[1 : 0] == 2'd0) begin
                        udp_valid_r <= 1'h1;
                        udp_tx_last_r <= 1'h0;
                    end
                    else begin
                        udp_valid_r <= 1'h0;
                        udp_tx_last_r <= 1'h0;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        if(rst_i) begin
            s_axis_tready_r = 1'h0;
        end
        else if(!fifo_full_r) begin
            s_axis_tready_r = 1'h1;
        end
        else begin
            s_axis_tready_r = 1'h0;
        end
    end

    always @(posedge aclk) begin
        if(s_axis_tvalid && s_axis_tready) begin
            wdata_r <= s_axis_tdata;
            wr_en_r <= 1'h1;
            rd_en_r <= 1'h0;
        end
        else begin
            wdata_r <= 'h0;
            wr_en_r <= 1'h0;
            rd_en_r <= 1'h0;
        end
    end

    fifo #(
        .fifo_depth(fifo_depth),
        .data_width(8)
    ) u_fifo (
        .clk_i(aclk),
        .rst_i(rst_i),

        .wr_en_i(wr_en_r),
        .rd_en_i(rd_en_r),

        .wdata_i(wdata_r),
        .rdata_o(rdata_r),

        .fifo_count_o(fifo_count_r),

        .fifo_empty_o(fifo_empty_r),
        .fifo_almost_empty_o(fifo_almost_empty_r),

        .fifo_full_o(fifo_full_r),
        .fifo_almost_full_o(fifo_almost_full_r)
    );

    crc32 u_crc32(
        .clk_i(aclk),
        .rst_i(rst_i),
        .data_in_i(rdata_r),
        .crc_en_i(rd_en_r),
        
        .crc_o(crc_r)
    );

    assign s_axis_tready = s_axis_tready_r;
    assign udp_data_o = udp_data_r;
    assign udp_valid_o = udp_valid_r;
    assign udp_tx_last_o = udp_tx_last_r;
endmodule
