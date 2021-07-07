# 'make' builds everything
# 'make clean' deletes everything except source files and Makefile
#
# You need to set NAME, PART and PROC for your project.
# NAME is the base name for most of the generated files.
LD_LIBRARY_PATH =

NAME = marcos_fpga
PART = xc7z020clg400-1
HWNAME = stemlab_sdr

CORES_PAVEL = axi_cfg_register_v1_0 axis_constant_v1_0 \
        axis_$(HWNAME)_adc_v1_0 axis_$(HWNAME)_dac_v1_0 \
        axis_zeroer_v1_0 axis_variable_v1_0 axis_interpolator_v1_0 \
        axi_sts_register_v1_0

PROC = ps7_cortexa9_0

CORES = flocra_v1_0 complex_multiplier_v1_0 CIC_v1_0 DDS_v1_0

VIVADO = vivado -nolog -nojournal -mode batch
RM = rm -rf

DTREE_TAG = xilinx-v2020.2
DTREE_DIR = utils/device-tree-xlnx-$(DTREE_TAG)
DTREE_TAR = utils/device-tree-xlnx-$(DTREE_TAG).tar.gz
DTREE_URL = https://github.com/Xilinx/device-tree-xlnx/archive/$(DTREE_TAG).tar.gz

.PRECIOUS: tmp/cores_pavel/% tmp/cores/% tmp/%.xpr tmp/%.hdf tmp/%.bit tmp/%.bit.bin tmp/%.tree/system.dts

all: tmp/$(NAME).bit.bin tmp/$(NAME).dtbo

xpr: tmp/$(NAME).xpr

bit: tmp/$(NAME).bit

hdf: tmp/$(NAME).hdf

$(DTREE_TAR):
	mkdir -p $(@D)
	curl -L $(DTREE_URL) -o $@

$(DTREE_DIR): $(DTREE_TAR)
	mkdir -p $@
	tar -zxf $< --strip-components=1 --directory=$@

tmp/cores_pavel/%: cores_pavel/%/core_config.tcl cores_pavel/%/*.v
	mkdir -p $(@D)
	$(VIVADO) -source scripts/core_pavel.tcl -tclargs $* $(PART)

tmp/cores/%: cores/%/core_config.tcl $(cores/%/*.v)  $(cores_pavel/%/*.sv)
	mkdir -p $(@D)
	$(VIVADO) -source scripts/core.tcl -tclargs $* $(PART)

tmp/$(NAME).xpr: projects/$(NAME) $(addprefix tmp/cores_pavel/, $(CORES_PAVEL)) $(addprefix tmp/cores/, $(CORES))
	mkdir -p $(@D)
	$(VIVADO) -source scripts/project.tcl -tclargs $* $(PART) $(PART_VARIANT)

tmp/%.hdf: tmp/%.xpr
	mkdir -p $(@D)
	$(VIVADO) -source scripts/hwdef.tcl -tclargs $*
	cp tmp/marcos_fpga.xsa tmp/marcos_fpga.hdf

tmp/%.bit: tmp/%.xpr
	mkdir -p $(@D)
	$(VIVADO) -source scripts/bitstream.tcl -tclargs $*

tmp/%.bit.bin: tmp/%.bit
	echo "all:{ $^}" > tmp/marcos_fpga.bif
	bootgen -image tmp/marcos_fpga.bif -arch zynq -process_bitstream bin -w -o $@

tmp/%.tree/system.dts: tmp/%.hdf $(DTREE_DIR)
	mkdir -p $(@D)
	xsct scripts/devicetree.tcl $(NAME) $(PROC) $(DTREE_DIR)

tmp/$(NAME).dtbo: tmp/$(NAME).tree/system.dts
	dtc -O dtb -o tmp/$(NAME).dtbo -b 0 -@ tmp/$(NAME).tree/pl.dtsi

clean:
	$(RM) fw_printenv tmp
	$(RM) .Xil usage_statistics_webtalk.html usage_statistics_webtalk.xml
	$(RM) apk-tools-static-* alpine-uboot-* linux-firmware-* stemlab-sdr-alpine-*
	$(RM) vivado*.jou vivado*.log
	$(RM) webtalk*.jou webtalk*.log
