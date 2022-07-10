`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:
// Design Name: 
// Module Name: neuron
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

module neuron #(parameter LAYER_ID=0,NEURON_ID=0, INPUTS_NUM=784, DATA_WIDTH=16, SIGMOID_SIZE=10, WEIGHT_INTEGER_WIDTH=4,ACT_TYPE="relu",BIAS_FILE="b_1_0.mif",WEIGHT_FILE="w_1_0.mif")(
    input clk,
    input reset_n,
    input [DATA_WIDTH-1:0] i_data_in,
    input i_data_in_valid,
    input [31:0] i_weight_value,
    input i_weight_valid,
    input [31:0] i_bias_value,
    input i_bias_valid,
    input [31:0] i_layer_id,
    input [31:0] i_neuron_id,
    output [DATA_WIDTH-1:0] o_data_out,
    output reg o_data_out_valid
    );
    parameter ADDR_WIDTH = $clog2(INPUTS_NUM);
    
    reg w_en;
    wire r_en;
    reg [ADDR_WIDTH-1:0] r_addr,w_addr;
    reg [DATA_WIDTH-1:0] w_in;
    wire [DATA_WIDTH-1:0] w_out;
    reg [2*DATA_WIDTH-1:0] mul,sum,bias;
    wire [2*DATA_WIDTH-1:0] comb_add,bias_add;
    reg [DATA_WIDTH-1:0] data_in_d;
     
    reg weight_valid_d;
    reg mult_valid;
    wire mux_valid;
    reg mux_valid_d;
    reg mux_valid_f;
    reg sig_valid;
    
    reg [31:0] bias_mem[0:0];
    reg bias_addr=0;
    //loading weights into memory
    always @(posedge clk)
    begin
        if(!reset_n)
        begin
            w_addr <= {ADDR_WIDTH{1'b1}};
            w_en <= 0;
        end
        else if(i_weight_valid && (i_layer_id == LAYER_ID) &&
        (i_neuron_id == NEURON_ID))
        begin
            w_in <= i_weight_value;
            w_addr <= w_addr+1;
            w_en<=1;
        end
        else
            w_en <= 0;
    end
    
    assign comb_add = mul+sum;
    assign bias_add = bias+sum;
    assign r_en = i_data_in_valid;
    assign mux_valid = mult_valid;
    
    `ifdef PRE_TRAINED
        initial
        begin
            $readmemb(BIAS_FILE,bias_mem);
        end
        always @(posedge clk)
        begin
            bias <= {bias_mem[bias_addr][DATA_WIDTH-1:0],{DATA_WIDTH{1'b0}}};
        end
    `else
        always @(posedge clk)
        begin
            if(i_bias_valid && (i_layer_num == LAYER_NUM) &&
            (i_neuron_num == NEURON_NUM))
            begin
                bias <= {i_bias_value[DATA_WIDTH-1:0],{DATA_WIDTH{1'b0}}};
            end
        end   
    `endif
    
    always @(posedge clk)
    begin
        if(!reset_n|o_data_out_valid)
            r_addr<=0;
        else if(i_data_in_valid)
            r_addr <= r_addr+1;
    end
    
    always @(posedge clk)
    begin
        mul <= $signed(data_in_d) * $signed(w_out);
    end
    
    always @(posedge clk)
    begin
        if(~reset_n|o_data_out_valid)
            sum <= 0;
        else if((r_addr == INPUTS_NUM) & mux_valid_f)
        begin
            if(!bias[2*DATA_WIDTH-1] &!sum[2*DATA_WIDTH-1] & bias_add[2*DATA_WIDTH-1]) //If bias and sum are positive and after adding bias to sum, if sign bit becomes 1, saturate
            begin
                sum[2*DATA_WIDTH-1] <= 1'b0;
                sum[2*DATA_WIDTH-2:0] <= {2*DATA_WIDTH-1{1'b1}};
            end
            else if(bias[2*DATA_WIDTH-1] & sum[2*DATA_WIDTH-1] &  !bias_add[2*DATA_WIDTH-1]) //If bias and sum are negative and after addition if sign bit is 0, saturate
            begin
                sum[2*DATA_WIDTH-1] <= 1'b1;
                sum[2*DATA_WIDTH-2:0] <= {2*DATA_WIDTH-1{1'b0}};
            end
            else
                sum <= bias_add; 
        end
        else if(mux_valid)
        begin
            if(!mul[2*DATA_WIDTH-1] & !sum[2*DATA_WIDTH-1] & comb_add[2*DATA_WIDTH-1])
            begin
                sum[2*DATA_WIDTH-1] <= 1'b0;
                sum[2*DATA_WIDTH-2:0] <= {2*DATA_WIDTH-1{1'b1}};
            end
            else if(mul[2*DATA_WIDTH-1] & sum[2*DATA_WIDTH-1] & !comb_add[2*DATA_WIDTH-1])
            begin
                sum[2*DATA_WIDTH-1] <= 1'b1;
                sum[2*DATA_WIDTH-2:0] <= {2*DATA_WIDTH-1{1'b0}};
            end
            else
                sum <= comb_add; 
        end
    end
    
    always @(posedge clk)
    begin
        data_in_d <= i_data_in;
        weight_valid_d <= i_data_in_valid;
        mult_valid <= weight_valid_d;
        sig_valid <= ((r_addr == INPUTS_NUM) & mux_valid_f);
        o_data_out_valid <= sig_valid;
        mux_valid_d <= mux_valid;
        mux_valid_f <= !mux_valid & mux_valid_d;
    end
    memory #( .MEM_DEPTH(INPUTS_NUM), .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH),
    .INIT_FILE(WEIGHT_FILE)) w_mem_inst
    (
        .clk(clk),
        .reset_n(reset_n),
        .i_r_en(r_en),
        .i_w_en(w_en),
        .i_w_addr(w_addr),
        .i_r_addr(r_addr),
        .i_data_in(w_in),
        .o_data_out(w_out)
    );
    generate
        if(ACT_TYPE == "sigmoid")
        begin: sig
            sigmoid_rom #( .DATA_IN_WIDTH(SIGMOID_SIZE),
            .DATA_OUT_WIDTH(DATA_WIDTH)) sig_inst
            (
                .clk(clk),
                .reset_n(reset_n),
                .i_data_in(sum[2*DATA_WIDTH-1-:SIGMOID_SIZE]),
                .o_data_out(o_data_out)
            );
        end
        else 
        begin: relu
            relu #( .DATA_WIDTH(DATA_WIDTH), .INTEGER_WIDTH(WEIGHT_INTEGER_WIDTH)) relu_inst
            (
                .clk(clk),
                .reset_n(reset_n),
                .i_data_in(sum),
                .o_data_out(o_data_out)
            );
        end
    endgenerate
    `ifdef DEBUG
        always @(posedge clk)
        begin
            if(o_data_out_valid)
                $display(i_neuron_num,,,,"%b",o_data_out);
        end
    `endif
endmodule
