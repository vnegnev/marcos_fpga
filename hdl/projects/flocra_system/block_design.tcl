if {$part_variant=="Z20"} {
	set adc_clk_freq 122.88
} elseif {$part_variant=="Z10"} {
	set adc_clk_freq 125
}
global adc_clk_freq

# Create clk_wiz
cell xilinx.com:ip:clk_wiz pll_0 {
  PRIMITIVE PLL
  PRIM_IN_FREQ.VALUE_SRC USER
  PRIM_IN_FREQ $adc_clk_freq
  PRIM_SOURCE Differential_clock_capable_pin
  CLKOUT1_USED true
  CLKOUT1_REQUESTED_OUT_FREQ $adc_clk_freq
  CLKOUT2_USED true
  CLKOUT2_REQUESTED_OUT_FREQ 245.76
  CLKOUT2_REQUESTED_PHASE -112.5
  CLKOUT3_USED true
  CLKOUT3_REQUESTED_OUT_FREQ 245.76
  CLKOUT3_REQUESTED_PHASE -67.5    
  USE_RESET false
} {
  clk_in1_p adc_clk_p_i
  clk_in1_n adc_clk_n_i
}

# Create processing_system7
cell xilinx.com:ip:processing_system7 ps_0 {
  PCW_IMPORT_BOARD_PRESET cfg/stemlab_sdr.xml
} {
  M_AXI_GP0_ACLK pll_0/clk_out1
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {
  make_external {FIXED_IO, DDR}
  Master Disable
  Slave Disable
} [get_bd_cells ps_0]

# Create xlconstant
cell xilinx.com:ip:xlconstant const_0

# Create proc_sys_reset
cell xilinx.com:ip:proc_sys_reset rst_0 
connect_bd_net [get_bd_pins rst_0/ext_reset_in] [get_bd_pins ps_0/FCLK_RESET0_N]

# ADC
if {$part_variant=="Z20"} {
	# Create axis_stemlab_sdr_adc
	cell pavel-demin:user:axis_stemlab_sdr_adc adc_0 {
	  ADC_DATA_WIDTH 16
	} {
	  aclk pll_0/clk_out1
	  adc_dat_a adc_dat_a_i
	  adc_dat_b adc_dat_b_i
	  adc_csn adc_csn_o
	}

	# Create axis_stemlab_sdr_dac
	cell pavel-demin:user:axis_stemlab_sdr_dac dac_0 {
	  DAC_DATA_WIDTH 14
	} {
	  aclk pll_0/clk_out1
	  ddr_clk pll_0/clk_out2
	  wrt_clk pll_0/clk_out3    
	  locked pll_0/locked
	  dac_clk dac_clk_o
	  dac_rst dac_rst_o
	  dac_sel dac_sel_o
	  dac_wrt dac_wrt_o
	  dac_dat dac_dat_o
	  s_axis_tvalid const_0/dout    
	}
} elseif {$part_variant=="Z10"} {
	# Create axis_red_pitaya_adc
	cell pavel-demin:user:axis_red_pitaya_adc:2.0 adc_0 {} {
	  aclk pll_0/clk_out1
	  adc_dat_a adc_dat_a_i
	  adc_dat_b adc_dat_b_i
	  adc_csn adc_csn_o
	}

	# Create axis_red_pitaya_dac
	cell pavel-demin:user:axis_red_pitaya_dac:1.0 dac_0 {} {
	  aclk pll_0/clk_out1
	  ddr_clk pll_0/clk_out2
	  locked pll_0/locked
	  dac_clk dac_clk_o
	  dac_rst dac_rst_o
	  dac_sel dac_sel_o
	  dac_wrt dac_wrt_o
	  dac_dat dac_dat_o
	}
}

# Create axi_cfg_register
cell pavel-demin:user:axi_cfg_register cfg_0 {
  CFG_DATA_WIDTH 128
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 txinterpolator_slice_0 {
  DIN_WIDTH 128 DIN_FROM 31 DIN_TO 0 DOUT_WIDTH 32
} {
  Din cfg_0/cfg_data
}

# Create xlslice
#cell xilinx.com:ip:xlslice:1.0 rst_slice_1 {
#  DIN_WIDTH 128 DIN_FROM 15 DIN_TO 8 DOUT_WIDTH 8
#} {
#  Din cfg_0/cfg_data
#}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 cfg_slice_0 {
  DIN_WIDTH 128 DIN_FROM 95 DIN_TO 32 DOUT_WIDTH 64
} {
  Din cfg_0/cfg_data
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 cfg_slice_1 {
  DIN_WIDTH 128 DIN_FROM 127 DIN_TO 96 DOUT_WIDTH 32
} {
  Din cfg_0/cfg_data
}

# Create Memory for pulse sequence
cell xilinx.com:ip:blk_mem_gen:8.4 sequence_memory {
  MEMORY_TYPE Simple_Dual_Port_RAM
  USE_BRAM_BLOCK Stand_Alone
  WRITE_WIDTH_A 32
  WRITE_DEPTH_A 16384
  WRITE_WIDTH_B 64
  ENABLE_A Always_Enabled
  ENABLE_B Always_Enabled
  REGISTER_PORTB_OUTPUT_OF_MEMORY_PRIMITIVES false
}


# Create microsequencer
cell open-mri:user:micro_sequencer:1.0 micro_sequencer {
  C_S_AXI_DATA_WIDTH 32
  C_S_AXI_ADDR_WIDTH 32
  BRAM_DATA_WIDTH 64
  BRAM_ADDR_WIDTH 13
} {
  BRAM_PORTA sequence_memory/BRAM_PORTB
}


# Removed these connections from rx:
# slice_0/Din
# rst_slice_0/Dout
module rx_0 {
  source projects/ocra_mri/rx.tcl
} {
  rate_slice/Din cfg_slice_0/Dout
  mult_0/S_AXIS_A adc_0/M_AXIS
  mult_0/aclk pll_0/clk_out1
}

#  axis_interpolator_0/cfg_data txinterpolator_slice_0/Dout  
module tx_0 {
  source projects/ocra_mri/tx.tcl
} {
  slice_1/Din cfg_slice_1/Dout
  axis_interpolator_0/cfg_data txinterpolator_slice_0/Dout
  real_0/M_AXIS dac_0/S_AXIS
}

module nco_0 {
    source projects/ocra_mri/nco.tcl
} {
  slice_1/Din cfg_slice_0/Dout
  bcast_nco/M00_AXIS rx_0/mult_0/S_AXIS_B
  bcast_nco/M01_AXIS tx_0/mult_0/S_AXIS_B
  dds_nco/aresetn micro_sequencer/hf_reset
}

# Create axi_sts_register
cell pavel-demin:user:axi_sts_register:1.0 sts_0 {
  STS_DATA_WIDTH 32
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
} {
  sts_data rx_0/fifo_generator_0/rd_data_count
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins cfg_0/S_AXI]

set_property RANGE 4K [get_bd_addr_segs ps_0/Data/SEG_cfg_0_reg0]
set_property OFFSET 0x40000000 [get_bd_addr_segs ps_0/Data/SEG_cfg_0_reg0]

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins sts_0/S_AXI]

set_property RANGE 4K [get_bd_addr_segs ps_0/Data/SEG_sts_0_reg0]
set_property OFFSET 0x40001000 [get_bd_addr_segs ps_0/Data/SEG_sts_0_reg0]

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins rx_0/reader_0/S_AXI]

set_property RANGE 64K [get_bd_addr_segs ps_0/Data/SEG_reader_0_reg0]
set_property OFFSET 0x40010000 [get_bd_addr_segs ps_0/Data/SEG_reader_0_reg0]

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins tx_0/writer_0/S_AXI]

set_property RANGE 64K [get_bd_addr_segs ps_0/Data/SEG_writer_0_reg0]
set_property OFFSET 0x40020000 [get_bd_addr_segs ps_0/Data/SEG_writer_0_reg0]


# Load some initial data to the memory
#set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {/home/red-pitaya/red-pitaya-notes.old/test.coe}] [get_bd_cells sequence_memory]

# Create axi_bram_writer for pulse sequence
cell pavel-demin:user:axi_bram_writer:1.0 sequence_writer {
  AXI_DATA_WIDTH 32
  AXI_ADDR_WIDTH 32
  BRAM_DATA_WIDTH 32
  BRAM_ADDR_WIDTH 14
} {
  BRAM_PORTA sequence_memory/BRAM_PORTA
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins sequence_writer/S_AXI]

set_property RANGE 64K [get_bd_addr_segs ps_0/Data/SEG_sequence_writer_reg0]
set_property OFFSET 0x40030000 [get_bd_addr_segs ps_0/Data/SEG_sequence_writer_reg0]


# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins micro_sequencer/S_AXI]

set_property RANGE 64K [get_bd_addr_segs ps_0/Data/SEG_micro_sequencer_reg0]
set_property OFFSET 0x40040000 [get_bd_addr_segs ps_0/Data/SEG_micro_sequencer_reg0]

cell xilinx.com:ip:xlconcat:2.1 pio_concat_0 {
    NUM_PORTS 6
}

# Create RF attenuator
cell open-mri:user:axi_serial_attenuator:1.0 serial_attenuator {
  C_S_AXI_DATA_WIDTH 32
  C_S_AXI_ADDR_WIDTH 16
} {
	attn_clk pio_concat_0/In0
	attn_serial pio_concat_0/In1
	attn_le pio_concat_0/In2
}

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins serial_attenuator/S_AXI]
set_property RANGE 64K [get_bd_addr_segs ps_0/Data/SEG_serial_attenuator_reg0]
set_property OFFSET 0x40050000 [get_bd_addr_segs ps_0/Data/SEG_serial_attenuator_reg0]


#
# hook up the event pulses to something
#

# the LEDs
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xled_slice_0
set_property -dict [list CONFIG.DIN_WIDTH {64} CONFIG.DIN_TO {8} CONFIG.DIN_FROM {15} CONFIG.DOUT_WIDTH {8}] [get_bd_cells xled_slice_0]
connect_bd_net [get_bd_pins micro_sequencer/pulse] [get_bd_pins xled_slice_0/Din]
connect_bd_net [get_bd_ports led_o] [get_bd_pins xled_slice_0/Dout]

# the transmit trigger pulse
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 trigger_slice_0
set_property -dict [list CONFIG.DIN_WIDTH {64} CONFIG.DIN_FROM {7} CONFIG.DIN_TO {0} CONFIG.DOUT_WIDTH {8}] [get_bd_cells trigger_slice_0]
connect_bd_net [get_bd_pins micro_sequencer/pulse] [get_bd_pins trigger_slice_0/Din]
connect_bd_net [get_bd_pins trigger_slice_0/Dout] [get_bd_pins tx_0/slice_0/Din]
connect_bd_net [get_bd_pins trigger_slice_0/Dout] [get_bd_pins rx_0/slice_0/Din]

# Gradient Core
create_bd_port -dir I -type data exp_p_tri_io_i

create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 grad_bram_enb_slice
set_property -dict [list CONFIG.DIN_WIDTH {8} CONFIG.DIN_TO {2} CONFIG.DIN_FROM {2} CONFIG.DOUT_WIDTH {1}] [get_bd_cells grad_bram_enb_slice]
connect_bd_net [get_bd_pins grad_bram_enb_slice/Din] [get_bd_pins trigger_slice_0/Dout]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 grad_bram_offset_slice
set_property -dict [list CONFIG.DIN_WIDTH {16} CONFIG.DIN_TO {0} CONFIG.DIN_FROM {13} CONFIG.DOUT_WIDTH {14}] [get_bd_cells grad_bram_offset_slice]
connect_bd_net [get_bd_pins grad_bram_offset_slice/Din] [get_bd_pins micro_sequencer/grad_offset]


cell open-mri:user:flocra_grad_ctrl:1.0 flocra_grad_ctrl {
  C_S00_AXI_DATA_WIDTH 32
  C_S00_AXI_ADDR_WIDTH 16
  C_S_AXI_INTR_DATA_WIDTH 32
  C_S_AXI_INTR_ADDR_WIDTH 5
} {
grad_bram_offset_i grad_bram_offset_slice/Dout
grad_bram_enb_i grad_bram_enb_slice/Dout
fhd_sdi_i exp_p_tri_io_i
s00_axi_aclk pll_0/clk_out1
s00_axi_aresetn rst_0/peripheral_aresetn
s_axi_intr_aclk pll_0/clk_out1
s_axi_intr_aresetn rst_0/peripheral_aresetn
fhd_clk_o pio_concat_0/In3
fhd_sdo_o pio_concat_0/In5
fhd_ssn_o pio_concat_0/In4
}
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {  Master {/ps_0/M_AXI_GP0} Slave {/flocra_grad_ctrl/s00_axi} }  [get_bd_intf_pins flocra_grad_ctrl/s00_axi]

set_property range 1M [get_bd_addr_segs {ps_0/Data/SEG_flocra_grad_ctrl_reg0}]
set_property offset 0x40100000 [get_bd_addr_segs {ps_0/Data/SEG_flocra_grad_ctrl_reg0}]

cell xilinx.com:ip:xlconcat:2.1 spi_concat_0 {
    NUM_PORTS 7
} {
	In0 flocra_grad_ctrl/oc1_clk_o
	In1 flocra_grad_ctrl/oc1_syncn_o
	In2 flocra_grad_ctrl/oc1_ldacn_o
	In3 flocra_grad_ctrl/oc1_sdox_o
	In4	flocra_grad_ctrl/oc1_sdoy_o
	In5 flocra_grad_ctrl/oc1_sdoz_o
	In6 flocra_grad_ctrl/oc1_sdoz2_o
}



# connect the tx_offset
connect_bd_net [get_bd_pins micro_sequencer/tx_offset] [get_bd_pins tx_0/reader_0/current_offset]

# TW add one output register stage
set_property -dict [list CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Register_PortB_Output_of_Memory_Core {false}] [get_bd_cells sequence_memory]

#
# try to connect the bottom 8 bits of the pulse output of the sequencer to the positive gpoi
#
# Delete input/output port
delete_bd_objs [get_bd_ports exp_p_tri_io]
delete_bd_objs [get_bd_ports exp_n_tri_io]

# Create newoutput port
create_bd_port -dir O -from 7 -to 0 exp_p_tri_io
#connect_bd_net [get_bd_pins exp_p_tri_io] [get_bd_pins trigger_slice_0/Dout]

# Create output port for the SPI stuff
create_bd_port -dir O -from 7 -to 0 exp_n_tri_io

# 09/2019: For the new board we are doing this differently. The SPI bus will use seven pins on the n side of the header
#          and the txgate will use the eight' pin on the n side

# Slice the txgate off the microsequencer pulse word. I'm torn on style here, but the trigger slice is almost obsolete,
# so its easier to not use it
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 txgate_slice_0
set_property -dict [list CONFIG.DIN_WIDTH {64} CONFIG.DIN_FROM {4} CONFIG.DIN_TO {4} CONFIG.DOUT_WIDTH {1}] [get_bd_cells txgate_slice_0]
connect_bd_net [get_bd_pins micro_sequencer/pulse] [get_bd_pins txgate_slice_0/Din]


# Concat with the gradient DAC slice
cell xilinx.com:ip:xlconcat:2.1 nio_concat_0 {
    NUM_PORTS 2
}
connect_bd_net [get_bd_pins nio_concat_0/In1] [get_bd_pins txgate_slice_0/Dout]
connect_bd_net [get_bd_pins spi_concat_0/dout] [get_bd_pins nio_concat_0/In0]

# connect to pins
connect_bd_net [get_bd_pins exp_n_tri_io] [get_bd_pins nio_concat_0/Dout]
connect_bd_net [get_bd_pins exp_p_tri_io] [get_bd_pins pio_concat_0/Dout]



