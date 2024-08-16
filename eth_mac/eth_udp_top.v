//  This module will accept AXI Stream data in
//  Then push all of those data into a FIFO
//  When FIFO is empty, pre pad it with protocol header
//  The internal FIFO will then connect to the generic eth_tx module
//
//  The output is RMII interface

module eth_udp_top #(

) (

);

    /*
        Header checksum
        The 16-bit IPv4 header checksum field is used for error checking of the header. When a packet arrives at a router or its destination, the network device calculates the checksum of the header including the checksum field. A value of 0xFFFF is expected. If a different result is obtained, the device discards the packet. Errors in the data portion of the packet are handled separately by the encapsulated protocol. Both UDP and TCP have separate checksums that apply to their data.
        When a packet arrives at a router, the router decreases the TTL field in the header. Consequently, the router must calculate a new header checksum.
    The checksum field is the 16-bit ones' complement of the ones' complement sum of all 16-bit words in the header. For purposes of computing the checksum, the value of the checksum field is zero.
        
        AXI Stream Master -> | AXI Stream Slave -> FIFO -> fifo_count_o == 1400 -> eth_tx_rdy -> eth_tx
        AXI Stream Slave <- | AXI Stream Master <- tvalid == 1 <- fifo_count_o == 1400 <- eth_rx
    
        Example ethernet frame:

        
        192.168.0.44:1024 -> 192.168.0.4:1024 UDP 
        00 10 A4 7B EA 80 00 12 34 56 78 90 08 00 45 00 00 2E B3 FE 00
        00 80 11 05 40 C0 A8 00 2C C0 A8 00 04 04 00 04 00 00 1A 2D E8 
        00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 B3 31 88 
        1B

        Ethernet mac header:
            + Destination mac address: 00 10 A4 7B EA 80
            + Source mac address: 00 12 34 56 78 90
            + Ethernet type: 0800
        
        Data: 
            + IP header: 45 00 00 2E B3 FE 00 00 80 11 05 40 C0 A8 00 2C C0 A8 00 04
                + Version: 4 (IPv4)
                + Internet header length: 5 (5 * 4 bytes = 20 bytes => max size = 15 * 4 bytes = 60 bytes)
                + DSCP: 0
                + ECN: 0
                + Total length: 002E or 46 bytes (size include header and data: 20 bytes IPv4 header + 8 bytes UDP header + 18 bytes UDP payload)
                + Identification: B3FE
                + Flags: 00 (Reserved)
                + Fragment offset: 0000
                + Time to live: 80 (128 decimal)
                + Protocol: 11 (UDP protocol)
                + Header checksum: 0540
                + Source address: C0_A8_00_2C (192.168.0.44)
                + Destination address: C0_A8_00_04 (192.168.0.4)

            + UDP payload: 04 00 04 00 00 1A 2D E8 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11
                + Source port: 0400 (1024)
                + Destination port: 0400 (1024)
                + UDP length: 001A (26 bytes = 8 bytes of header + 18 bytes of data)
                + Checksum: 2DE8
                + Data: 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11
            + FCS: B331_881B (CRC32 of begining (preamble not counted to end)
    */
endmodule
