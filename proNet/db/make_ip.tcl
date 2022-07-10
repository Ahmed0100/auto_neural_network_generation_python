open_project [lindex $argv 0]
ipx::package_project -root_dir ./proNet/src -vendor VIP -library user -taxonomy /user_ip
ipx::add_bus_interface axis_data [ipx::current_core]

set_property abstraction_type_vlnv xilinx.com:interface:axis_rtl:1.0 [ipx::get_bus_interfaces axis_data -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com.interface:axis:1.0 [ipx::get_bus_interfaces axis_data -of_objects [ipx::current_core]]

ipx::add_port_map TVALID [ipx::get_bus_interfaces axis_data -of_objects [ipx::current_core]]
set_property physical_name axis_data_in_valid [ipx::get_port_maps TVALID -of_objects [ipx::get_bus_interfaces axis_data -of_objects [ipx::current_core]]]

ipx::add_port_map TREADY [ipx::get_bus_interfaces axis_data -of_objects [ipx::current_core]]
set_property physical_name axis_data_in_ready [ipx::get_port_maps TREADY -of_objects [ipx::get_bus_interfaces axis_data -of_objects [ipx::current_core]]]

ipx::add_port_map TDATA [ipx::get_bus_interfaces axis_data -of_objects [ipx::current_core]]
set_property physical_name axis_data_in [ipx::get_port_maps TDATA -of_objects [ipx::get_bus_interfaces axis_data -of_objects [ipx::current_core]]]

set_property core_revision 1 [ipx::current_core]
set_property value s_axi_axis_data [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces clk -of_objects [ipx::current_core]]]

ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
update_ip_catalog
exit