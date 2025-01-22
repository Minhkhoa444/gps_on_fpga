`timescale 1ns/1ps

module tracking_test_tb;
    localparam axil_addr_width = 10;
    localparam axil_data_width = 32;
    localparam num_trackers = 8;

    bit aclk;
    bit aresetn;

    bit [axil_addr_width - 1 : 0] s_axil_awaddr, s_axil_araddr;
    bit [axil_data_width - 1 : 0] s_axil_wdata, s_axil_rdata;
    bit s_axil_awvalid, s_axil_arvalid, s_axil_wvalid, s_axil_rready;
    bit s_axil_awready, s_axil_arready, s_axil_wready, s_axil_rvalid;
    bit [1:0] s_axil_bresp, s_axil_rresp;
    bit s_axil_bvalid, s_axil_bready;
    bit [axil_data_width / 8 - 1 : 0] s_axil_wstrb;

    // acquisition input
    bit [5:0] prn_id;
    bit [axil_data_width - 1 : 0] correlation_result;
    bit [axil_data_width - 1 : 0] code_delay;
    bit [axil_data_width - 1 : 0] doppler_freq;

    // tracker inputs
    bit [num_trackers - 1 : 0]      lock_loss;

    // tracker outputs
    bit [5:0]                       out_prn_id      [0:num_trackers-1];
    bit [axil_data_width - 1 : 0]   out_doppler     [0:num_trackers-1];
    bit [axil_data_width - 1 : 0]   out_code_delay  [0:num_trackers-1];

    mailbox waddr_mbox, wdata_mbox, wresponse_mbox, raddr_mbox, rdata_mbox;

    bit [5 : 0]                     store_top_correlation       [0:num_trackers-1];
    bit [axil_data_width - 1 : 0]   store_correlation_result    [0:31];
    bit [axil_data_width - 1 : 0]   store_doppler_shift         [0:31];
    bit [axil_data_width - 1 : 0]   store_code_delay            [0:31];

    tracking_test #(
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

        // acquisition inputs
        .prn_id(prn_id),
        .correlation_result(correlation_result),
        .code_delay(code_delay),
        .doppler_freq(doppler_freq),

        // tracker inputs
        .lock_loss(lock_loss),

        // tracker outputs
        .out_prn_id(out_prn_id),
        .out_doppler(out_doppler),
        .out_code_delay(out_code_delay)
    );

    typedef struct packed {
        bit [axil_addr_width - 1 : 0] addr;
        bit [axil_data_width - 1 : 0] data;
        bit [axil_data_width / 8 - 1 : 0] wstrb;
    } item;

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
        end
    endtask

    task automatic write(input bit [axil_addr_width - 1 : 0] addr, input bit [axil_data_width - 1 : 0] data, input bit [axil_data_width / 8 - 1 : 0] wstrb);
        begin
            item item;
            item.addr = addr;
            item.data = data;
            item.wstrb = wstrb;
            waddr_mbox.put(addr);
            wdata_mbox.put(item);
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

    task print_prn_id();
        for (int i = 0; i < num_trackers; i++) begin
            $display("PRN ID tracker %0d: %b", i, out_prn_id[i]);
        end
        $display("==================================================");
    endtask

    task print_doppler();
        for (int i = 0; i < num_trackers; i++) begin
            $display("Doppler tracker %0d: %b", i, out_doppler[i]);
        end
        $display("==================================================");
    endtask

    task print_code_delay();
        for (int i = 0; i < num_trackers; i++) begin
            $display("Code delay tracker %0d: %b", i, out_code_delay[i]);
        end
        $display("==================================================");
    endtask

    task write_full_doppler_tracker();
        bit [axil_addr_width - 1 : 0] addr;
        bit [axil_data_width - 1 : 0] data;
        data = 'hEEEEFFFF;
        for (addr = 'h210; addr <= 'h22C; addr +=4) begin
            write(addr,data,'hF); #40;
        end 
    endtask

    task write_full_prn_id();
        bit [axil_addr_width - 1 : 0] addr;
        bit [axil_data_width - 1 : 0] data;
        data = 'hEEEEFFFF;
        for (addr = 'h8; addr <= 'hC; addr +=4) begin
            write(addr,data,'hF); #40;
        end 
    endtask

    task write_full_code_delay();
        bit [axil_addr_width - 1 : 0] addr;
        bit [axil_data_width - 1 : 0] data;
        data = 'hEEEEFFFF;
        for (addr = 'h230; addr <= 'h24C; addr +=4) begin
            write(addr,data,'hF); #40;
        end 
    endtask

    // write full to check operation
    task write_check_trackers();
        write_full_prn_id();
        write_full_doppler_tracker();
        write_full_code_delay();
    endtask

    // write prn_ids to all trackers
    task write_prn_id();
        bit [axil_data_width - 1 : 0] data1;
        bit [axil_data_width - 1 : 0] data2;
        data1 = 'h0; data2 = 'h0;
        if (num_trackers <= 5) begin
            for (int i = 0; i < num_trackers; i++) begin
                data1[i*6+:6] = store_top_correlation[i]+1;
            end
            write('h8,data1,'hF); #40;
        end else begin
            for (int i = 0; i < 5; i++) begin
                data1[i*6+:6] = store_top_correlation[i]+1;
            end
            for (int i = 0; i < num_trackers - 5; i++) begin
                data2[i*6+:6] = store_top_correlation[i+5]+1;
            end
            write('h8,data1,'hF); #40;
            write('hC,data2,'hF); #40;
        end
    endtask

    // write doppler_shift to all trackers
    task write_doppler_shift();
        bit [axil_addr_width - 1 : 0] addr;
        bit [axil_data_width - 1 : 0] data;
        addr = 'h210;
        for (int i = 0; i < num_trackers; i++) begin
            data = store_doppler_shift[store_top_correlation[i]];
            write(addr,data,'hF); #40;
            addr += 4;
        end
    endtask
    // write code_delay to all trackers
    task write_code_delay();
        bit [axil_addr_width - 1 : 0] addr;
        bit [axil_data_width - 1 : 0] data;
        addr = 'h230;
        for (int i = 0; i < num_trackers; i++) begin
            data = store_code_delay[store_top_correlation[i]];
            write(addr,data,'hF); #40;
            addr += 4;
        end
    endtask

    // remove used IDs
    task delete_used_ids();
        for (int i = 0; i < num_trackers; i++) begin
            store_code_delay[store_top_correlation[i]] = 0;
            store_doppler_shift[store_top_correlation[i]] = 0;
            store_top_correlation[i] = 0;
        end
    endtask
    // write specific data to specific tracker
    task write_to_tracker(bit [5:0] index, bit [3:0] tracker_num);
        
    endtask

    task print_trackers();
        print_prn_id();
        print_doppler();
        print_code_delay();
    endtask

    //write axi check trackers
    // initial begin
    //     bit [axil_addr_width - 1 : 0] addr;
    //     bit [axil_data_width - 1 : 0] data;
    //     bit [axil_data_width / 8 - 1 : 0] wstrb;
    //     @(posedge aresetn);
    //     write_check_trackers();
    //     print_trackers();
    //     #200;
    //     $finish;
    // end

    task send_acquisition(input bit [5:0] prn_id_input, input bit [axil_data_width - 1 : 0] correlation_result_input, input bit [axil_data_width - 1 : 0] code_delay_input, input bit [axil_data_width - 1 : 0] doppler_freq_input);
        prn_id = prn_id_input;
        correlation_result = correlation_result_input;
        code_delay = code_delay_input;
        doppler_freq = doppler_freq_input;
    endtask

    task read_acquisition(input bit [5:0] prn_id_input);
        bit [axil_data_width - 1 : 0] data;
        $display("PRN ID: %d", prn_id_input);
        read('h90+(prn_id_input-1)*4,data); #40; // correlation result
        $display("Address: 0x%h, Read Data (Correlation): 0x%h", 'h90+(prn_id_input-1)*4, data);
        store_correlation_result[prn_id_input-1] = data;
        read('h110+(prn_id_input-1)*4,data); #40; // doppler_shift 
        $display("Address: 0x%h, Read Data (Doppler):     0x%h", 'h110+(prn_id_input-1)*4, data);
        store_doppler_shift[prn_id_input-1] = data;
        read('h190+(prn_id_input-1)*4,data); #40; // code_delay
        $display("Address: 0x%h, Read Data (Code Delay):  0x%h", 'h190+(prn_id_input-1)*4, data);
        store_code_delay[prn_id_input-1] = data;
    endtask

    task find_num_tracker_max_correlation();
        bit [5:0] index;
        bit [axil_data_width - 1 : 0] max_value;
        for (int i = 0; i < num_trackers; i++) begin
            index = 0;
            max_value = 0;
            for (int j = 0; j < 32; j++) begin
                if (store_correlation_result[j] > max_value) begin
                    index = j;
                    max_value = store_correlation_result[j];
                end
            end
            store_correlation_result[index] = 0;
            store_top_correlation[i] = index;
        end
    endtask

    task send_top_num_trackers_to_trackers();
        find_num_tracker_max_correlation();
        write_prn_id();
        write_doppler_shift();
        write_code_delay();
    endtask

    initial begin
        @(posedge aresetn);
        for (int i = 1 ;i <= 32; i++) begin
            send_acquisition(i,i,i,i);
            read_acquisition(i);
        end
        send_top_num_trackers_to_trackers();
        // $display("Contents of store_top_correlation:");
        // for (int k = 0; k < num_trackers; k++) begin
        //     $display("Index %0d: %0d", k, store_top_correlation[k]);
        // end
        #200;
        print_trackers();
        $finish;
    end

endmodule