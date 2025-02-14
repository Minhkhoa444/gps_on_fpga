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
    input wire signed   [WII+WIF:0]         i_angle,
    input               [1:0]               quadrant,
    
    output wire signed  [WII+WIF:0]         x_o,
    output wire signed  [WII+WIF:0]         y_o,
    output wire signed  [WII+WIF:0]         z_o
    );
    
    // initialize parameters
    localparam PI           =   'b00110010010000111111011010101000100;
    localparam HALF_PI      =   'b00011001001000011111101101010100010;
    localparam ONE_HALF_PI  =   'b01001011011001011111000111111100110;
    localparam DOUBLE_PI    =   'b01100100100001111110110101010001001;

    wire signed [WII+WIF:0] init_x;
    wire signed [WII+WIF:0] init_y;

    reg signed [WII+WIF:0] x_tmp;
    reg signed [WII+WIF:0] y_tmp;
    reg signed [WII+WIF:0] z_tmp;
    
    reg signed [WII+WIF:0]  angle;
    
    assign init_x = 'b00001001101101110100111011011010100;   // k factor = 0.607
    assign init_y = 'b0;
    
    always @* begin
        case(quadrant)
            2'b00:
            begin
                angle = i_angle;
            end

            2'b01:
            begin
                angle = i_angle - HALF_PI;
            end

            2'b10:
            begin
                angle = i_angle - PI;
            end

            2'b11:
            begin
                angle = i_angle - ONE_HALF_PI;
            end

            default:
            begin
               angle = i_angle; 
            end
        endcase
    end

    reg [1:0]  flag;
    
    always @* begin
        if(angle > HALF_PI && angle <= PI) begin
            z_tmp = angle - PI;
            x_tmp = -init_x;
            y_tmp = -init_y;
            flag = 0;
        end
        else begin
            z_tmp = angle;
            x_tmp = init_x;
            y_tmp = init_y;
            flag = 2;
        end
    end

    assign x_o = x_tmp;
    assign y_o = y_tmp;
    assign z_o = z_tmp;
    
endmodule
