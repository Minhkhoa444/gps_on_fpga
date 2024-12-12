`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2024 10:23:45 AM
// Design Name: 
// Module Name: preprocessing_angle
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


module preprocessing_angle #(
    parameter WII   =   3,
    parameter WIF   =   31
)(
    input wire signed [WII+WIF:0]       angle_i,
    
    output wire signed [WII+WIF:0]       x_o,
    output wire signed [WII+WIF:0]       y_o,
    output wire signed [WII+WIF:0]       z_o
    );
    
    // initialize parameters
    localparam PI           =   'b0110010010000111111011010101000100;
    localparam HALF_PI      =   'b0011001001000011111101101010100010;
    localparam DOUBLE_PI    =   'b01100100100001111110110101010001000;

    // initialize
    // wire signed [WII+WIF:0] pi;         // 35 bits
    // wire signed [WII+WIF:0] half_pi;    // 35 bits
    // wire signed [WII+WIF+1:0] double_pi;// 36 bits
    wire signed [WII+WIF:0] init_x;
    wire signed [WII+WIF:0] init_y;

    reg signed [WII+WIF:0] x_tmp;
    reg signed [WII+WIF:0] y_tmp;
    reg signed [WII+WIF:0] z_tmp;
    
    reg signed [WII+WIF:0]  angle;
    
    // assign pi = 'b0110010010000111111011010101000100;           // pi = 3.14
    // assign half_pi = 'b0011001001000011111101101010100010;      // pi/2 = 1.57
    // assign double_pi = 'b01100100100001111110110101010001000;   // 2pi = 6.28
    assign init_x = 'b0001001101101110100111011011010100;
    assign init_y = 'b0;
    
    always @* begin
        if(angle_i > PI) begin
            angle = {1'b0,angle_i} - DOUBLE_PI;
        end
        else begin
            angle = angle_i;
        end
    end
    
    always @* begin
        if(angle > HALF_PI && angle <= PI) begin
            z_tmp = angle - PI;
            x_tmp = -init_x;
            y_tmp = -init_y;
        end
        else if(angle < -HALF_PI && angle >= -PI) begin
            z_tmp = angle + PI;
            x_tmp = -init_x;
            y_tmp = -init_y;
        end
        else begin
            z_tmp = angle;
            x_tmp = init_x;
            y_tmp = init_y;
        end
    end

    assign x_o = x_tmp;
    assign y_o = y_tmp;
    assign z_o = z_tmp;
    
endmodule
