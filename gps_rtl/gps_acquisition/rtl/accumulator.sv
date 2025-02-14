`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/10/2025 07:07:41 PM
// Design Name: 
// Module Name: accumulator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module accumulator(
    input   logic               clk,
    input   logic               rst_n,
    input   logic               i_start,
    // input   logic               i_vld,
    // input   logic               i_flag,
    input   logic   [5:0]       i_doppler_id,           // doppler id: 0 ---> 40 corresponding to f = +10kHz ---> 250Hz

    output  logic               o_vld,
    output  logic   [34:0]      o_angle
);

    localparam PI           =   'b00110010010000111111011010101000100;
    localparam HALF_PI      =   'b00011001001000011111101101010100010;
    localparam DOUBLE_PI    =   'b01100100100001111110110101010001001;

    logic   [31:0]  step    [0:40];

    step_assignment sta (.step);

    // logic   [18:0]  angle_pipe_1;
    // logic   [18:0]  angle_pipe_2;
    // logic   [18:0]  angle_pipe_1_tmp;
    // logic   [18:0]  angle_pipe_2_tmp;

    logic   [34:0]  angle_incr;
    logic   [34:0]  angle_modify;
    logic           vld_pipe_1;
    // logic           vld_pipe_2;
    logic           en;
    logic   [11:0]  cnt;
    logic   [11:0]  cnt_nxt;
    logic   [11:0]  cnt_tmp;

    assign  cnt_tmp = cnt + 1'b1;

    logic   en_cnt_1;
    logic   en_cnt_2;
    assign  en_cnt_1 = ~(|cnt[11:0]);
    assign  en_cnt_2 = cnt_tmp > 4000;
    always_comb begin
        if(en_cnt_1) begin
            if(i_start) begin
                cnt_nxt = cnt_tmp;
            end
            else begin
                cnt_nxt = 'b0;
            end
        end
        else begin
            if(en_cnt_2) begin
                cnt_nxt = 'b0;
            end
            else begin
                cnt_nxt = cnt_tmp;
            end
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            cnt <= 'b0;
        end
        else begin
            cnt <= cnt_nxt;
        end
    end

    assign  en = (i_start) ? ~(&cnt[11:0]) : 1'b0;

    assign  angle_incr = o_angle + step[i_doppler_id];
    always_comb begin
        if(en) begin
            angle_modify = 'b0;
        end
        else begin
            if(angle_incr > DOUBLE_PI) begin
                angle_modify = angle_incr - DOUBLE_PI;
            end
            else begin
                angle_modify = angle_incr;
            end
        end
    end
    always_ff @(posedge clk) begin
        o_angle <= angle_modify;
    end

    // always_comb begin
    //         if(en) begin
    //             angle_pipe_1_tmp = 'b0;
    //         end
    //         else begin
    //             angle_pipe_1_tmp = angle_pipe_1 + step[i_doppler_id];
    //         end
    // end

    // always_comb begin
    //     if(angle_pipe_1 > DOUBLE_PI) begin
    //         angle_pipe_2_tmp = angle_pipe_1 - DOUBLE_PI;
    //     end
    //     else begin
    //         angle_pipe_2_tmp = angle_pipe_1;
    //     end
    // end

    logic   vld_pipe_1_tmp;
    always_comb begin
        if(~vld_pipe_1) begin
            if(i_start) begin
                vld_pipe_1_tmp = 1'b1;
            end
            else begin
                vld_pipe_1_tmp = 1'b0;
            end
        end
        else begin
            if(cnt_tmp > 4000) begin
                vld_pipe_1_tmp = 1'b0;
            end
            else begin
                vld_pipe_1_tmp = 1'b1;
            end
        end
    end

    always_ff @( posedge clk, negedge rst_n ) begin
        if(~rst_n) begin
            // angle_pipe_1 <= 'b0;
            // angle_pipe_2 <= 'b0;
            vld_pipe_1 <= 'b0;
            // vld_pipe_2 <= 'b0;
        end
        else begin
            // angle_pipe_1 <= angle_pipe_1_tmp;
            // angle_pipe_2 <= angle_pipe_2_tmp;
            vld_pipe_1 <= vld_pipe_1_tmp;
            // vld_pipe_2 <= vld_pipe_1;
            
        end
    end

    // assign o_vld = vld_pipe_2;
    assign o_vld = vld_pipe_1;
    // assign o_angle = angle_pipe_2;

endmodule
