from proNet import proNet
from proNet import utils
import numpy as np

def gen_minst_proNet(data_width, sigmoid_size, weight_int_size, input_int_size):
	model = proNet.model()
	model.add(proNet.layer("flatten",784))
	model.add(proNet.layer("dense",30,"relu"))
	model.add(proNet.layer("dense",30,"relu"))
	model.add(proNet.layer("dense",10,"relu"))
	model.add(proNet.layer("dense",10,"relu"))
	model.add(proNet.layer("dense",10,"hardmax"))
	weights_array = utils.gen_weights_array('weights_and_biases.txt')
	biases_array = utils.gen_biases_array('weights_and_biases.txt')
	model.compile(pre_trained='yes',weights=weights_array,biases=biases_array, data_width=data_width,weight_int_size=weight_int_size,input_int_size=input_int_size,sigmoid_size=sigmoid_size)

if __name__ == "__main__":
	gen_minst_proNet(data_width=16, sigmoid_size=5, weight_int_size=4,input_int_size=1)