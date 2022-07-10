output_path="./proNet/w_b/"
header_path="./"

def convert_to_binary(num,data_width,fract_width):
	if num >= 0:
		num = num * (2**fract_width)
		num = int(num)
		res = num
	else:
		num=-num
		num=num*(2**fract_width)
		num=int(num)
		if num == 0:
			res = 0
		else:
			res = 2**data_width - num
	return res

def gen_weights_and_biases(data_width, weight_fract_width,bias_fract_width,weights,biases):
	weight_int_width = data_width- weight_fract_width
	bias_int_width = data_width - bias_fract_width
	# data_file = open(input_file,"r")
	weight_header_file = open(header_path + "weight_values.h","w")
	# data = data_file.read()
	# dictionary=json.loads(data)
	# weights = dictionary['weights']
	# biases = dictionary['biases']
	weight_header_file.write("int weightValues[]={")
	# try:
	for layer in range(0,len(weights)):
		for neuron in range(0,len(weights[layer])):
			fi = 'w_'+str(layer+1)+'_'+str(neuron)+'.mif'
			f = open(output_path+fi,'w')
			for weight in range(0,len(weights[layer][neuron])):
				if 'e' in str(weights[layer][neuron][weight]):
					p=0
				else:
					if weights[layer][neuron][weight] > 2**(weight_int_width-1):
						weights[layer][neuron][weight]= 2**(weight_int_width-1)-2**(-weight_fract_width)
					elif weights[layer][neuron][weight]<-2**(weight_int_width-1):
						weights[layer][neuron][weight]=-2**(weight_int_width-1)
					weight_in_decimal = convert_to_binary(weights[layer][neuron][weight],data_width,weight_fract_width)
					p=bin(weight_in_decimal)[2:]
				f.write(str(p)+'\n')
				weight_header_file.write(str(weight_in_decimal)+',')
			f.close()
	weight_header_file.write('0};\n')
	weight_header_file.close()
	# except:
		# print("Number of weights does not match with number of neurons\n")
	biases_header_file=open(header_path+"bias_values.h","w")
	biases_header_file.write("int biasValues[]={")
	try:
		for layer in range(0,len(biases)):
			for neuron in range(0,len(biases[layer])):
				fi='b_'+str(layer+1)+'_'+str(neuron)+'.mif'
				f=open(output_path+fi,"w")
				p=biases[layer][neuron][0]
				if 'e' in str(p):
					res = 0
				else:
					if p> 2**(bias_int_width-1):
						p=2**(bias_int_width-1)-2**(- bias_fract_width)
					elif p<-2**(bias_int_width):
						p=-2**(bias_int_width-1)
					bias_in_decimal=convert_to_binary(p,data_width,bias_fract_width)
					res=bin(bias_in_decimal)[2:]
				f.write(res)
				biases_header_file.write(str(bias_in_decimal)+',')
				f.close()
		biases_header_file.write('0};\n')
		biases_header_file.close()
	except:
		print("Number of biases does not match with number of neurons\n")