module sine_generator #(
    parameter phase_width = 12,
    parameter data_width = 16
) (
    input                                   clk_i,
    input                                   rst_i,

    input[phase_width + 1 : 0]              phase_i,

    output[data_width - 1 : 0]              val_o
);
    
    reg[data_width - 1 : 0] sine_mem[0 : 2**(phase_width) - 1];
    reg[data_width - 1 : 0] val_r;
    reg[phase_width - 1 : 0] index_r;

    initial begin
        $readmemb("../mem/sinelut.mem", sine_mem);
    end

    always @(*) begin
        if(phase_i[phase_width] == 1'b0) begin
            index_r = phase_i[phase_width - 1 : 0];
        end
        else begin
            index_r = ~phase_i[phase_width - 1 : 0];
        end
    end

    always @(posedge clk_i) begin
        if(rst_i) begin
            val_r <= sine_mem[0];
        end
        else begin
            if(phase_i[phase_width + 1] == 1'b0) begin 
                val_r <= sine_mem[index_r];
            end
            else begin
                val_r <= -sine_mem[index_r];
            end
        end
    end

    assign val_o = val_r;
endmodule
