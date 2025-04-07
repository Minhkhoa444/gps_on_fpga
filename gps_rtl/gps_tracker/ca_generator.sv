module ca_generator(
    input logic                             clk_i,
    input logic[11 : 0]                     addr_i,
    output logic[0 : 31]                    code_o
);

    logic[0 : 31] ca_samples[0 : 4095];

    initial begin
        //$readmemb("../gps_rtl/gps_tracker/mem/ca_samples.mem", ca_samples);
        $readmemb("mem/ca_samples.mem", ca_samples);
    end

    always_ff @(posedge clk_i) begin
        code_o <= ca_samples[addr_i];
    end
endmodule
