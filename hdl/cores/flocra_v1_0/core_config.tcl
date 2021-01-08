set display_name {FLOCRA}

set core [ipx::current_core]

set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core

core_parameter C_S0_AXI_DATA_WIDTH {S0 AXI DATA WIDTH} {Width of the AXI data bus.}
core_parameter C_S0_AXI_ADDR_WIDTH {S0 AXI ADDR WIDTH} {Width of the AXI address bus.}

set bus [ipx::get_bus_interfaces -of_objects $core dds0_phase_axis_o]
set_property NAME DDS0_PHASE_AXIS $bus
set_property INTERFACE_MODE master $bus

set bus [ipx::get_bus_interfaces -of_objects $core dds1_phase_axis_o]
set_property NAME DDS1_PHASE_AXIS $bus
set_property INTERFACE_MODE master $bus

set bus [ipx::get_bus_interfaces -of_objects $core dds2_phase_axis_o]
set_property NAME DDS2_PHASE_AXIS $bus
set_property INTERFACE_MODE master $bus

set bus [ipx::get_bus_interfaces -of_objects $core rx0_rate_axis_o]
set_property NAME RX0_RATE_AXIS $bus
set_property INTERFACE_MODE master $bus

set bus [ipx::get_bus_interfaces -of_objects $core rx1_rate_axis_o]
set_property NAME RX1_RATE_AXIS $bus
set_property INTERFACE_MODE master $bus

set bus [ipx::get_bus_interfaces -of_objects $core rx0_axis_i]
set_property NAME RX0_AXIS $bus
set_property INTERFACE_MODE slave $bus

set bus [ipx::get_bus_interfaces -of_objects $core rx1_axis_i]
set_property NAME RX1_AXIS $bus
set_property INTERFACE_MODE slave $bus

set bus [ipx::get_bus_interfaces -of_objects $core dds0_iq_axis_i]
set_property NAME DDS0_IQ_AXIS $bus
set_property INTERFACE_MODE slave $bus

set bus [ipx::get_bus_interfaces -of_objects $core dds1_iq_axis_i]
set_property NAME DDS1_IQ_AXIS $bus
set_property INTERFACE_MODE slave $bus

set bus [ipx::get_bus_interfaces -of_objects $core dds2_iq_axis_i]
set_property NAME DDS2_IQ_AXIS $bus
set_property INTERFACE_MODE slave $bus

set bus [ipx::get_bus_interfaces -of_objects $core rx0_dds_iq_axis_o]
set_property NAME RX0_DDS_IQ_AXIS $bus
set_property INTERFACE_MODE master $bus

set bus [ipx::get_bus_interfaces -of_objects $core rx1_dds_iq_axis_o]
set_property NAME RX1_DDS_IQ_AXIS $bus
set_property INTERFACE_MODE master $bus

set bus [ipx::get_bus_interfaces -of_objects $core tx0_axis_o]
set_property NAME TX0_AXIS $bus
set_property INTERFACE_MODE master $bus

set bus [ipx::get_bus_interfaces -of_objects $core tx1_axis_o]
set_property NAME TX1_AXIS $bus
set_property INTERFACE_MODE master $bus

set bus [ipx::get_bus_interfaces -of_objects $core s0_axi]
set_property NAME S0_AXI $bus
set_property INTERFACE_MODE slave $bus


# associate clk to AXI busses
set bus [ipx::get_bus_interfaces s0_axi_aclk]
set parameter [ipx::get_bus_parameters -of_objects $bus ASSOCIATED_BUSIF]
set_property VALUE DDS0_PHASE_AXIS:DDS1_PHASE_AXIS:DDS2_PHASE_AXIS:RX0_RATE_AXIS:RX1_RATE_AXIS:RX0_AXIS:RX1_AXIS:DDS0_IQ_AXIS:DDS1_IQ_AXIS:DDS2_IQ_AXIS:RX0_DDS_IQ_AXIS:RX1_DDS_IQ_AXIS:TX0_AXIS:TX1_AXIS:S0_AXI $parameter
