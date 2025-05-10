// `timescale 1ns / 1ps
// //////////////////////////////////////////////////////////////////////////////////
// // Company: 
// // Engineer: 
// // 
// // Create Date: 01/16/2025 08:36:18 PM
// // Design Name: 
// // Module Name: ifft_bitreverse
// // Project Name: 
// // Target Devices: 
// // Tool Versions: 
// // Description: 
// // 
// // Dependencies: 
// // 
// // Revision:
// // Revision 0.01 - File Created
// // Additional Comments:
// // 
// //////////////////////////////////////////////////////////////////////////////////

// import fft_pkg::*;

// module fft_bitreverse
// #(
//     parameter SIZE = FFT_SIZE,
//     localparam WIDTH = $clog2(SIZE)
// )
// (
//     input   logic       clk,
//     input   logic       rst_n,
//     input   logic       i_vld,
//     input   data_t      i_data,
//     input   logic       last_data,

//     output  logic       o_vld,
//     output  data_t      o_data
// );

//     data_t  pingpong_mem    [0:SIZE*2-1];

//     logic   [WIDTH:0]   wraddr;
//     logic   [WIDTH:0]   wraddr_nxt;
//     logic   [WIDTH:0]   rdaddr;

//     logic   enough_data;
//     logic   sending_last_data;
//     always_ff @(posedge clk, negedge rst_n) begin
//         if(~rst_n) begin
//             enough_data <= 'b0;
//         end
//         else begin
//             if(&wraddr[WIDTH-1:0]) begin
//                 enough_data <= 'b1;
//             end
//         end
//     end
//     always_comb begin
//         if(enough_data) begin
//             if(i_vld) begin
//                 o_vld = 'b1;
//             end
//             else begin
//                 o_vld = sending_last_data;
//             end
//         end
//         else begin
//             o_vld = 'b0;
//         end
//     end
//     always_ff @(posedge clk, negedge rst_n) begin
//         if(~rst_n) begin
//             sending_last_data <= 'b0;
//         end
//         else begin
//             if(~sending_last_data) begin
//                 if(last_data) begin
//                     sending_last_data <= 'b1;
//                 end
//             end
//             else begin
//                 if(&wraddr[D_WIDTH-1:0]) begin
//                     sending_last_data <= 'b0;
//                 end
//             end
//         end
//     end
//     logic wr_en;
//     always_comb begin
//         if(i_vld) begin
//             wr_en = 'b1;
//         end
//         else begin
//             wr_en = sending_last_data;
//         end
//     end

//     logic   [WIDTH:0]   wraddr_tmp;
//     assign  wraddr_tmp = (wr_en) ? wraddr + 1'b1 : wraddr;
//     always_ff @(posedge clk, negedge rst_n) begin
//         if(~rst_n) begin
//             wraddr <= 'b0;
//             wraddr_nxt <= 'b0;
//         end
//         else begin
//             wraddr <= wraddr_tmp;
//             wraddr_nxt[0] <= wraddr[0];
//             wraddr_nxt[WIDTH:1] <= wraddr[WIDTH:1] + 1'b1;
//         end
//     end

// 	genvar	i;
// 	generate 
//         for(i=0; i<WIDTH; i=i+1)
//         begin
//             assign rdaddr[i] = wraddr_nxt[WIDTH-1-i];
//         end 
//     endgenerate
//     assign  rdaddr[WIDTH] = ~wraddr_nxt[WIDTH];

//     always_ff @(posedge clk) begin
//         if(en) begin
//             pingpong_mem[wraddr] <= i_data;
//         end
//         o_data <= pingpong_mem[rdaddr];
//     end

//     assign o_vld = start;
// endmodule