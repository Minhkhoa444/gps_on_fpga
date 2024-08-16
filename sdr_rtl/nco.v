module nco #(
    parameter phase_width = 8,
    parameter data_width = 16
) (
    input                                   clk_i,
    input                                   rst_i,
    input                                   load_i,
    input[phase_width - 1 : 0]              phase_i,
    output[data_width - 1 : 0]              sine_o,
    output[data_width - 1 : 0]              cosine_o
);

    reg[phase_width - 1 : 0] step_r;
    reg[phase_width - 1 : 0] phase_r;

    always @(posedge clk_i) begin
        if(load_i) begin
            step_r <= phase_i;
        end
    end
    
    always @(posedge clk_i) begin
        phase_r <= phase_r + step_r;
    end

    sine_generator #(
        .phase_width(phase_width),
        .data_width(data_width)
    ) u_sine (
        .clk_i(clk_i), 
        .rst_i(rst_i), 
        .phase_i(phase_r), 
        .val_o(sine_o)
    );

    cosine_generator #(
        .phase_width(phase_width),
        .data_width(data_width)
    ) u_cosine (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .phase_i(phase_r),
        .val_o(cosine_o)
    );

endmodule
