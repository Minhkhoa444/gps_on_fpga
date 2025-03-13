module sin_cos_lut #(
    parameter PHASE_WIDTH = 32,
    parameter DAT_WIDTH = 16,
    parameter LUT_SIZE = 256
) (
    input logic                             clk_i,
    input logic                             rst_i,
    input logic[PHASE_WIDTH - 1 : 0]        i_phase,
    output logic signed[DAT_WIDTH - 1 : 0]  o_sin,
    output logic signed[DAT_WIDTH - 1 : 0]  o_cos
);
    logic signed[DAT_WIDTH -1 : 0] sin_lut[0 : LUT_SIZE - 1];
    logic signed[DAT_WIDTH -1 : 0] cos_lut[0 : LUT_SIZE - 1];

    logic[$clog2(LUT_SIZE) - 1 : 0] lut_index;

    initial begin
        for(int i = 0; i < LUT_SIZE; i = i + 1) begin
            sin_lut[i] = $rtoi($sin(2.0 * 3.14159265 * i / LUT_SIZE) * 32767);
            cos_lut[i] = $rtoi($cos(2.0 * 3.14159265 * i / LUT_SIZE) * 32767);
        end
    end

    assign lut_index = i_phase[PHASE_WIDTH - 1 : PHASE_WIDTH - $clog2(LUT_SIZE)];

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            o_sin <= '0;
            o_cos <= '0;
        end
        else begin
            o_sin <= sin_lut[lut_index];
            o_cos <= cos_lut[lut_index];
        end
    end
endmodule
