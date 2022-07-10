import sys
import os
import math
from shutil import copyfile
from os import path

dst_file_path = "./proNet/src/rtl/"
tb_file_path= "./proNet/src/tb/"

def write_defs_file(pre_trained, num_dense_layers, data_width, layers, sigmoid_size, weight_int_size):
	#create directory
	if not os.path.exists(dst_file_path):
		os.makedirs(dst_file_path)
	f=open(dst_file_path+"defs.v","w")
	if pre_trained == "yes":
		f.write('`define PRE_TRAINED\n')
	f.write("`define NUM_LAYERS "+str(num_dense_layers)+'\n')
	f.write("`define DATA_WIDTH "+str(data_width)+'\n')
	i=1
	for i in range(1,len(layers)):
		f.write("`define NEURONS_NUM_L%d %d\n"%(i,layers[i].num_neurons))
		f.write("`define INPUTS_NUM_L%d %d\n"%(i,layers[i-1].num_neurons))
		f.write("`define ACT_TYPE_L%d \"%s\"\n"%(i,layers[i].activation))
	f.write("`define SIGMOID_SIZE %d\n"%(sigmoid_size))
	f.write("`define WEIGHT_INTEGER_WIDTH %d\n"%(weight_int_size))
	f.close()
	# resources_dir = path.join(path.dirname(__file__), 'db/axi_lite_wrapper.v')
	copyfile('./proNet/db/axi_lite_wrapper.v', dst_file_path+'axi_lite_wrapper.v')
	copyfile('./proNet/db/neuron.v', dst_file_path+'neuron.v')
	copyfile('./proNet/db/relu.v', dst_file_path+'relu.v')
	copyfile( './proNet/db/sigmoid_rom.v', dst_file_path+'sigmoid_rom.v')
	copyfile('./proNet/db/memory.v', dst_file_path+'memory.v')

def gen_layer(layer_id, neurons_num, act_type):
	file_name = dst_file_path+"layer_"+str(layer_id)+".v"
	f=open(file_name,"w")
	
	f.write('module layer_%d #(parameter NEURONS_NUM=30, INPUTS_NUM=784, DATA_WIDTH=16,LAYER_ID=1, SIGMOID_SIZE=10, WEIGHT_INTEGER_WIDTH=4,ACT_TYPE="relu")\n'%(layer_id))
	f.write('(\n\
    input clk,\n\
    input reset_n,\n\
    input i_weight_valid,\n\
    input i_bias_valid,\n\
    input [31:0] i_bias_value,\n\
    input [31:0] i_weight_value,\n\
    input [31:0] i_layer_id,\n\
    input [31:0] i_neuron_id,\n\
    input i_data_in_valid,\n\
    input [DATA_WIDTH-1:0] i_data_in,\n\
    output [NEURONS_NUM-1:0] o_data_out_valid,\n\
    output [NEURONS_NUM*DATA_WIDTH-1:0] o_data_out\n\
    );\n')
	for i in range (neurons_num):
		f.write('\nneuron #(.INPUTS_NUM(INPUTS_NUM),.LAYER_ID(LAYER_ID),.NEURON_ID(%d),.DATA_WIDTH(DATA_WIDTH),\n\
    .SIGMOID_SIZE(SIGMOID_SIZE),.WEIGHT_INTEGER_WIDTH(WEIGHT_INTEGER_WIDTH),.ACT_TYPE(ACT_TYPE),\n\
    .WEIGHT_FILE("w_%d_%d.mif"), .BIAS_FILE("b_%d_%d.mif")) neuron_inst_%d(\n\
        .clk(clk),\n\
        .reset_n(reset_n),\n\
        .i_data_in(i_data_in),\n\
        .i_weight_valid(i_weight_valid),\n\
        .i_bias_valid(i_bias_valid),\n\
        .i_weight_value(i_weight_value),\n\
        .i_bias_value(i_bias_value),\n\
        .i_layer_id(i_layer_id),\n\
        .i_neuron_id(i_neuron_id),\n\
        .i_data_in_valid(i_data_in_valid),\n\
        .o_data_out_valid(o_data_out_valid[%d]),\n\
        .o_data_out(o_data_out[%d*DATA_WIDTH+:DATA_WIDTH])\n\
    );'%(i,layer_id,i,layer_id,i,i,i,i))
	f.write('\nendmodule')
	f.close()
def gen_tb():
	copyfile('./proNet/db/Top.v', tb_file_path+'Top.v')

def gen_nn(layers_num=0,layers=[],data_width=0,pre_trained='yes',weights=[],biases=[], sigmoid_size=10,weight_int_size=1,input_int_size=4):
	print("gen_nn layer_num "+str(layers_num)+"\n")
	print("gen_nn len(layers) "+str(len(layers))+"\n")

	if layers_num != len(layers):
		print("Error: Number of layers does not match with the provided layers\n")
		sys.exit()
	if pre_trained == 'yes':
		i=0
		for layer in layers:
			if layer.type == "dense" and layer.activation != "hardmax":
				try:
					if layer.num_neurons != len(weights[i]):
						print("Number of weights available does not match with the number of neurons for layer {}".format(i))
						sys.exit()
					i += 1
				except: 
					print("Number of weights does not match with the number of neurons\n")
			elif layer.type == "dense":
				i +=1
	else:
		i=0
		for layer in layers:
			if layer.type == "dense":
				i+=1

	write_defs_file(pre_trained,i,data_width,layers,sigmoid_size,weight_int_size)
	f=open(dst_file_path+"proNet.v","w")
	g=open("./proNet/module_template")
	data=g.read()
	g.close()
	f.write(data)

	#instantiate layers
	for i in range(1,layers_num):
		if layers[i].type == "dense" and layers[i].activation != "hardmax":

			f.write("wire [`NEURONS_NUM_L%d-1:0] data_outs_valid_%d;\n"%(i,i))
			f.write("wire [`NEURONS_NUM_L%d*`DATA_WIDTH-1:0] data_outs_%d;\n"%(i,i))
			f.write("reg [`NEURONS_NUM_L%d*`DATA_WIDTH-1:0] hold_reg_%d;\n"%(i,i))
			f.write("reg [`DATA_WIDTH-1:0] data_out_%d;\n"%(i))
			f.write("reg data_out_valid_%d;\n"%(i))
			gen_layer(i,layers[i].num_neurons,layers[i].activation)
			if i == 1: #input from the axi stream
				f.write("layer_%d #( .NEURONS_NUM(`NEURONS_NUM_L%d), .INPUTS_NUM(`INPUTS_NUM_L%d),\n\
        		.DATA_WIDTH(`DATA_WIDTH),.LAYER_ID(%d),\n\
        		.SIGMOID_SIZE(`SIGMOID_SIZE),.WEIGHT_INTEGER_WIDTH(`WEIGHT_INTEGER_WIDTH),\n\
        		.ACT_TYPE(`ACT_TYPE_L%d)) layer_%d_inst(\n\
    			.clk(clk),\n\
			    .reset_n(runtime_reset_n),\n\
			    .i_weight_valid(weight_valid),\n\
			    .i_bias_valid(bias_valid),\n\
			    .i_bias_value(bias_value),\n\
			    .i_weight_value(weight_value),\n\
			    .i_layer_id(config_layer_id),\n\
			    .i_neuron_id(config_neuron_id),\n\
			    .i_data_in_valid(axis_data_in_valid),\n\
			    .i_data_in(axis_data_in),\n\
			    .o_data_out_valid(data_outs_valid_%d),\n\
			    .o_data_out(data_outs_%d)\n\
			    );\n"%(i,i,i,i,i,i,i,i))
			else:
				f.write("layer_%d #( .NEURONS_NUM(`NEURONS_NUM_L%d), .INPUTS_NUM(`INPUTS_NUM_L%d),\n\
        		.DATA_WIDTH(`DATA_WIDTH),.LAYER_ID(%d),\n\
        		.SIGMOID_SIZE(`SIGMOID_SIZE),.WEIGHT_INTEGER_WIDTH(`WEIGHT_INTEGER_WIDTH),\n\
        		.ACT_TYPE(`ACT_TYPE_L%d)) layer_%d_inst(\n\
    			.clk(clk),\n\
			    .reset_n(runtime_reset_n),\n\
			    .i_weight_valid(weight_valid),\n\
			    .i_bias_valid(bias_valid),\n\
			    .i_bias_value(bias_value),\n\
			    .i_weight_value(weight_value),\n\
			    .i_layer_id(config_layer_id),\n\
			    .i_neuron_id(config_neuron_id),\n\
			    .i_data_in_valid(data_out_valid_%d),\n\
			    .i_data_in(data_out_%d),\n\
			    .o_data_out_valid(data_outs_valid_%d),\n\
			    .o_data_out(data_outs_%d)\n\
			    );\n"%(i,i,i,i,i,i,i-1,i-1,i,i))
			if layers[i].activation != "hardmax":
				f.write("//state machine for data pipelining \n")
				f.write("reg state_%d;\n"%(i))
				f.write("integer count_%d;\n"%(i))
				f.write("\
 always @(posedge clk)\n\
    begin\n\
        if(!runtime_reset_n)\n\
        begin\n\
            data_out_valid_%d<=0;\n\
            state_%d<=IDLE;\n\
            count_%d<=0;\n\
        end\n\
        else\n\
        begin\n\
            case(state_%d)\n\
                IDLE:\n\
                begin\n\
                    count_%d<=0;\n\
                    data_out_valid_%d<=0;\n\
                    if(data_outs_valid_%d[0])\n\
                    begin\n\
                        hold_reg_%d<=data_outs_%d;\n\
                        state_%d<=SEND;\n\
                    end\n\
                end\n\
                SEND:\n\
                begin\n\
                    data_out_%d<=hold_reg_%d[`DATA_WIDTH-1:0];\n\
                    hold_reg_%d <= hold_reg_%d>>`DATA_WIDTH;\n\
                    count_%d<=count_%d+1;\n\
                    data_out_valid_%d<=1;\n\
                    if(count_%d==`NEURONS_NUM_L%d)\n\
                    begin\n\
                        state_%d<=IDLE;\n\
                        data_out_valid_%d<=0;\n\
                    end\n\
                end\n\
            endcase\n\
        end\n\
    end\n\n"%(i,i,i,i,i,i,i,i,i,i,i,i,i,i,i,i,i,i,i,i,i))

		elif layers[i].activation == "hardmax":
			copyfile('./proNet/db/max_finder.v', dst_file_path+'max_finder.v')
			f.write("reg [`NEURONS_NUM_L%d*`DATA_WIDTH-1:0] hold_reg_%d;\n"%(i-1,i))
			f.write("assign axi_rd_data = hold_reg_%d[`DATA_WIDTH-1:0];\n\n"%(i))
			f.write("\
			    always @(posedge clk)\n\
			    begin\n\
			        if(data_outs_valid_%d[0])\n\
			            hold_reg_%d<=data_outs_%d;\n\
			        else if(axi_rd_en)\n\
			            hold_reg_%d <= hold_reg_%d >> `DATA_WIDTH;\n\
			    end\n\n"%(i-1,i,i-1,i,i))
			f.write("\
			    max_finder #(.INPUTS_NUM(`NEURONS_NUM_L%d), .INPUT_WIDTH(`DATA_WIDTH)) max_finder_inst\n\
			    (\n\
			        .clk(clk),\n\
			        .reset_n(runtime_reset_n),\n\
			        .i_data_in(data_outs_%d),\n\
			        .i_data_in_valid(data_outs_valid_%d),\n\
			        .o_data_out(max_finder_data_out),\n\
			        .o_data_out_valid(max_finder_data_out_valid)\n\
			    );\n\n"%(i-1,i-1,i-1))

			f.write("endmodule\n")
			f.close()

			gen_tb()
			f=open(dst_file_path+"sigContent.mif","w")
			fract_bits = sigmoid_size-(weight_int_size+input_int_size)
			if fract_bits < 0:
				fract_bits = 0
			x=-2**(weight_int_size+input_int_size-1)
			for i in range(0,2**sigmoid_size):
				y=sigmoid(x)
				z=convert_to_binary(y,data_width,data_width-input_int_size)
				f.write(z+'\n')
				x=x+(2**-fract_bits)
			f.close()

def convert_to_binary(num,data_width,fract_bits):
	if num>0:
		num = num * (2**fract_bits)
		num=int(num)
		e=bin(num)[2:]
	else:
		num=-num
		num = num *(2**fract_bits)
		num=int(num)
		if num == 0:
			d=0
		else:
			d= 2**(data_width) - num
		e=bin(d)[2:]
	return e
def sigmoid(x):
	try:
		return 1/(1+math.exp(-x))
	except:
		return 0