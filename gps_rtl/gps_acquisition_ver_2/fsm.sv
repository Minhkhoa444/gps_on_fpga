import fft_pkg::*;
module fsm(
    input   logic   clk,
    input   logic   rst_n,

    input   logic   [11:0]  counter,
    input   logic   [4:0]   prn,

    output  fsm_state_t current_state
);

    fsm_state_t nxt_state;

    always_comb begin
        if(current_state == FFT_RCV) begin
            if(&counter[11:0]) begin
                nxt_state = FFT_LOCAL;
            end
            else begin
                nxt_state = current_state;
            end
        end
        else begin
            if(&counter[11:0] && &prn[4:0]) begin
                nxt_state = FFT_RCV;
            end
            else begin
                nxt_state = current_state;
            end
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            current_state <= FFT_RCV;
        end
        else begin
            current_state <= nxt_state;
        end
    end

endmodule