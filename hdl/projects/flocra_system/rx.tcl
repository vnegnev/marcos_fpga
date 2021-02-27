global adc_clk_freq
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_ADC
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_DDS_IQ
create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_RX_RATE
create_bd_pin -dir I rx_aresetn

cell xilinx.com:ip:axis_subset_converter:1.1 real_selector {
    S_TDATA_NUM_BYTES.VALUE_SRC USER
    M_TDATA_NUM_BYTES.VALUE_SRC USER
    S_TDATA_NUM_BYTES 2
    M_TDATA_NUM_BYTES 4
    TDATA_REMAP {16'b0, tdata[15:0]}
} {
    S_AXIS S_AXIS_ADC
	aclk /pll_0/clk_out1	
	aresetn /rst_0/peripheral_aresetn		
}

cell open-mri:user:complex_multiplier:1.0 mult_0 {
  OPERAND_WIDTH_A 16
  OPERAND_WIDTH_B 16
  OPERAND_WIDTH_OUT 32
  BLOCKING 0
  STAGES 3
  TRUNCATE 1  
} {
    S_AXIS_A real_selector/M_AXIS
    S_AXIS_B S_AXIS_DDS_IQ
	aclk /pll_0/clk_out1  
	aresetn rx_aresetn
}

# Create axis_broadcaster
cell xilinx.com:ip:axis_broadcaster:1.1 comb2iq {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 8
  M_TDATA_NUM_BYTES 4
  M00_TDATA_REMAP {tdata[31:0]}
  M01_TDATA_REMAP {tdata[63:32]}
  HAS_TREADY 0
} {
	S_AXIS mult_0/M_AXIS_DOUT
	aclk /pll_0/clk_out1  
	aresetn rx_aresetn
}

cell xilinx.com:ip:axis_broadcaster:1.1 rate {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 2
  M_TDATA_NUM_BYTES 2
  M00_TDATA_REMAP {tdata[15:0]}
  M01_TDATA_REMAP {tdata[15:0]}
  HAS_TREADY 0
} {
    S_AXIS S_AXIS_RX_RATE
	aclk /pll_0/clk_out1
	aresetn rx_aresetn	
}

cell open-mri:user:CIC:1.0 cic_real {
  INP_DW 32
  OUT_DW 32
  RATE_DW 16
  CIC_R 4095
  CIC_N 6
  CIC_M 1
  PRUNE_BITS 0x480000004500000044000000440000004300000042000000410000003c00000031000000270000001c000000100000000400000000
  VAR_RATE 1  
  EXACT_SCALING 1
  PRG_SCALING 0  
} {
    S_AXIS_RATE rate/M00_AXIS
    S_AXIS_IN comb2iq/M00_AXIS
	clk /pll_0/clk_out1  
	reset_n rx_aresetn	
}

# cell xilinx.com:ip:cic_compiler:4.0 cic_real {
  # INPUT_DATA_WIDTH.VALUE_SRC USER
  # FILTER_TYPE Decimation
  # NUMBER_OF_STAGES 6
  # SAMPLE_RATE_CHANGES Programmable
  # MINIMUM_RATE 4
  # MAXIMUM_RATE 4095
  # FIXED_OR_INITIAL_RATE 512
  # RATESPECIFICATION Sample_Period
  # SAMPLEPERIOD 1
  # INPUT_DATA_WIDTH 32
  # QUANTIZATION Truncation
  # OUTPUT_DATA_WIDTH 32
  # USE_XTREME_DSP_SLICE true
  # HAS_DOUT_TREADY false
  # HAS_ARESETN true
# } {
	# S_AXIS_DATA comb2iq/M00_AXIS
	# S_AXIS_CONFIG rate/M00_AXIS
	# aclk /pll_0/clk_out1  
	# aresetn rx_aresetn	
# }

cell open-mri:user:CIC:1.0 cic_imag {
  INP_DW 32
  OUT_DW 32
  RATE_DW 16
  CIC_R 4095
  CIC_N 6
  CIC_M 1
  PRUNE_BITS 0x480000004500000044000000440000004300000042000000410000003c00000031000000270000001c000000100000000400000000
  VAR_RATE 1
  EXACT_SCALING 1
  PRG_SCALING 0
} {
    S_AXIS_RATE rate/M01_AXIS
    S_AXIS_IN comb2iq/M01_AXIS
	clk /pll_0/clk_out1  
	reset_n rx_aresetn	
}

# cell xilinx.com:ip:cic_compiler:4.0 cic_imag {
  # INPUT_DATA_WIDTH.VALUE_SRC USER
  # FILTER_TYPE Decimation
  # NUMBER_OF_STAGES 6
  # SAMPLE_RATE_CHANGES Programmable
  # MINIMUM_RATE 4
  # MAXIMUM_RATE 4095
  # FIXED_OR_INITIAL_RATE 512
  # RATESPECIFICATION Sample_Period
  # SAMPLEPERIOD 1
  # INPUT_DATA_WIDTH 32
  # QUANTIZATION Truncation
  # OUTPUT_DATA_WIDTH 32
  # USE_XTREME_DSP_SLICE true
  # HAS_DOUT_TREADY false
  # HAS_ARESETN true
# } {
	# S_AXIS_DATA comb2iq/M01_AXIS
	# S_AXIS_CONFIG rate/M01_AXIS
	# aclk /pll_0/clk_out1
	# aresetn rx_aresetn 
# }

cell xilinx.com:ip:axis_combiner:1.1 comb_iqmerge {
  NUM_SI 2
  TDATA_NUM_BYTES 4
} {
    S00_AXIS cic_real/M_AXIS_OUT
    S01_AXIS cic_imag/M_AXIS_OUT
    aclk /pll_0/clk_out1
	aresetn rx_aresetn
}


