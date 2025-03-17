`timescale 1ns/1ps

module gps_dispatcher_tb;
    localparam axil_addr_width = 10;
    localparam axil_data_width = 32;
    localparam num_trackers = 8;

    // Clock and Reset
    bit aclk;
    bit aresetn;

    // AXI Lite signals
    bit [axil_addr_width - 1 : 0] s_axil_awaddr, s_axil_araddr;
    bit [axil_data_width - 1 : 0] s_axil_wdata, s_axil_rdata;
    bit s_axil_awvalid, s_axil_arvalid, s_axil_wvalid, s_axil_rready;
    bit s_axil_awready, s_axil_arready, s_axil_wready, s_axil_rvalid;
    bit [1:0] s_axil_bresp, s_axil_rresp;
    bit s_axil_bvalid, s_axil_bready;
    bit [axil_data_width / 8 - 1 : 0] s_axil_wstrb;

    mailbox waddr_mbox, wdata_mbox, wresponse_mbox, raddr_mbox, rdata_mbox;

    gps_dispatcher #(
        .axil_addr_width(axil_addr_width),
        .axil_data_width(axil_data_width),
        .num_trackers(num_trackers)
    ) dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axil_awaddr(s_axil_awaddr),
        .s_axil_awvalid(s_axil_awvalid),
        .s_axil_awready(s_axil_awready),
        .s_axil_wdata(s_axil_wdata),
        .s_axil_wstrb(s_axil_wstrb),
        .s_axil_wvalid(s_axil_wvalid),
        .s_axil_wready(s_axil_wready),
        .s_axil_bresp(s_axil_bresp),
        .s_axil_bvalid(s_axil_bvalid),
        .s_axil_bready(s_axil_bready),
        .s_axil_araddr(s_axil_araddr),
        .s_axil_arvalid(s_axil_arvalid),
        .s_axil_arready(s_axil_arready),
        .s_axil_rdata(s_axil_rdata),
        .s_axil_rvalid(s_axil_rvalid),
        .s_axil_rready(s_axil_rready),
        .s_axil_rresp(s_axil_rresp),
        .acquisition_valid(),
        .prn_id(),
        .correlation_result(),
        .code_delay(),
        .doppler_freq(),
        .tracking_valid(),
        .dll_out(),
        .start_acquisition(),
        .track_prn_id(),
        .track_code_delay(),
        .track_doppler()
    );

    typedef struct packed {
        bit [axil_addr_width - 1 : 0] addr;
        bit [axil_data_width - 1 : 0] data;
        bit [axil_data_width / 8 - 1 : 0] wstrb;
    } item;

    item write_queue[$];
    item read_queue[$];

    bit [axil_data_width - 1 : 0] mem[0 : 147];

    initial begin
        aclk = 0;
        forever begin
            aclk = #10 !aclk;
        end
    end

    initial begin
        aresetn = 0;
        #20
        aresetn = 1;
    end

    task aw_channel();
        forever begin
            bit [axil_addr_width - 1 : 0] addr;
            waddr_mbox.get(addr);
            s_axil_awaddr = addr;
            s_axil_awvalid = 1;
            wait (s_axil_awready);
            @(posedge aclk);
            s_axil_awvalid = 0;
        end
    endtask

    task w_channel();
        forever begin
            item item;
            wdata_mbox.get(item);
            s_axil_wdata = item.data;
            s_axil_wstrb = item.wstrb;
            s_axil_wvalid = 1;
            wait (s_axil_wready);
            @(posedge aclk);
            s_axil_wvalid = 0;
            wresponse_mbox.put(1);
        end
    endtask

    task b_channel();
        forever begin
            bit a;
            wresponse_mbox.get(a);
            s_axil_bready = 1;
            // $display("$0t, 2", $time);
            wait (s_axil_bvalid);
            @(posedge aclk);
            s_axil_bready = 0;
        end
    endtask

    task ar_channel();
        forever begin
            bit [axil_addr_width - 1 : 0] addr;
            raddr_mbox.get(addr);
            s_axil_araddr = addr;
            s_axil_arvalid = 1;
            wait (s_axil_arready);
            @(posedge aclk);
            s_axil_arvalid = 0;
        end
    endtask

    task r_channel();
        forever begin
            bit [axil_data_width - 1 : 0] data;
            s_axil_rready = 1;
            wait (s_axil_rvalid);
            @(posedge aclk);
            data = s_axil_rdata;
            s_axil_rready = 0;
            rdata_mbox.put(data);
            @(posedge aclk);
        end
    endtask

    task automatic read(input bit [axil_addr_width - 1 : 0] addr, ref bit [axil_data_width - 1 : 0] data);
        begin
            item item;
            raddr_mbox.put(addr);
            rdata_mbox.get(data);
            // $display("Read address 0x%h, read data 0x%h", addr, data);
            item.addr = addr;
            item.data = data;
            read_queue.push_back(item);
            #40;
        end
    endtask

    task automatic write(input bit [axil_addr_width - 1 : 0] addr, input bit [axil_data_width - 1 : 0] data, input bit [axil_data_width / 8 - 1 : 0] wstrb, ref bit [axil_data_width - 1 : 0] mem[0 : 147]);
        begin
            item item;
            item.addr = addr;
            item.data = data;
            item.wstrb = wstrb;
            waddr_mbox.put(addr);
            wdata_mbox.put(item);
            // $display("Write address 0x%h, write data 0x%h", addr, data);
            item.data = 0;
            case (addr)
                'h0:
                begin
                    if (wstrb[0] == 1'b1) begin
                        item.data[0] = data[0];
                        mem[addr/4][0] = data[0];
                    end
                end
                'h8:
                begin
                    if (wstrb[0] == 1'b1) begin
                        item.data[7:0] = data[7:0];
                        mem[addr/4][7:0] = data[7:0];
                    end
                    if (wstrb[1] == 1'b1) begin
                        item.data[15:8] = data[15:8];
                        mem[addr/4][15:8] = data[15:8];
                    end
                    if (wstrb[2] == 1'b1) begin
                        item.data[23:16] = data[23:16];
                        mem[addr/4][23:16] = data[23:16];
                    end
                    if (wstrb[3] == 1'b1) begin
                        item.data[24] = data[24];
                        mem[addr/4][24] = data[24];
                    end
                end
                'hc:
                begin
                    if (wstrb[0] == 1'b1) begin
                        item.data[7:0] = data[7:0];
                        mem[addr/4][7:0] = data[7:0];
                    end
                    if (wstrb[1] == 1'b1) begin
                        item.data[14:8] = data[14:8];
                        mem[addr/4][14:8] = data[14:8];
                    end
                    // if (wstrb[2] == 1'b1) begin
                    //     item.data[17:16] = data[17:16];
                    //     mem[addr/4][17:16] = data[17:16];
                    // end
                end
                'h210, 'h214, 'h218, 'h21C, 'h220, 'h224, 'h228, 'h22C,
                'h230, 'h234, 'h238, 'h23C, 'h240, 'h244, 'h248, 'h24C:
                begin
                    if (wstrb[0] == 1'b1) begin
                        item.data[7:0] = data[7:0];
                        mem[addr/4][7:0] = data[7:0];
                    end
                    if (wstrb[1] == 1'b1) begin
                        item.data[15:8] = data[15:8];
                        mem[addr/4][15:8] = data[15:8];
                    end
                    // if (wstrb[2] == 1'b1) begin
                    //     item.data[23:16] = data[23:16];
                    //     mem[addr/4][23:16] = data[23:16];
                    // end
                    // if (wstrb[3] == 1'b1) begin
                    //     item.data[31:24] = data[31:24];
                    //     mem[addr/4][31:24] = data[31:24];
                    // end
                end
            endcase
            write_queue.push_back(item);
            #40;
        end
    endtask

    initial begin
        waddr_mbox = new();
        wdata_mbox = new();
        wresponse_mbox = new();
        raddr_mbox = new();
        rdata_mbox = new();
        fork
            aw_channel();
            w_channel();
            b_channel();
            ar_channel();
            r_channel();
        join_none
    end

    initial begin
        for (int i = 0; i < 148; i++) begin
            mem[i] = 0;
        end
    end


    initial begin
        bit [axil_addr_width - 1:0] addr;
        bit [axil_data_width - 1:0] data;
        bit [axil_data_width/8 - 1:0] wstrb;
        bit [axil_data_width - 1:0] data_out;
        bit fail = 0;
        @(posedge aresetn);
        @(posedge aclk);
        // Write to specific addresses with the value 0x12345678
        repeat(1000) begin
            wstrb = $urandom;
            addr = ($urandom % (32'h250 / 4)) * 4; // Ensure the address is aligned to 4 bytes
            data = $urandom;    
            if ($urandom %2 == 0) begin
                write(addr, data, wstrb, mem);
            end else begin
                read(addr, data_out);
                if (data_out == mem[addr/4]) begin
                    $display("Correct: Address = 0x%h, Expected: 0x%h, Got: 0x%h", addr, mem[addr / 4], data_out);
                end else begin
                    $display("Incorrect: Address = 0x%h, Expected: 0x%h, Got: 0x%h", addr, mem[addr / 4], data_out, $time);
                    fail = 1;
                end
            end
        end
        // wstrb = 4'b1111;
        // addr = 'h21c; // Ensure the address is aligned to 4 bytes
        // data = 'h86fcffcb;
        // write(addr, data, wstrb, mem); #40;
        // wstrb = 4'b1101;
        // addr = 'h210;
        // data = 'h11223344;
        // write(addr, data, wstrb, mem); #40;
        // wstrb = 4'b1111;
        // addr = 'h110;
        // data = 'h12345678;
        // write(addr, data, wstrb, mem); #40;
        // read('h21c, data_out); #40;
        // if (data_out == mem[addr/4]) begin
        //     $display("Correct: Address = 0x%h, Expected: 0x%h, Got: 0x%h", addr, mem[addr / 4], data_out);
        // end else begin
        //     $display("Incorrect: Address = 0x%h, Expected: 0x%h, Got: 0x%h", addr, mem[addr / 4], data_out);
        // end
        // #2000;
        // foreach (read_queue[i]) begin
        //     if (read_queue[i].data == mem[read_queue[i].addr / 4]) begin
        //         $display("Correct: Address = 0x%h, Expected: 0x%h, Got: 0x%8h", read_queue[i].addr, mem[read_queue[i].addr / 4], read_queue[i].data);
        //     end else begin
        //         $display("Incorrect: Address = 0x%h, Expected: 0x%h, Got: 0x%8h", read_queue[i].addr, mem[read_queue[i].addr / 4], read_queue[i].data);
        //         $display("Incorrect: Write Queue [%0d]: Address = 0x%h, Data = 0x%h, Read Queue[%0d]: Address = 0x%h, Data = 0x%h", i, write_queue[i].addr, write_queue[i].data, i, read_queue[i].addr, read_queue[i].data);
        //     end
        // end
        #200;
        if (!fail) begin
            $display("TEST PASSED");
        end else $display("TEST FAILED");
        $finish;
    end
endmodule