if {$part_variant=="Z20"} {
    set adc_clk_freq 122.88
    set adc_clk_freq_2x 245.76
    set rx_fifo_length 16384
    set marga_addr_width 19
    create_bd_port -dir I -from 15 -to 0 adc_dat_a_i
    create_bd_port -dir I -from 15 -to 0 adc_dat_b_i
} elseif {$part_variant=="Z10"} {
    create_bd_port -dir I -from 13 -to 0 adc_dat_a_i
    create_bd_port -dir I -from 13 -to 0 adc_dat_b_i
    set adc_clk_freq 125
    set adc_clk_freq_2x 250
    set rx_fifo_length 8192
    set marga_addr_width 18
} else {
    puts "Error: Unknown part variant!"
    exit 1
}

# probably don't need to be globals except rx_fifo_length
global adc_clk_freq
global adc_clk_freq_2x
global rx_fifo_length
global marga_addr_width
global dsp_source

# I/O ports
create_bd_port -dir I adc_clk_p_i
create_bd_port -dir I adc_clk_n_i

create_bd_port -dir O adc_enc_p_o
create_bd_port -dir O adc_enc_n_o

create_bd_port -dir O adc_csn_o

### DAC

create_bd_port -dir O -from 13 -to 0 dac_dat_o

create_bd_port -dir O dac_clk_o
create_bd_port -dir O dac_rst_o
create_bd_port -dir O dac_sel_o
create_bd_port -dir O dac_wrt_o

### PWM

create_bd_port -dir O -from 3 -to 0 dac_pwm_o

### XADC

create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vp_Vn
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux0
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux1
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux9
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux8

### LED

create_bd_port -dir O -from 7 -to 0 led_o

# Create clk_wiz
cell xilinx.com:ip:clk_wiz pll_0 {
    PRIMITIVE PLL
    PRIM_IN_FREQ.VALUE_SRC USER
    PRIM_IN_FREQ $adc_clk_freq
    PRIM_SOURCE Differential_clock_capable_pin
    CLKOUT1_USED true
    CLKOUT1_REQUESTED_OUT_FREQ $adc_clk_freq
    CLKOUT2_USED true
    CLKOUT2_REQUESTED_OUT_FREQ $adc_clk_freq_2x
    CLKOUT2_REQUESTED_PHASE -112.5
    CLKOUT3_USED true
    CLKOUT3_REQUESTED_OUT_FREQ $adc_clk_freq_2x
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


# Create proc_sys_reset
cell xilinx.com:ip:proc_sys_reset rst_0
connect_bd_net [get_bd_pins rst_0/ext_reset_in] [get_bd_pins ps_0/FCLK_RESET0_N]
connect_bd_net [get_bd_pins rst_0/slowest_sync_clk] [get_bd_pins pll_0/clk_out1]

cell xilinx.com:ip:xlconstant const_0

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
} else {
    puts "Error: Unknown part variant!"
    exit 1
}

cell xilinx.com:ip:axis_broadcaster:1.1 adc_ab {
    S_TDATA_NUM_BYTES.VALUE_SRC USER
    M_TDATA_NUM_BYTES.VALUE_SRC USER
    S_TDATA_NUM_BYTES 4
    M_TDATA_NUM_BYTES 2
    M00_TDATA_REMAP {tdata[15:0]}
    M01_TDATA_REMAP {tdata[31:16]}
    HAS_TREADY 0
} {
    S_AXIS adc_0/M_AXIS
    aclk /pll_0/clk_out1
    aresetn /rst_0/peripheral_aresetn
}

cell open-mri:user:marga:1.0 marga {
    RX_FIFO_LENGTH $rx_fifo_length
    C_S0_AXI_ADDR_WIDTH $marga_addr_width
} {
    s0_axi_aclk pll_0/clk_out1
    s0_axi_aresetn rst_0/peripheral_aresetn
}
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
    Master {/ps_0/M_AXI_GP0}
    Slave {/marga/S0_AXI}
} [get_bd_intf_pins marga/S0_AXI]

set_property RANGE 512K [get_bd_addr_segs ps_0/Data/SEG_marga_reg0]
set_property OFFSET 0x43C00000 [get_bd_addr_segs ps_0/Data/SEG_marga_reg0]

module rx_0 {
    source projects/marcos_fpga/rx.tcl
} {
    S_AXIS_ADC adc_ab/M00_AXIS
    comb_iqmerge/M_AXIS marga/RX0_AXIS
    S_AXIS_RX_RATE marga/RX0_RATE_AXIS
    S_AXIS_DDS_IQ marga/RX0_DDS_IQ_AXIS
    rx_aresetn marga/rx0_rst_n_o
}

module rx_1 {
    source projects/marcos_fpga/rx.tcl
} {
    S_AXIS_ADC adc_ab/M01_AXIS
    comb_iqmerge/M_AXIS marga/RX1_AXIS
    S_AXIS_RX_RATE marga/RX1_RATE_AXIS
    S_AXIS_DDS_IQ marga/RX1_DDS_IQ_AXIS
    rx_aresetn marga/rx1_rst_n_o
}

if {$dsp_source=="OPENSOURCE"} {
    module tx_0 {
	source projects/marcos_fpga/tx.tcl
    } {
	bcast_nco0/M01_AXIS marga/DDS0_IQ_AXIS
	bcast_nco1/M01_AXIS marga/DDS1_IQ_AXIS
	tx2_nco/M_AXIS_OUT marga/DDS2_IQ_AXIS
    }
} elseif {$dsp_source=="XILINX"} {
    module tx_0 {
	source projects/marcos_fpga/tx.tcl
    } {
	bcast_nco0/M01_AXIS marga/DDS0_IQ_AXIS
	bcast_nco1/M01_AXIS marga/DDS1_IQ_AXIS
	tx2_nco/M_AXIS_DATA marga/DDS2_IQ_AXIS
    }
}


# hook up the event pulses to something
#

# LEDs, using the LSB as a clock lock status
cell xilinx.com:ip:xlslice:1.0 led_slice {
    DIN_FROM 7
    DIN_TO 1
    DIN_WIDTH 8
    # DOUT_WIDTH 7 # might not need this
} {
    Din marga/leds_o
}
cell xilinx.com:ip:xlconcat:2.1 led_concat {
    NUM_PORTS 2
    IN0_WIDTH 7
    IN1_WIDTH 1
} {
    In0 led_slice/Dout
    In1 pll_0/locked
}

connect_bd_net [get_bd_pins led_concat/dout] [get_bd_ports led_o]

cell xilinx.com:ip:xlconcat:2.1 spi_concat_0 {
    NUM_PORTS 7
} {
    In0 marga/ocra1_clk_o
    In1 marga/ocra1_syncn_o
    In2 marga/ocra1_ldacn_o
    In3 marga/ocra1_sdox_o
    In4	marga/ocra1_sdoy_o
    In5 marga/ocra1_sdoz_o
    In6 marga/ocra1_sdoz2_o
}

# Expansion connector
create_bd_port -dir O -from 7 -to 0 exp_p_tri_io
create_bd_port -dir O -from 7 -to 0 exp_n_tri_io
create_bd_port -dir I -type data exp_p_tri_io_i

cell xilinx.com:ip:xlconcat:2.1 pio_concat_0 {
    NUM_PORTS 6
} {
    In2 marga/trig_o
    In3 marga/fhdo_clk_o
    In4 marga/fhdo_ssn_o
    In5 marga/fhdo_sdo_o
}

connect_bd_net [get_bd_pins exp_p_tri_io_i] [get_bd_pins marga/fhdo_sdi_i]

cell xilinx.com:ip:xlconcat:2.1 nio_concat_0 {
    NUM_PORTS 2
}
connect_bd_net [get_bd_pins nio_concat_0/In0] [get_bd_pins spi_concat_0/dout]
connect_bd_net [get_bd_pins nio_concat_0/In1] [get_bd_pins marga/tx_gate_o]

create_bd_port -dir O -type data rx_gate_o
connect_bd_net [get_bd_ports rx_gate_o] [get_bd_pins marga/rx_gate_o]

# clock forward
cell xilinx.com:ip:oddr:1.0 oddr_0
connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins oddr_0/clk_in]

cell xilinx.com:ip:util_ds_buf:2.1 ext_clk_0_buf {
    C_BUF_TYPE OBUFDS
}
create_bd_port -dir O -type clk ext_clk_0_p_o
create_bd_port -dir O -type clk ext_clk_0_n_o
connect_bd_net [get_bd_pins oddr_0/clk_out] [get_bd_pins ext_clk_0_buf/OBUF_IN]
connect_bd_net [get_bd_pins ext_clk_0_buf/OBUF_DS_P] [get_bd_ports ext_clk_0_p_o]
connect_bd_net [get_bd_pins ext_clk_0_buf/OBUF_DS_N] [get_bd_ports ext_clk_0_n_o]

create_bd_port -dir I -type data trig_i
connect_bd_net [get_bd_ports trig_i] [get_bd_pins marga/trig_i]
connect_bd_net [get_bd_pins exp_n_tri_io] [get_bd_pins nio_concat_0/Dout]
connect_bd_net [get_bd_pins exp_p_tri_io] [get_bd_pins pio_concat_0/Dout]

if {$part_variant=="Z20"} {
    create_bd_port -dir O -type data trig_p_o
    connect_bd_net [get_bd_pins marga/trig_o] [get_bd_ports trig_p_o]
} elseif {$part_variant=="Z10"} {
    # Not enough pins on Z10 for trigger output
} else {
    puts "Error: Unknown part variant!"
    exit 1
}
