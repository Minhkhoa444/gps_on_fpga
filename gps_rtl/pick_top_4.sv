typedef struct packed {
    logic   signed  [15:0]  corr_result;
    logic   signed  [14:0]  doppler_shift;
    logic   [4:0]           prn_id;
    logic   [11:0]          code_phase_delay;
} pick_top_4_data_t;
module pick_top_4 #(
    parameter D_WIDTH = 5
)(
    input   logic   clk,
    input   logic   rst_n,

    input   logic   i_vld,
    input   logic   signed  [15:0]  i_corr_result,
    input   logic   signed  [14:0]  i_doppler_shift,
    input   logic   [4:0]           i_prn_id,
    input   logic   [11:0]          i_code_phase_delay,

    output  logic   o_vld,
    output  logic   signed  [15:0]  o_corr_result_0,
    output  logic   signed  [14:0]  o_doppler_shift_0,
    output  logic   [4:0]           o_prn_id_0,
    output  logic   [11:0]          o_code_phase_delay_0,

    output  logic   signed  [15:0]  o_corr_result_1,
    output  logic   signed  [14:0]  o_doppler_shift_1,
    output  logic   [4:0]           o_prn_id_1,
    output  logic   [11:0]          o_code_phase_delay_1,

    output  logic   signed  [15:0]  o_corr_result_2,
    output  logic   signed  [14:0]  o_doppler_shift_2,
    output  logic   [4:0]           o_prn_id_2,
    output  logic   [11:0]          o_code_phase_delay_2,

    output  logic   signed  [15:0]  o_corr_result_3,
    output  logic   signed  [14:0]  o_doppler_shift_3,
    output  logic   [4:0]           o_prn_id_3,
    output  logic   [11:0]          o_code_phase_delay_3
);

    pick_top_4_data_t   top_4       [0:3];
    logic   [3:0]   update;
    logic   [3:0]   bigger;
    logic   vld_tmp;

    genvar i;
    generate
        for(i=0; i<4; i++) begin
            assign bigger[i] = (i_vld) ? (i_corr_result > top_4[i].corr_result) : 'b0;
        end
    endgenerate

    assign  update[0] = bigger[0];
    assign  update[1] = bigger[0];
    assign  update[2] = |bigger[1:0];
    assign  update[3] = |bigger[2:0];

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            top_4[0].corr_result <= 'b0;
        end
        else begin
            if(update[0]) begin
                top_4[0] <= '{i_corr_result,i_doppler_shift,i_prn_id,i_code_phase_delay};
            end
        end
    end

    generate
        for(i=1; i<4; i++) begin
            always_ff @(posedge clk, negedge rst_n) begin
                if(~rst_n) begin
                    top_4[i].corr_result <= 'b0;
                end
                else begin
                    if(update[i]) begin
                        top_4[i] <= top_4[i-1];
                    end
                    else begin
                        if(bigger[i]) begin
                            top_4[i] <= '{i_corr_result,i_doppler_shift,i_prn_id,i_code_phase_delay};
                        end
                    end
                end
            end
        end
    endgenerate

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            vld_tmp <= 'b0;
            o_vld <= 'b0;
        end
        else begin
            vld_tmp <= (&i_prn_id);
            o_vld <= vld_tmp;
        end
    end

    always_ff @(posedge clk) begin
        o_corr_result_0         <= top_4[0].corr_result;
        o_doppler_shift_0       <= top_4[0].doppler_shift;
        o_prn_id_0              <= top_4[0].prn_id;
        o_code_phase_delay_0    <= top_4[0].code_phase_delay;

        o_corr_result_1         <= top_4[1].corr_result;
        o_doppler_shift_1       <= top_4[1].doppler_shift;
        o_prn_id_1              <= top_4[1].prn_id;
        o_code_phase_delay_1    <= top_4[1].code_phase_delay;

        o_corr_result_2         <= top_4[2].corr_result;
        o_doppler_shift_2       <= top_4[2].doppler_shift;
        o_prn_id_2              <= top_4[2].prn_id;
        o_code_phase_delay_2    <= top_4[2].code_phase_delay;

        o_corr_result_3         <= top_4[3].corr_result;
        o_doppler_shift_3       <= top_4[3].doppler_shift;
        o_prn_id_3              <= top_4[3].prn_id;
        o_code_phase_delay_3    <= top_4[3].code_phase_delay;
    end

endmodule