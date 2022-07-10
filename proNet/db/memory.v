`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:
// Design Name: 
// Module Name: memory
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

`include "defs.v"

module memory #(parameter MEM_DEPTH=3, ADDR_WIDTH=10, DATA_WIDTH=16, INIT_FILE="w_1_15.mif")(
    input clk,
    input reset_n,
    input i_w_en,
    input i_r_en,
    input [ADDR_WIDTH-1:0] i_w_addr,
    input [ADDR_WIDTH-1:0] i_r_addr,
    input [DATA_WIDTH-1:0] i_data_in,
    output reg [DATA_WIDTH-1:0] o_data_out);
     
    reg [DATA_WIDTH-1:0] mem[MEM_DEPTH-1:0];
    
    `ifdef PRE_TRAINED
        initial
        begin
            $readmemb(INIT_FILE,mem);
        end    
    `else
        always@(posedge clk)
        begin
            if(i_w_en)
            begin
                mem[i_w_addr]<=i_data_in;
            end
        end
    `endif
    always @(posedge clk)
    begin
        if(i_r_en)
        begin
            o_data_out <= mem[i_r_addr];
        end
    end
endmodule
