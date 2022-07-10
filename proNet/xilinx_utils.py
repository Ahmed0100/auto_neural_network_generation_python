from os import system
from os import path

def make_vivado_project(project_name='my_project',fpga_part="xc7z020clg484-1"):
	system("C:Xilinx\\Vivado\\2018.3\\bin\\vivado -mode tcl -source "+'./proNet/db/vivado_script.tcl'+" -tclargs "+fpga_part)
	f=open("proNet.tcl","a")
	f.write("\nset_property source_mgmt_mode All [current_project]")
	f.write("\nexit")
	f.close()
	system("C:Xilinx\\Vivado\\2018.3\\bin\\vivado -mode tcl -source proNet.tcl -tclargs --project_name "+project_name)

def make_ip(project_name='my_project'):
	system("C:Xilinx\\Vivado\\2018.3\\bin\\vivado -mode tcl -source "+"./proNet/db/make_ip.tcl"+" -tclargs "+project_name)