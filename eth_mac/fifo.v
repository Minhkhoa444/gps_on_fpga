module fifo #(
    parameter fifo_depth = 1024,
    parameter data_width = 8
) (
    input                                   clk_i,
    input                                   rst_i,

    input                                   wr_en_i,
    input                                   rd_en_i,

    input[data_width - 1 : 0]               wdata_i,
    output[data_width - 1 : 0]              rdata_o,

    output[$clog2(fifo_depth) -1 : 0]       fifo_count_o,
    
    output                                  fifo_empty_o,
    output                                  fifo_almost_empty_o,

    output                                  fifo_full_o,
    output                                  fifo_almost_full_o
);

    reg[$clog2(fifo_depth) - 1 : 0] wr_ptr_r;
    reg[$clog2(fifo_depth) - 1 : 0] rd_ptr_r;
    reg[$clog2(fifo_depth) - 1 : 0] count_r;

    reg[data_width - 1 : 0] fifo_mem[0 : fifo_depth - 1];

    always @(posedge clk_i) begin
        if(rst_i) begin
            wr_ptr_r <= 'h0;
        end
        else begin
            if(wr_en_i && !fifo_full_o) begin
                fifo_mem[wr_ptr_r] <= wdata_i;
                wr_ptr_r <= wr_ptr_r + 'h1;
            end
            else begin
                fifo_mem[wr_ptr_r] <= fifo_mem[wr_ptr_r];
                wr_ptr_r <= wr_ptr_r;
            end
        end
    end

    always @(posedge clk_i) begin
        if(rst_i) begin
            rd_ptr_r <= 'h0;
        end
        else begin
            if(rd_en_i && !fifo_empty_o) begin
                rdata_o <= fifo_mem[rd_ptr_r];
                rd_ptr_r <= rd_ptr_r + 'h1;
            end
            else begin
                rdata_o <= 'h0;
                rd_ptr_r <= rd_ptr_r;
            end
        end
    end

    always @(posedge clk_i) begin
        if(rst_i) begin
            count_r <= 'h0;
        end
        else begin
            case({wr_en_i, rd_en_i})
                2'b00:
                begin
                    count_r <= count_r;
                end
                2'b01:
                begin
                    count_r <= count_r - 1'h1;
                end
                2'b10:
                begin
                    count_r <= count_r + 1'h1;
                end
                2'b11:
                begin
                    count_r <= count_r;
                end
            endcase
        end
    end

    assign fifo_count_o = count_r;
    assign fifo_empty_o = (count_r == 'h0);
    assign fifo_almost_empty_o = (count_r == 'h1);
    assign fifo_full_o = (count_r == fifo_depth);
    assign fifo_almost_full_o = (count_r == fifo_depth - 'h1);
endmodule
