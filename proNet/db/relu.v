`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:
// Design Name: 
// Module Name: relu
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


module relu #(parameter DATA_WIDTH = 16, INTEGER_WIDTH=1)(
    input clk,
    input reset_n,
    input [2*DATA_WIDTH-1:0] i_data_in,
    output reg [DATA_WIDTH-1:0] o_data_out
    );
    
    always @(posedge clk)
    begin
        if($signed(i_data_in)>0)
        begin
            if(|i_data_in[2*DATA_WIDTH-1 -: INTEGER_WIDTH+1]) //detect overflow beyond integer width
                o_data_out <= {1'b0,{(DATA_WIDTH-1){1'b1}}};
            else 
                o_data_out<= i_data_in[2*DATA_WIDTH-1-INTEGER_WIDTH -: DATA_WIDTH];
        end
        else
            o_data_out <= 0;
    end
endmodule
