module sine_generator #(
    parameter phase_width = 10,
    parameter data_width = 16
) (
    input                                   clk_i,
    input                                   rst_i,

    input[phase_width - 1 : 0]              phase_i,

    output[data_width - 1 : 0]              val_o
);
    
    reg[data_width - 1 : 0] sine_mem[0 : 2**(phase_width) - 1];
    reg[data_width - 1 : 0] val_r;

    initial begin
        $readmemb("../mem/sinelut.mem", sine_mem);
    end

    always @(posedge clk_i) begin
        if(rst_i) begin
            val_r <= 'h0;
        end
        else begin
            val_r <= sine_mem[phase_i];
        end
    end

    assign val_o = val_r;
endmodule
