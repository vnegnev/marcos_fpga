global adc_clk_freq

cell open-mri:user:complex_multiplier:1.0 mult_0 {
  OPERAND_WIDTH_A 16
  OPERAND_WIDTH_B 16
  OPERAND_WIDTH_OUT 32
  BLOCKING 0
  STAGES 3
  TRUNCATE 1  
} {
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
}

# Create cic_compiler
cell xilinx.com:ip:cic_compiler:4.0 cic_real {
  INPUT_DATA_WIDTH.VALUE_SRC USER
  FILTER_TYPE Decimation
  NUMBER_OF_STAGES 6
  SAMPLE_RATE_CHANGES Programmable
  MINIMUM_RATE 25
  MAXIMUM_RATE 8192
  FIXED_OR_INITIAL_RATE 625
  INPUT_SAMPLE_FREQUENCY $adc_clk_freq
  CLOCK_FREQUENCY $adc_clk_freq
  INPUT_DATA_WIDTH 32
  QUANTIZATION Truncation
  OUTPUT_DATA_WIDTH 32
  USE_XTREME_DSP_SLICE false
  HAS_DOUT_TREADY false
  HAS_ARESETN true
} {
  S_AXIS_DATA comb2iq/M00_AXIS
  S_AXIS_CONFIG rate/M00_AXIS
}

# Create cic_compiler
cell xilinx.com:ip:cic_compiler:4.0 cic_imag {
  INPUT_DATA_WIDTH.VALUE_SRC USER
  FILTER_TYPE Decimation
  NUMBER_OF_STAGES 6
  SAMPLE_RATE_CHANGES Programmable
  MINIMUM_RATE 25
  MAXIMUM_RATE 8192
  FIXED_OR_INITIAL_RATE 625
  INPUT_SAMPLE_FREQUENCY $adc_clk_freq
  CLOCK_FREQUENCY $adc_clk_freq
  INPUT_DATA_WIDTH 32
  QUANTIZATION Truncation
  OUTPUT_DATA_WIDTH 32
  USE_XTREME_DSP_SLICE false
  HAS_DOUT_TREADY false
  HAS_ARESETN true
} {
  S_AXIS_DATA comb2iq/M01_AXIS
  S_AXIS_CONFIG rate/M01_AXIS
}

cell xilinx.com:ip:axis_combiner:1.1 comb_iqmerge {
  NUM_SI 2
  TDATA_NUM_BYTES 4
} {
    S00_AXIS cic_real/M_AXIS_DATA
    S01_AXIS cic_imag/M_AXIS_DATA
}


