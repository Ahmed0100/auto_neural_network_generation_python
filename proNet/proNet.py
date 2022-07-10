from proNet import gen_nn
from proNet import gen_weights_and_biases
import os
from proNet import xilinx_utils

class layer:
	def __init__(self,type="flatten",num_neurons=0,activation=""):
		self.type=type
		self.num_neurons=num_neurons
		if type == "dense":
			self.activation=activation
		def get_num_neurons(self):
			return self.num_neurons
		def get_activation(self):
			return self.activation

class model:
	def __init__(self):
		self.num_layers=0
		self.layers=[]
	def add(self,layer):
		self.num_layers +=1
		self.layers.append(layer)
	def get_num_layers(self):
		return self.num_layers
	def compile(self,pre_trained='no',weights="",biases="",data_width=16,sigmoid_size=5,weight_int_size=1, input_int_size=4):
		gen_nn.gen_nn(self.num_layers,self.layers,data_width,pre_trained=pre_trained,weights=weights,biases=biases, sigmoid_size=sigmoid_size,weight_int_size=weight_int_size,input_int_size=input_int_size)
		if pre_trained=='yes':
			gen_weights_and_biases.gen_weights_and_biases(data_width,data_width-weight_int_size, data_width- weight_int_size- input_int_size,weights,biases)

def make_xilinx_project(project_name='my_project',fpga_part='xc7z020clg484-1'):
	xilinx_utils.make_vivado_project(project_name,fpga_part)

def make_ip(project_name):
	xilinx_utils.make_ip(project_name+'/'+project_name+'.xpr')

def make_system(project_name,block_name):
	xilinx_utils.make_system(project_name+'/'+project_name+'.xpr',project_name+'/../src/', block_name)