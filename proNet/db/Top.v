`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: Top
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
`include "..\..\sources_1\new\defs.v"
`define samples_num 100
module Top(

    );

    localparam C_S_AXI_DATA_WIDTH=32,C_S_AXI_ADDR_WIDTH=5;

    reg clk,reset_n;
    //axis stream interface
    reg [`DATA_WIDTH-1:0] axis_data_in;
    reg axis_data_in_valid;

    //AXI lite interface
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr;
    reg  s_axi_awvalid;
    wire s_axi_awready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata;
    reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb;
    reg s_axi_wvalid;
    wire s_axi_wready;
    wire s_axi_bvalid;
    reg s_axi_bready;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr;
    reg s_axi_arvalid;
    wire s_axi_arready;
    wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata;
    wire s_axi_rvalid;
    reg s_axi_rready;
    wire intr;
//////////
    reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rd_data;
    reg [C_S_AXI_DATA_WIDTH-1:0] axis_data_in_mem [784:0];
    reg [`DATA_WIDTH-1:0] expected_result;

//////////
    wire [31:0] num_neurons[31:1];
    wire [31:0] num_weights[31:1];
    
    assign num_neurons[1] = `NEURONS_NUM_L1;
    assign num_neurons[2] = `NEURONS_NUM_L2;
    assign num_neurons[3] = `NEURONS_NUM_L3;
    assign num_neurons[4] = `NEURONS_NUM_L4;
    
    assign num_weights[1] = `INPUTS_NUM_L1;
    assign num_weights[2] = `INPUTS_NUM_L2;
    assign num_weights[3] = `INPUTS_NUM_L3;
    assign num_weights[4] = `INPUTS_NUM_L4;
//////////
    reg [7:0] file_name[23:0];
//////////
    proNet dut(
    .clk(clk),
    .reset_n(reset_n),

    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awprot(0),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(4'hF),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),
    .s_axi_bresp(),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arprot(0),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    .axis_data_in(axis_data_in),
    .axis_data_in_valid(axis_data_in_valid),
    .axis_data_in_ready(),
    .intr(intr)
    );
    initial
    begin
        clk = 1'b0;
        s_axi_awvalid = 1'b0;
        s_axi_wvalid = 1'b0;
        s_axi_bready = 1'b0;
        s_axi_arvalid = 1'b0;
    end
    always 
        #5 clk = !clk;

    function [7:0] to_ascii;
        input integer a;
        begin
            to_ascii = a+48;
        end
    endfunction
    always @(posedge 
        clk)
    begin
        s_axi_bready <= s_axi_bvalid;
        s_axi_rready <= s_axi_rvalid;
    end
    task write_axi( input [C_S_AXI_ADDR_WIDTH-1:0] address,
        input [C_S_AXI_DATA_WIDTH-1:0] data);
    begin
         @(posedge clk);
         s_axi_awvalid <= 1'b1;
         s_axi_awaddr <= address;
         s_axi_wdata <= data;
         s_axi_wvalid <= 1'b1;
         wait(s_axi_wready);
         @(posedge clk);
         s_axi_awvalid<= 0;
         s_axi_wvalid<=0;
         @(posedge clk);
    end
    endtask // write_axi
    task read_axi (input [C_S_AXI_ADDR_WIDTH-1:0] address);
    begin
        @(posedge clk);
        s_axi_arvalid <= 1'b1;
        s_axi_araddr<=address;
        wait(s_axi_arready);
        @(posedge clk);
        s_axi_arvalid <= 1'b0;
        wait(s_axi_rvalid);
        @(posedge clk);
        axi_rd_data <= s_axi_rdata;
        @(posedge clk);
    end
    endtask

    task config_weights();
    integer i,j,k,t;
    integer neuron_id;
    reg [`DATA_WIDTH:0] config_mem[783:0];
    begin
        @(posedge clk);
        for(k=1;k<=`NUM_LAYERS;k=k+1)
        begin
            write_axi(12,k);//write layer id
            for(j=0;j<num_neurons[k];j=j+1)
            begin
                neuron_id = j;
                file_name[0]="f";
                file_name[1]="i";
                file_name[2]="m";
                file_name[3]=".";
                if(j>9)
                begin
                    file_name[4]=48;
                    file_name[5]=48;
                    i=0;
                    while(neuron_id!=0)
                    begin
                        file_name[i+4]= to_ascii(neuron_id%10);
                        neuron_id= neuron_id/10;
                        i=i+1;
                    end
                    file_name[6]="_";
                    file_name[7]=to_ascii(k);
                    file_name[8]="_";
                    file_name[9]="w";
                end
                else
                begin
                    file_name[4]=48;
                    i=0;
                    while(neuron_id!=0)
                    begin
                        file_name[i+4]=to_ascii(neuron_id%10);
                        neuron_id = neuron_id/10;
                        i=i+1;
                    end
                    file_name[5]="_";
                    file_name[6]=to_ascii(k);
                    file_name[7]="_";
                    file_name[8]="w";
                end
                $readmemb(file_name,config_mem);
                write_axi(16,j); //write neuron num;
                for(t=0;t<num_neurons[k];t=t+1)
                begin
                    write_axi(0,{15'd0,config_mem[t]});
                end
            end
        end
    end
    endtask // task

    task config_bias();
    integer i,j,k,t;
    integer neuron_id;
    reg [31:0] config_mem[0:0];
    begin
        @(posedge clk);
        for(k=1;k<=`NUM_LAYERS;k=k+1)
        begin
            write_axi(12,k);//write layer id
            for(j=0;j<num_neurons[k];j=j+1)
            begin
                neuron_id = j;
                file_name[0]="f";
                file_name[1]="i";
                file_name[2]="m";
                file_name[3]=".";
                if(j>9)
                begin
                    file_name[4]=48;
                    file_name[5]=48;
                    i=0;
                    while(neuron_id!=0)
                    begin
                        file_name[i+4]= to_ascii(neuron_id%10);
                        neuron_id= neuron_id/10;
                        i=i+1;
                    end
                    file_name[6]="_";
                    file_name[7]=to_ascii(k);
                    file_name[8]="_";
                    file_name[9]="b";
                end
                else
                begin
                    file_name[4]=48;
                    i=0;
                    while(neuron_id!=0)
                    begin
                        file_name[i+4]=to_ascii(neuron_id%10);
                        neuron_id = neuron_id/10;
                        i=i+1;
                    end
                    file_name[5]="_";
                    file_name[6]=to_ascii(k);
                    file_name[7]="_";
                    file_name[8]="b";
                end
                $readmemb(file_name,config_mem);
                write_axi(16,j); //write neuron num;
                write_axi(4,{15'd0,config_mem[0]});
            end
        end
    end
    endtask // task

    task send_data();
    integer t;
    begin
        $readmemb(file_name,axis_data_in_mem);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        for(t=0;t<784;t=t+1)
        begin
            @(posedge clk);
            axis_data_in <= axis_data_in_mem[t];
            axis_data_in_valid<=1;
        end
        @(posedge clk);
        axis_data_in_valid<=0;
        expected_result=axis_data_in_mem[t];
    end
    endtask // task

    integer i,j,layer_id=1,k;
    integer start;
    integer test_data_count;
    integer test_data_count_reg;
    integer correct_res_cnt=0;
    integer wrong_res_cnt=0;
    initial 
    begin
        reset_n = 0;
        axis_data_in_valid=0;
        #100
        reset_n = 1;
        #100
        write_axi(28,0); //clear soft reset
        start=$time;
        `ifndef PRE_TRAINED
            config_weights();
            config_bias();
        `endif
        $display("Configuration complete",,,,$time-start,,"ns");
        start=$time;
        for(test_data_count=0;test_data_count<`samples_num;test_data_count=test_data_count+1)
        begin
            test_data_count_reg= test_data_count;
            file_name[0] = "t";
            file_name[1] = "x";
            file_name[2] = "t";
            file_name[3] = ".";
            file_name[4] = "0";
            file_name[5] = "0";
            file_name[6] = "0";
            file_name[7] = "0";
            i=0;
            while(test_data_count_reg!=0)
            begin
                file_name[i+4]=to_ascii(test_data_count_reg%10);
                test_data_count_reg= test_data_count_reg/10;
                i=i+1;
            end
            file_name[8] = "_";
            file_name[9] = "a";
            file_name[10] = "t";
            file_name[11] = "a";
            file_name[12] = "d";
            file_name[13] = "_";
            file_name[14] = "t";
            file_name[15] = "s";
            file_name[16] = "e";
            file_name[17] = "t";
            send_data();
            @(posedge intr);
            read_axi(8);
            if(axi_rd_data == expected_result)
                correct_res_cnt = correct_res_cnt+1;
            $display("%0d. Accuracy: %f, Detected number: %0x, Expected: %x",test_data_count+1,correct_res_cnt*100.0/(test_data_count+1),axi_rd_data,expected_result);

        end
        $display("Accuracy: %f",correct_res_cnt*100.0/test_data_count);
        $stop;
    end
endmodule

