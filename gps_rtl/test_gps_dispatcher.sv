module test_gps_dispatcher (
    input logic         aclk,
    input logic         aresetn,
    input logic [4:0]   prn_id,
    input logic         acquisition_valid,
    input logic [15:0]  correlation_result,
    input logic [15:0]  doppler_freq,
    input logic [15:0]  code_delay
);

logic [11:0] dispatcher_o_raddr;
logic signed [15:0] dispatcher_i_ca [0:31];

gps_dispatcher dut1(
    .aclk(aclk),
    .aresetn(aresetn),
    .o_raddr(dispatcher_o_raddr),
    .i_ca(dispatcher_i_ca),
    .acquisition_valid(acquisition_valid),
    .correlation_result(correlation_result),
    .doppler_freq(doppler_freq),
    .prn_id(prn_id),
    .code_delay(code_delay)
);

precomputed_ca dut2(
    .clk(aclk),
    .i_rdaddr(dispatcher_o_raddr),
    .o_data(dispatcher_i_ca)
);

endmodule