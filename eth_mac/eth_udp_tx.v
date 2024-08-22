module eth_udp_tx #(
    parameter fifo_depth = 256,
    parameter src_mac = 48'h0,
    parameter src_ip = 32'h0,
    parameter src_port = 16'd1024,
    parameter dest_mac = 48'h0,
    parameter dest_ip = 32'h0,
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
    
    localparam[2 : 0] S_IDLE = 'd0,
                    S_HEADER = 'd1,
                    S_PAYLOAD = 'h2,
                    S_CRC32 = 'h3,
                    S_IPG = 'h4;

    localparam[15 : 0] UDP_SIZE = fifo_depth + 8;   //  8 bytes UDP Header + Payload Size
    localparam[15 : 0] IP_SIZE = UDP_SIZE + 20;     //  20 bytes IPv4 Header + Payload Size (UDP total size)

    reg[31 : 0] ip_checksum_r;
    reg[31 : 0] udp_checksum_r;
    
    reg[2 : 0] state_r;
    reg[2 : 0] next_state_r;
    reg[7 : 0] udp_data_r;
    reg udp_valid_r;
    reg udp_tx_last_r;

    reg[7 : 0] frame_header_r[50];
    reg[7 : 0] ipg_r[12];

    reg[10 : 0] bytes_counter_r;

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

    always @(posedge aclk) begin
        if(rst_i) begin
            bytes_counter_r <= 'h00;
        end
        else begin
            if(
        end
    end

    always @(*) begin
        case(state_r)
            S_IDLE:
            begin
                if() begin
                    next_state_r = S_HEADER;
                end
                else begin

                end
            end
            S_HEADER:
            begin
                if(byte_counter_r == 'h01) begin

                end
            end
            S_PAYLOAD:
            begin
                if(byte_counter_r == 'h01) begin

                end
            end
            S_CRC32:
            begin

            end
            S_IPG:
            begin
                if(bytes_counter_r == 'h01) begin

                end
                else begin
                    
                end
            end
        endcase
    end

    fifo u_fifo(

    );

    crc32 u_crc32(
        .crc_in(),
        .data_in_i(),
        
        .crc_out()
    );

    assign udp_data_o = udp_data_r;
    assign udp_valid_o udp_valid_r;
    assign udp_tx_last_o = udp_tx_last_r;
endmodule
