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

module rx_0 {
  source projects/flocra_system/rx.tcl
} {
}

module rx_1 {
  source projects/flocra_system/rx.tcl
} {
}

module tx_0 {
  source projects/flocra_system/tx.tcl
} {
}

cell open-mri:user:flocra:1.0 flocra {
} {
}



# hook up the event pulses to something
#

# the LEDs
connect_bd_net [get_bd_ports led_o] [get_bd_pins flocra/leds_o]


cell xilinx.com:ip:xlconcat:2.1 spi_concat_0 {
    NUM_PORTS 7
} {
	In0 flocra/oc1_clk_o
	In1 flocra/oc1_syncn_o
	In2 flocra/oc1_ldacn_o
	In3 flocra/oc1_sdox_o
	In4	flocra/oc1_sdoy_o
	In5 flocra/oc1_sdoz_o
	In6 flocra/oc1_sdoz2_o
}



# connect the tx_offset
# connect_bd_net [get_bd_pins micro_sequencer/tx_offset] [get_bd_pins tx_0/reader_0/current_offset]

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

cell xilinx.com:ip:xlconcat:2.1 pio_concat_0 {
    NUM_PORTS 6
} {
	In3 flocra/fhdo_clk_o
	In4 flocra/fhdo_ssn_o
	In5 flocra/fhdo_sdo_o
}

# Concat with the gradient DAC slice
cell xilinx.com:ip:xlconcat:2.1 nio_concat_0 {
    NUM_PORTS 2
}
connect_bd_net [get_bd_pins nio_concat_0/In0] [get_bd_pins spi_concat_0/dout]
connect_bd_net [get_bd_pins nio_concat_0/In1] [get_bd_pins flocra/tx_gate_o]



# connect to pins
connect_bd_net [get_bd_pins exp_n_tri_io] [get_bd_pins nio_concat_0/Dout]
connect_bd_net [get_bd_pins exp_p_tri_io] [get_bd_pins pio_concat_0/Dout]



