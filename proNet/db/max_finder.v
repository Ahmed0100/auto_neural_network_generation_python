`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:
// Design Name: 
// Module Name: max_finder
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


module max_finder #(parameter INPUTS_NUM=10, parameter INPUT_WIDTH=16)(
    input clk,
    input reset_n,
    input [(INPUTS_NUM*INPUT_WIDTH)-1:0] i_data_in,
    input i_data_in_valid,
    output reg [31:0] o_data_out,
    output reg o_data_out_valid
    );
    reg [(INPUTS_NUM*INPUT_WIDTH)-1:0] data_buffer;
    reg [INPUT_WIDTH-1:0] max_value;
    integer counter;
    always @(posedge clk)
    begin
        o_data_out_valid <= 0;
        if(i_data_in_valid)
        begin
            max_value <= i_data_in[INPUT_WIDTH-1:0];
            counter <= 1;
            data_buffer<=i_data_in;
            o_data_out<=0;
        end
        else if(counter== INPUTS_NUM)
        begin
            counter<=0;
            o_data_out_valid <= 1;
        end
        else if(counter!=0)
        begin
            counter<=counter+1;
            if(data_buffer[(counter*INPUT_WIDTH)+:INPUT_WIDTH]>max_value)
            begin
                max_value<=data_buffer[(counter*INPUT_WIDTH)+:INPUT_WIDTH];
                o_data_out<=counter;
            end
        end
    end
endmodule
