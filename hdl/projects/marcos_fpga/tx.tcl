

cell open-mri:user:complex_multiplier:1.0 mult_0 {
  OPERAND_WIDTH_A 16
  OPERAND_WIDTH_B 16
  OPERAND_WIDTH_OUT 16
  BLOCKING 0
  STAGES 6
  ROUND_MODE 1
} {
    S_AXIS_A /flocra/TX0_AXIS
    aclk /pll_0/clk_out1
	aresetn /rst_0/peripheral_aresetn  
}

cell open-mri:user:complex_multiplier:1.0 mult_1 {
  OPERAND_WIDTH_A 16
  OPERAND_WIDTH_B 16
  OPERAND_WIDTH_OUT 16
  BLOCKING 0
  STAGES 6
  ROUND_MODE 1
} {
    S_AXIS_A /flocra/TX1_AXIS
	aclk /pll_0/clk_out1
	aresetn /rst_0/peripheral_aresetn
}

# extract the real component of the product using a broadcaster in to I and Q
# a simpler alternative would be to use a axis_subset_converter
cell xilinx.com:ip:axis_subset_converter:1.1 real_0 {
    S_TDATA_NUM_BYTES.VALUE_SRC USER
    M_TDATA_NUM_BYTES.VALUE_SRC USER
    S_TDATA_NUM_BYTES 4
    M_TDATA_NUM_BYTES 2
    TDATA_REMAP {tdata[15:0]}
} {
    S_AXIS mult_0/M_AXIS_DOUT
	aclk /pll_0/clk_out1
	aresetn /rst_0/peripheral_aresetn	
}

cell xilinx.com:ip:axis_subset_converter:1.1 real_1 {
    S_TDATA_NUM_BYTES.VALUE_SRC USER
    M_TDATA_NUM_BYTES.VALUE_SRC USER
    S_TDATA_NUM_BYTES 4
    M_TDATA_NUM_BYTES 2
    TDATA_REMAP {tdata[15:0]}
} {
    S_AXIS mult_1/M_AXIS_DOUT
	aclk /pll_0/clk_out1	
	aresetn /rst_0/peripheral_aresetn		
}


cell xilinx.com:ip:axis_combiner:1.1 axis_combiner_0 {
  NUM_SI 2
  TDATA_NUM_BYTES 2
} {
    S00_AXIS real_0/M_AXIS
    S01_AXIS real_1/M_AXIS
	aclk /pll_0/clk_out1	
	aresetn /rst_0/peripheral_aresetn		
}

cell xilinx.com:ip:axis_subset_converter:1.1 dac_truncator {
    S_TDATA_NUM_BYTES.VALUE_SRC USER
    M_TDATA_NUM_BYTES.VALUE_SRC USER
    S_TDATA_NUM_BYTES 4
    M_TDATA_NUM_BYTES 4
    TDATA_REMAP {2'b00, tdata[30:17], 2'b00, tdata[14:1]}
} {
    M_AXIS /dac_0/S_AXIS
    S_AXIS axis_combiner_0/M_AXIS
	aclk /pll_0/clk_out1	
	aresetn /rst_0/peripheral_aresetn		
}


# DDS
# cell open-mri:user:DDS:1.0 tx0_nco {
    # PHASE_DW 24
    # OUT_DW 16
    # USE_TAYLOR 1
    # LUT_DW 9
    # SIN_COS 1
    # NEGATIVE_SINE 1
# } {
    # clk /pll_0/clk_out1
    # S_AXIS_PHASE /flocra/DDS0_PHASE_AXIS
	# reset_n /rst_0/peripheral_aresetn	    
# }

cell xilinx.com:ip:dds_compiler:6.0 tx0_nco {
    PartsPresent SIN_COS_LUT_only
    Noise_Shaping Taylor_Series_Corrected
    PHASE_WIDTH 24
    OUTPUT_WIDTH 16
    Memory_Type Auto
    Has_Phase_Out false
    DSP48_USE Minimal
    NEGATIVE_SINE true
} {
    aclk /pll_0/clk_out1
    S_AXIS_PHASE /flocra/DDS0_PHASE_AXIS
}

# cell open-mri:user:DDS:1.0 tx1_nco {
    # PHASE_DW 24
    # OUT_DW 16
    # USE_TAYLOR 1
    # LUT_DW 9
    # SIN_COS 1
    # NEGATIVE_SINE 1
# } {
    # clk /pll_0/clk_out1
    # S_AXIS_PHASE /flocra/DDS1_PHASE_AXIS
	# reset_n /rst_0/peripheral_aresetn	    
# }

cell xilinx.com:ip:dds_compiler:6.0 tx1_nco {
    PartsPresent SIN_COS_LUT_only
    Noise_Shaping Taylor_Series_Corrected
    PHASE_WIDTH 24
    OUTPUT_WIDTH 16
    Memory_Type Auto
    Has_Phase_Out false
    DSP48_USE Minimal
    NEGATIVE_SINE true
} {
    aclk /pll_0/clk_out1
    S_AXIS_PHASE /flocra/DDS1_PHASE_AXIS
}

cell xilinx.com:ip:dds_compiler:6.0 tx2_nco {
    PartsPresent SIN_COS_LUT_only
    Noise_Shaping Taylor_Series_Corrected
    PHASE_WIDTH 24
    OUTPUT_WIDTH 16
    Memory_Type Auto
    Has_Phase_Out false
    DSP48_USE Minimal
    NEGATIVE_SINE true
} {
    aclk /pll_0/clk_out1
    S_AXIS_PHASE /flocra/DDS2_PHASE_AXIS
}

# cell xilinx.com:ip:axis_broadcaster:1.1 bcast_nco0 {
  # NUM_MI 2
  # S_TDATA_NUM_BYTES.VALUE_SRC USER
  # M_TDATA_NUM_BYTES.VALUE_SRC USER
  # S_TDATA_NUM_BYTES 4
  # M_TDATA_NUM_BYTES 4
  # M00_TDATA_REMAP {tdata[31:0]}
  # M01_TDATA_REMAP {tdata[31:0]}
  # HAS_TREADY 0
# } {
    # M00_AXIS mult_0/S_AXIS_B
    # S_AXIS tx0_nco/M_AXIS_OUT
	# aclk /pll_0/clk_out1	
	# aresetn /rst_0/peripheral_aresetn		
# }

# cell xilinx.com:ip:axis_broadcaster:1.1 bcast_nco1 {
  # NUM_MI 2
  # S_TDATA_NUM_BYTES.VALUE_SRC USER
  # M_TDATA_NUM_BYTES.VALUE_SRC USER
  # S_TDATA_NUM_BYTES 4
  # M_TDATA_NUM_BYTES 4
  # M00_TDATA_REMAP {tdata[31:0]}
  # M01_TDATA_REMAP {tdata[31:0]}
  # HAS_TREADY 0
# } {
    # M00_AXIS mult_1/S_AXIS_B
    # S_AXIS tx1_nco/M_AXIS_OUT
	# aclk /pll_0/clk_out1
	# aresetn /rst_0/peripheral_aresetn		
# }

cell xilinx.com:ip:axis_broadcaster:1.1 bcast_nco0 {
  NUM_MI 2
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 4
  M00_TDATA_REMAP {tdata[31:0]}
  M01_TDATA_REMAP {tdata[31:0]}
  HAS_TREADY 0
} {
    M00_AXIS mult_0/S_AXIS_B
    S_AXIS tx0_nco/M_AXIS_DATA
	aclk /pll_0/clk_out1	
	aresetn /rst_0/peripheral_aresetn		
}

cell xilinx.com:ip:axis_broadcaster:1.1 bcast_nco1 {
  NUM_MI 2
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 4
  M00_TDATA_REMAP {tdata[31:0]}
  M01_TDATA_REMAP {tdata[31:0]}
  HAS_TREADY 0
} {
    M00_AXIS mult_1/S_AXIS_B
    S_AXIS tx1_nco/M_AXIS_DATA
	aclk /pll_0/clk_out1
	aresetn /rst_0/peripheral_aresetn		
}