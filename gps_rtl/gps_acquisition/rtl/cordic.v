`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Ho Chi Minh City University of Technology
// Engineer: Vu Nam Binh
// 
// Create Date: 11/26/2024 09:48:09 AM
// Design Name: CORDIC Algorithm
// Module Name: cordic
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: sub-module to calculate trigonometric function utilized for GPS ACquisition Process with angle in radians ranges from 0 to 2pi (not process special cases greater than 2pi yet)
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module cordic #(
    parameter WII           =   3,  // # bits of integer part of input angle, an angle from 0 -> 2pi maximum 6.abc -> use 3 bits integer
    parameter WIF           =   31, // # bits of fraction part of input angle
    parameter DAT_WIDTH     =   16, // # bits output cosine and sine
    parameter NUM_STG       =   32  // # stages in pipeline
    // parameter WII           =   3,  // # bits of integer part of input angle, an angle from 0 -> 2pi maximum 6.abc -> use 3 bits integer
    // parameter WIF           =   15, // # bits of fraction part of input angle
    // parameter DAT_WIDTH     =   32, // # bits output cosine and sine
    // parameter NUM_STG       =   16  // # stages in pipeline
)
(
    // input angle in rad
    input                                   clk,
    input                                   rst_n,
    input                                   i_vld,
    input   [WII+WIF:0]                     i_angle,  // 35 bits - Q3.31 + signed bit       
    // input   [WII+WIF:0]                     i_angle,  // 19 bits - Q4.15 (unsigned)     

    // output cosine and sine results
    output wire signed  [DAT_WIDTH-1:0]     o_cosine,
    output wire signed  [DAT_WIDTH-1:0]     o_sine,
    output                                  o_vld
);
    localparam WI = WII + WIF;
    localparam iter = $clog2(NUM_STG);
    localparam PI           =   'b00110010010000111111011010101000100;
    localparam HALF_PI      =   'b00011001001000011111101101010100010;
    localparam ONE_HALF_PI  =   'b01001011011001011111000111111100110;
    localparam DOUBLE_PI    =   'b01100100100001111110110101010001001;

    wire signed  [WI:0]          x_tmp;
    wire signed  [WI:0]          y_tmp;
    wire signed  [WI:0]          z_tmp;

    reg signed  [WI:0]          x   [0:NUM_STG-1];
    reg signed  [WI:0]          y   [0:NUM_STG-1];
    reg signed  [WI:0]          z   [0:NUM_STG-1];
    reg         [1:0]           quadrant    [0:NUM_STG-1];
    reg         [1:0]           quadrant_tmp;
    reg                         vld [0:NUM_STG-1];

//    reg                         vld;
    
    wire signed [WIF:0]          atan2   [0:NUM_STG-1];
    
    // Q1.31
    assign atan2[0]     = 'b00001100100100001111110110101010001;        // atan2 (45 degrees in radians = 0.785...)
    assign atan2[1]     = 'b00000111011010110001100111000001010;
    assign atan2[2]     = 'b00000011111010110110111010111111001;
    assign atan2[3]     = 'b00000001111111010101101110101001101;
    assign atan2[4]     = 'b00000000111111111010101011011101101;
    assign atan2[5]     = 'b00000000011111111111010101010110111;
    assign atan2[6]     = 'b00000000001111111111111010101010101;
    assign atan2[7]     = 'b00000000000111111111111111010101010;
    assign atan2[8]     = 'b00000000000011111111111111111010101;
    assign atan2[9]     = 'b00000000000001111111111111111111010;
    assign atan2[10]    = 'b00000000000000111111111111111111111;
    assign atan2[11]    = 'b00000000000000011111111111111111111;
    assign atan2[12]    = 'b00000000000000001111111111111111111;
    assign atan2[13]    = 'b00000000000000000111111111111111111;
    assign atan2[14]    = 'b00000000000000000011111111111111111;
    assign atan2[15]    = 'b00000000000000000001111111111111111;
    assign atan2[16]    = 'b00000000000000000000111111111111111;
    assign atan2[17]    = 'b00000000000000000000011111111111111;
    assign atan2[18]    = 'b00000000000000000000001111111111111;
    assign atan2[19]    = 'b00000000000000000000000111111111111;
    assign atan2[20]    = 'b00000000000000000000000011111111111;
    assign atan2[21]    = 'b00000000000000000000000001111111111;
    assign atan2[22]    = 'b00000000000000000000000000111111111;
    assign atan2[23]    = 'b00000000000000000000000000011111111;
    assign atan2[24]    = 'b00000000000000000000000000001111111;
    assign atan2[25]    = 'b00000000000000000000000000000111111;
    assign atan2[26]    = 'b00000000000000000000000000000011111;
    assign atan2[27]    = 'b00000000000000000000000000000010000;
    assign atan2[28]    = 'b00000000000000000000000000000001000;
    assign atan2[29]    = 'b00000000000000000000000000000000100;
    assign atan2[30]    = 'b00000000000000000000000000000000010;
    assign atan2[31]    = 'b00000000000000000000000000000000001;

    // Q1.15
    // assign atan2[0] = 'b0110010010001000;
    // assign atan2[1] = 'b0011101101011001;
    // assign atan2[2] = 'b0001111101011011;
    // assign atan2[3] = 'b0000111111101011;
    // assign atan2[4] = 'b0000011111111101;
    // assign atan2[5] = 'b0000010000000000;
    // assign atan2[6] = 'b0000001000000000;
    // assign atan2[7] = 'b0000000100000000;
    // assign atan2[8] = 'b0000000010000000;
    // assign atan2[9] = 'b0000000001000000;
    // assign atan2[10] = 'b0000000000100000;
    // assign atan2[11] = 'b0000000000010000;
    // assign atan2[12] = 'b0000000000001000;
    // assign atan2[13] = 'b0000000000000100;
    // assign atan2[14] = 'b0000000000000010;
    // assign atan2[15] = 'b0000000000000001;

    // Q1.63
    // assign atan2[0] = 'b0110010010000111111011010101000100010000101101000110000000000000;
    // assign atan2[1] = 'b0011101101011000110011100000101011000011011101101001111000000000;
    // assign atan2[2] = 'b0001111101011011011101011111100100101100100000001101110100000000;
    // assign atan2[3] = 'b0000111111101010110111010100110101010110000101111011011100000000;
    // assign atan2[4] = 'b0000011111111101010101101110110111001011001111110111101010000000;
    // assign atan2[5] = 'b0000001111111111101010101011011101110101001011101100010010100000;
    // assign atan2[6] = 'b0000000111111111111101010101010110111011101101110010100110110000;
    // assign atan2[7] = 'b0000000011111111111111101010101010101101110111011101010010111000;
    // assign atan2[8] = 'b0000000001111111111111111101010101010101011011101110111011011100;
    // assign atan2[9] = 'b0000000000111111111111111111101010101010101010110111011101111000;
    // assign atan2[10] = 'b0000000000011111111111111111111101010101010101010101101110111100;
    // assign atan2[11] = 'b0000000000001111111111111111111111101010101010101010101011011110;
    // assign atan2[12] = 'b0000000000000111111111111111111111111101010101010101010101010111;
    // assign atan2[13] = 'b0000000000000011111111111111111111111111101010101010101010101011;
    // assign atan2[14] = 'b0000000000000001111111111111111111111111111101010101010101010101;
    // assign atan2[15] = 'b0000000000000000111111111111111111111111111111101010101010101011;
    // assign atan2[16] = 'b0000000000000000011111111111111111111111111111111101010101010101;
    // assign atan2[17] = 'b0000000000000000001111111111111111111111111111111111101010101011;
    // assign atan2[18] = 'b0000000000000000000111111111111111111111111111111111111101010101;
    // assign atan2[19] = 'b0000000000000000000011111111111111111111111111111111111111101011;
    // assign atan2[20] = 'b0000000000000000000001111111111111111111111111111111111111111101;
    // assign atan2[21] = 'b0000000000000000000001000000000000000000000000000000000000000000;
    // assign atan2[22] = 'b0000000000000000000000100000000000000000000000000000000000000000;
    // assign atan2[23] = 'b0000000000000000000000010000000000000000000000000000000000000000;
    // assign atan2[24] = 'b0000000000000000000000001000000000000000000000000000000000000000;
    // assign atan2[25] = 'b0000000000000000000000000100000000000000000000000000000000000000;
    // assign atan2[26] = 'b0000000000000000000000000010000000000000000000000000000000000000;
    // assign atan2[27] = 'b0000000000000000000000000001000000000000000000000000000000000000;
    // assign atan2[28] = 'b0000000000000000000000000000100000000000000000000000000000000000;
    // assign atan2[29] = 'b0000000000000000000000000000010000000000000000000000000000000000;
    // assign atan2[30] = 'b0000000000000000000000000000001000000000000000000000000000000000;
    // assign atan2[31] = 'b0000000000000000000000000000000100000000000000000000000000000000;
    // assign atan2[32] = 'b0000000000000000000000000000000010000000000000000000000000000000;
    // assign atan2[33] = 'b0000000000000000000000000000000001000000000000000000000000000000;
    // assign atan2[34] = 'b0000000000000000000000000000000000100000000000000000000000000000;
    // assign atan2[35] = 'b0000000000000000000000000000000000010000000000000000000000000000;
    // assign atan2[36] = 'b0000000000000000000000000000000000001000000000000000000000000000;
    // assign atan2[37] = 'b0000000000000000000000000000000000000100000000000000000000000000;
    // assign atan2[38] = 'b0000000000000000000000000000000000000010000000000000000000000000;
    // assign atan2[39] = 'b0000000000000000000000000000000000000001000000000000000000000000;
    // assign atan2[40] = 'b0000000000000000000000000000000000000000100000000000000000000000;
    // assign atan2[41] = 'b0000000000000000000000000000000000000000010000000000000000000000;
    // assign atan2[42] = 'b0000000000000000000000000000000000000000001000000000000000000000;
    // assign atan2[43] = 'b0000000000000000000000000000000000000000000100000000000000000000;
    // assign atan2[44] = 'b0000000000000000000000000000000000000000000010000000000000000000;
    // assign atan2[45] = 'b0000000000000000000000000000000000000000000001000000000000000000;
    // assign atan2[46] = 'b0000000000000000000000000000000000000000000000100000000000000000;
    // assign atan2[47] = 'b0000000000000000000000000000000000000000000000010000000000000000;
    // assign atan2[48] = 'b0000000000000000000000000000000000000000000000001000000000000000;
    // assign atan2[49] = 'b0000000000000000000000000000000000000000000000000100000000000000;
    // assign atan2[50] = 'b0000000000000000000000000000000000000000000000000010000000000000;
    // assign atan2[51] = 'b0000000000000000000000000000000000000000000000000001000000000000;
    // assign atan2[52] = 'b0000000000000000000000000000000000000000000000000000100000000000;
    // assign atan2[53] = 'b0000000000000000000000000000000000000000000000000000010000000000;
    // assign atan2[54] = 'b0000000000000000000000000000000000000000000000000000001000000000;
    // assign atan2[55] = 'b0000000000000000000000000000000000000000000000000000000100000000;
    // assign atan2[56] = 'b0000000000000000000000000000000000000000000000000000000010000000;
    // assign atan2[57] = 'b0000000000000000000000000000000000000000000000000000000001000000;
    // assign atan2[58] = 'b0000000000000000000000000000000000000000000000000000000000100000;
    // assign atan2[59] = 'b0000000000000000000000000000000000000000000000000000000000010000;
    // assign atan2[60] = 'b0000000000000000000000000000000000000000000000000000000000001000;
    // assign atan2[61] = 'b0000000000000000000000000000000000000000000000000000000000000100;
    // assign atan2[62] = 'b0000000000000000000000000000000000000000000000000000000000000010;
    // assign atan2[63] = 'b0000000000000000000000000000000000000000000000000000000000000001;


    preprocessing_angle p_a(
        .i_angle(i_angle),
        
        .x_o(x_tmp),
        .y_o(y_tmp),
        .z_o(z_tmp),
        .quadrant(quadrant_tmp)
    );

    always @* begin
        if(i_angle >= 0 && i_angle <= HALF_PI) begin
            quadrant_tmp = 2'b00;
        end
        else if(i_angle > HALF_PI && i_angle <= PI) begin
            quadrant_tmp = 2'b01;
        end
        else if(i_angle > PI && i_angle <= ONE_HALF_PI) begin
            quadrant_tmp = 2'b10;
        end
        else begin
            quadrant_tmp = 2'b11;
        end
    end

    always @(posedge clk) begin
        quadrant[0] <= quadrant_tmp;
    end

    always @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            x[0] <= 'b0;
            y[0] <= 'b0;
            z[0] <= 'b0;
            vld[0] <= 'b0;
        end
        else begin
            x[0]    <=  x_tmp;
            y[0]    <=  y_tmp;
            z[0]    <=  z_tmp;
            vld[0]  <=  i_vld;
        end
    end
    
    genvar i;
    generate
        for(i=0; i<NUM_STG-1; i=i+1)
        begin
            wire d;
            wire signed [WI:0]  x_sr, y_sr;
            wire signed [WI:0]  newx, newy, newz;
            
            assign d = z[i][WI];
            assign x_sr = x[i] >>> i;
            assign y_sr = y[i] >>> i;
            
            assign newx = d ? (x[i] + y_sr) : (x[i] - y_sr);
            assign newy = d ? (y[i] - x_sr) : (y[i] + x_sr);
            assign newz = d ? (z[i] + atan2[i]) : (z[i] - atan2[i]);
            
            always @(posedge clk, negedge rst_n) begin
                if(~rst_n) begin
                    x[i+1] <= 'b0;
                    y[i+1] <= 'b0;
                    z[i+1] <= 'b0;
                    vld[i+1] <= 'b0;
                end
                else begin
                    x[i+1]      <=  newx;
                    y[i+1]      <=  newy;
                    z[i+1]      <=  newz;
                    vld[i+1]    <=  vld[i];
                end
            end

            always @(posedge clk) begin
                quadrant[i+1] <= quadrant[i];
            end
        end
    endgenerate
//    assign o_cosine = x[NUM_STG-1];
//    assign o_sine   = y[NUM_STG-1];
    reg     signed  [31:0]  cosine_pipe_1_tmp;
    reg     signed  [31:0]  sine_pipe_1_tmp;
    reg     signed  [31:0]  cosine_pipe_2_tmp;
    reg     signed  [31:0]  sine_pipe_2_tmp;
    reg                     vld_pipe_1;
    reg                     vld_pipe_2;
    reg     signed  [31:0]  cosine_pipe_1;
    reg     signed  [31:0]  cosine_pipe_2;
    reg     signed  [31:0]  sine_pipe_1;
    reg     signed  [31:0]  sine_pipe_2;
    reg             [1:0]   quadrant_pipe_1;
    always @* begin
        if(x[NUM_STG-1][WIF] & (~x[NUM_STG-1][WI-1])) begin         // if exceed +1
            cosine_pipe_1_tmp = 32'b01111111111111111111111111111111;
        end
        else if(~x[NUM_STG-1][WIF] & (x[NUM_STG-1][WI-1])) begin    // if exceed -1
            cosine_pipe_1_tmp = 32'b10000000000000000000000000000000;
        end
        else begin  // if not exceed
            cosine_pipe_1_tmp = x[NUM_STG-1];
        end
    end

    always @* begin
        if(y[NUM_STG-1][WIF] & (~y[NUM_STG-1][WI-1])) begin         // if exceed +1
            sine_pipe_1_tmp = 32'b01111111111111111111111111111111;
        end
        else if(~y[NUM_STG-1][WIF] & (y[NUM_STG-1][WI-1])) begin    // if exceed -1
            sine_pipe_1_tmp = 32'b10000000000000000000000000000000;
        end
        else begin  // if not exceed
            sine_pipe_1_tmp = y[NUM_STG-1];
        end
    end

    always @* begin
        case(quadrant_pipe_1)
            2'b00:
                begin
                    cosine_pipe_2_tmp = cosine_pipe_1;
                    sine_pipe_2_tmp = sine_pipe_1;
                end

            2'b01:  // 2nd quadrant
                begin
                    // cosine_pipe_2_tmp = $signed(-cosine_pipe_1);
                    // sine_pipe_2_tmp = sine_pipe_1;
                    cosine_pipe_2_tmp = $signed(-sine_pipe_1);
                    sine_pipe_2_tmp = cosine_pipe_1;
                end

            2'b10:   // 3rd quadrant
                begin
                    cosine_pipe_2_tmp = $signed(-cosine_pipe_1);
                    sine_pipe_2_tmp = $signed(-sine_pipe_1);
                end

            2'b11:  // 4th quadrant
                begin
                    cosine_pipe_2_tmp = sine_pipe_1;
                    sine_pipe_2_tmp = $signed(-cosine_pipe_1);
                end
            default:
                begin
                    cosine_pipe_2_tmp = cosine_pipe_1;
                    sine_pipe_2_tmp = sine_pipe_1;
                end
        endcase
    end

    always @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            vld_pipe_1 <= 'b0;
            vld_pipe_2 <= 'b0;
        end
        else begin
            vld_pipe_1 <= vld[NUM_STG-1];
            vld_pipe_2 <= vld_pipe_1;
        end
    end

    always @(posedge clk) begin
        cosine_pipe_1 <= cosine_pipe_1_tmp;
        sine_pipe_1 <= sine_pipe_1_tmp;
        cosine_pipe_2 <= cosine_pipe_2_tmp;
        sine_pipe_2 <= sine_pipe_2_tmp;
        quadrant_pipe_1 <= quadrant[NUM_STG-1];
    end

    assign  o_vld = vld_pipe_2;
    assign  o_cosine = cosine_pipe_2 >>> 16;
    assign  o_sine = sine_pipe_2 >>> 16;

endmodule
