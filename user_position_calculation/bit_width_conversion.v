`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2024 03:24:17 PM
// Design Name: 
// Module Name: bitwidthconversion
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


// ------------PARAMETER ABBREVIATION------------//
//      WII: input integer part bit width        //
//      WIF: input fraction part bit width       //
//      WOI: output integer part bit width       //
//      WOF: output fraction part bit width      //
// ----------------------------------------------//

module bit_width_conversion # (
    parameter WII = 15,
    parameter WIF = 16,
    parameter WOI = 15,
    parameter WOF = 16,
    parameter ROUND = 0
)(
    input                           clk,
    input                           rst_n,
    input       [WII+WIF-1 : 0]     in,
    output      [WOI+WOF-1 : 0]     out,
    output                          overflow
    );

    reg                             overflow;
    reg         [WII+WOF-1 : 0]     inr;
    reg         [WII-1 : 0]         ini;
    reg         [WOI-1 : 0]         outi;
    reg         [WOF-1 : 0]         outf;

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            overflow <= 1'b0;
            ini <= {WII{1'b0}};
            outi <= {WOI{1'b0}};
            outf <= {WOF{1'b0}};
        end
    end

    generate if(WOF<WIF) begin  // Giam so bit frac tion
        if(ROUND==0) begin  // Khong round_up
            always @* begin
                if(~rst_n) begin
                    inr = {(WII+WOF){1'b0}};
                end
                else begin
                    inr = in[WII+WIF-1 : WIF-WOF];    // Giam so bit fraction
                end 
            end
        end else if (WII+WOF>=2) begin  // Co round_up
            always @* begin
                if(~rst_n) begin
                    inr = {(WII+WOF){1'b0}};
                end
                else begin
                    inr = in[WII+WIF-1 : WIF-WOF];    // Giam so bit fraction

                    // WIF-WOF-1: MSB of the cut_down segment
                    // WII+WOF-1: Sign bit (MSB) of input
                    // WII+WOF-2:0 remaining bits except for MSB of input
                    if(in[WIF-WOF-1] & ~(~inr[WII+WOF-1] & (&inr[WII+WOF-2:0]))) inr = inr + 1;
                end 
            end
        end else begin
            always @* begin
                if(~rst_n) begin
                    inr = {(WII+WOF){1'b0}};
                end
                else begin
                    inr = in[WII+WIF-1 : WIF-WOF];    // Giam so bit fraction
                    if(in[WIF-WOF-1] & inr[WII+WOF-1]) inr=inr+1;
                end 
            end
        end
    end else if(WOF==WIF) begin // Khong giam so bit fraction
        always @* begin
            if(~rst_n) begin
                inr = {(WII+WOF){1'b0}};
            end
            else begin
                inr[WII+WOF-1:0] = in;
            end
        end
    end else begin              // Tang so bit fraction => mo rong bit 0 cho LSB
        always @* begin
            if(~rst_n) begin
                inr = {(WII+WOF){1'b0}};
            end
            else begin
                inr[WII+WOF-1:WOF-WIF] = in;
                inr[WOF-WIF-1:0] = 0;
            end
        end
    end
    endgenerate

    generate if(WOI<WII) begin      // Giam so bit integer
        always @* begin
            if(~rst_n) begin
                overflow = 1'b0;
                ini = {WII{1'b0}};
                outi = {WOI{1'b0}};
                outf = {WOF{1'b0}};
            end
            else begin
                {ini, outf} = inr;

                // Case positive integer => Nếu phần bit bị cắt bớt vẫn chứa giá trị của số (không chỉ các bit dấu). Ví dụ: Cắt 3 bits trong 8'b00101111 => Ngoài bit MSB là 0 (bit dấu dương) thì bit[2] là '1' là giá trị số => nếu cắt đi sẽ gây overflow cho phần số còn lại (tức 5 bit lúc này không đủ để biểu diễn giá trị của số ban đầu nữa) => tăng giá trị số lên tối đa
                if(~ini[WII-1] & (|ini[WII-2:WOI-1])) begin
                    overflow = 1'b1;
                    outi = {WOI{1'b1}};
                    // outi[WOI-2:0] = {(WOI-1){1'b1}}; // đỉnh nóc kịch trần
                    outi[WOI-1] = 1'b0; // bit dấu là 0 => số dương
                    outf = {WOF{1'b1}}; // đỉnh nóc kịch trần luôn
                end
                // Case negative integer => Nếu có bất kì bit nào trong phần bị cắt bớt là 0 trừ bit MSB => overflow vì bit dấu âm là 1
                else if(ini[WII-1] & ~(&ini[WII-2:WOI-1])) begin
                    overflow = 1'b1;
                    // outi[WOI-2:0] = {(WOI-1){1'b1}};
                    outi = 0;
                    outi[WOI-1] = 1'b1;
                    outf = 0;
                end else begin
                    overflow = 1'b0;
                    outi = ini[WOI-1:0];
                end
            end
        end
    end else begin              // Tang so bit integer => mo rong ve phia MSB
        always @* begin
            if(~rst_n) begin
                overflow = 1'b0;
                ini = {WII{1'b0}};
                outi = {WOI{1'b0}};
                outf = {WOF{1'b0}};
            end
            else begin
                {ini,outf} = inr;
                overflow = 1'b0;
                // outi[WII-1:0] = ini;
                // outi[WOI-1:WOI-WII] = {(WOI-WII){1'b0}};
                outi = ini[WII-1] ? {WOI{1'b1}} : 0;
                outi[WII-1:0] = ini;
            end
        end
    end
    endgenerate

    assign out = {outi, outf};

endmodule
