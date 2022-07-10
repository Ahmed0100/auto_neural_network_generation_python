create_project -in_memory -part [lindex $argv 0]
# set_param synth.vivado.inSynthRun true
set_property default_lib xil_defaultlib [current_project]
set_property target_language Verilog [current_project]

read_mem [glob ./proNet/w_b/*.mif]
read_verilog -library xil_defaultlib [glob ./proNet/src/rtl/*.v]
add_files -fileset sim_1 -norecurse ./proNet/src/tb/Top.v

set_property top proNet [current_fileset]
set_property top Top [get_filesets sim_1]

write_project_tcl -force -no_copy_sources -all_properties -use_bd_files {proNet.tcl}

#synth_design -quiet -top zyNet -part xc7z020clg484-1
#opt_design -quiet
#place_design -quiet
#route_design -quiet
#report_utilization -file utilization.log
#report_timing_summary -file timing.log
exit
