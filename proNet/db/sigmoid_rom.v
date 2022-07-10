`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: sigmoid_rom
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


module sigmoid_rom #(parameter DATA_IN_WIDTH=10, DATA_OUT_WIDTH=16)(
    input clk,
    input reset_n,
    input [DATA_IN_WIDTH-1:0] i_data_in,
    output [DATA_OUT_WIDTH-1:0] o_data_out
    );
    reg [DATA_OUT_WIDTH-1:0] mem [2**DATA_IN_WIDTH-1:0];
    reg [DATA_IN_WIDTH-1:0] tmp;
    initial 
    begin
        $readmemb("sigContent.mif",mem);
    end
    always @(posedge clk)
    begin
        if(!reset_n)
            tmp <= 0;
        else if($signed(i_data_in)>=0)
            tmp <= i_data_in+(2**(DATA_IN_WIDTH-1));
        else
            tmp <= i_data_in-(2**(DATA_IN_WIDTH-1));
    end
    assign o_data_out = mem[tmp];
endmodule
