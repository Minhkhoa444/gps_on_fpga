`default_nettype none

module jun_tracker #(
    parameter axil_addr_width = 10,
    parameter axil_data_width = 32
) (
    input wire [5:0]                    track_prn_id,
    input wire [axil_data_width-1:0]    track_doppler,
    input wire [axil_data_width-1:0]    track_code_delay,
    input wire                          lock_loss_input,
    output wire                         lock_loss,
    output wire [5:0]                   out_prn_id,
    output wire [axil_data_width-1:0]   out_doppler,
    output wire [axil_data_width-1:0]   out_code_delay,
    output wire [axil_data_width-1:0]   dll_out
);
    assign lock_loss      = lock_loss_input;
    assign out_prn_id     = track_prn_id;
    assign out_doppler    = track_doppler;
    assign out_code_delay = track_code_delay;
endmodule
