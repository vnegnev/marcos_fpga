 marcos_fpga

Steps to compile the bitstream and XSA files:

- Clone this project

- git submodule update --init

(next 3 steps optional, needed to run the loopback test)

cd ..

git clone -b reset_instruction https://github.com/catkira/ocra-pulseq

git clone -b shim-interface https://github.com/catkira/marcos_client

git clone -b hf_chain_reset https://github.com/catkira/marcos_extras.git


To compile the HDL sources do: (not necessary if bit files from marcos_extras are used)
- install Vivado + Vitis on Linux (at least 2020.2)
- cd into the hdl folder
- Run `. /opt/Xilinx/Vitis/2020.2/settings64.sh`
- type "make", this will create .bit, .bin and .dtbo files for the fpga inside the `hdl/tmp` folder. Note that currently (20/11/2024) running multithreaded (i.e. "make -j4" etc) may lead to bugs or failures to compile.
- To select different options such as the target or the use of open-source cores, read the top of `hdl/Makefile` for instructions.

To run the loopback test do:
- go into marcos_extras
- run marcos_setup_bm.sh with correct arguments
- install python3 your host pc
- edit marcos_client/local_config.py
- run loopback_test.py
