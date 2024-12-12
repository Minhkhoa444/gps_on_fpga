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
    parameter DAT_WIDTH     =   32, // # bits output cosine and sine
    parameter NUM_STG       =   32  // # stages in pipeline
)
(
    // input angle in rad
    input                                   clk,
    input                                   m_axis_tvalid_i,
    input   [WII+WIF:0]                     angle_i,  // 35 bits - Q3.31 + signed bit       

    // output cosine and sine results
    output wire signed  [DAT_WIDTH-1:0]     cosine_o,
    output wire signed  [DAT_WIDTH-1:0]     sine_o,
    output                                  s_axis_tvalid_o
);
    localparam WI = WII + WIF;
    localparam iter = $clog2(NUM_STG);

    wire signed  [WI:0]          x_tmp;
    wire signed  [WI:0]          y_tmp;
    wire signed  [WI:0]          z_tmp;

    reg signed  [WI:0]          x   [0:NUM_STG-1];
    reg signed  [WI:0]          y   [0:NUM_STG-1];
    reg signed  [WI:0]          z   [0:NUM_STG-1];
    reg                         vld [0:NUM_STG-1];

//    reg                         vld;
    
    wire signed [WI:0]          atan2   [0:NUM_STG-1];
    
    assign atan2[0]     = 'b00001100100100001111110110101010001;
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

    preprocessing_angle p_a(
        .angle_i(angle_i),
        
        .x_o(x_tmp),
        .y_o(y_tmp),
        .z_o(z_tmp)
    );

    always @(posedge clk) begin
        begin
            x[0]    <=  x_tmp;
            y[0]    <=  y_tmp;
            z[0]    <=  z_tmp;
            vld[0]  <=  m_axis_tvalid_i;
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
            
            always @(posedge clk) begin
                begin
                    x[i+1]      <=  newx;
                    y[i+1]      <=  newy;
                    z[i+1]      <=  newz;
                    vld[i+1]    <=  vld[i];
                end
            end
        end
    endgenerate
    assign cosine_o = x[NUM_STG-1];
    assign sine_o   = y[NUM_STG-1];
    assign s_axis_tvalid_o = vld[NUM_STG-1];
endmodule
