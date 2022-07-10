import json
import math

def gen_weights_array(file_name=""):
	output=[]
	weights_file=open(file_name,"r")
	my_data = weights_file.read()
	my_dict= json.loads(my_data)
	weights= my_dict['weights']
	remove_nestings(weights,output)
	max_val=max(output)
	min_val=min(output)
	min_bits = max(math.ceil(math.log2(abs(int(max_val))+1)), math.ceil(math.log2(abs(int(min_val))+1)) ) +1
	print("Minimum bits required for integer representation of weight values is ",min_bits)
	return weights
def gen_biases_array(file_name=''):
	biases_file=open(file_name,"r")
	my_data = biases_file.read()
	my_dict=json.loads(my_data)
	biases = my_dict['biases']
	return biases

def remove_nestings(l,output):
	for i in l:
		if type(i) == list:
			remove_nestings(i,output)
		else:
			output.append(i)
