module cosine_generator#(
    parameter phase_width = 8,
    parameter data_width = 16
) (
    input                                   clk_i,
    input                                   rst_i,

    input[phase_width - 1 : 0]              phase_i,

    output[data_width - 1 : 0]              val_o
);
    
    reg[data_width - 1 : 0] cosine_mem[0 : 2**(phase_width) - 1];
    reg[data_width - 1 : 0] val_r;

    initial begin
        $readmemh("cosinelut.mem", cosine_mem);
    end

    always @(posedge clk_i) begin
        if(rst_i) begin
            val_r <= 0;
        end
        else begin
            val_r <= cosine_mem[phase_i];
        end
    end

    assign val_o = val_r;
endmodule
