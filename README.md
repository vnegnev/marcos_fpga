 marcos_fpga

Steps to compile the bitstream and XSA files:

- Clone this project

- git submodule update --init --remote

cd ..

git clone -b reset_instruction https://github.com/catkira/ocra-pulseq

git clone -b shim-interface https://github.com/catkira/marcos_client

git clone -b hf_chain_reset https://github.com/catkira/marcos_extras.git


To compile the HDL sources do: (not necessary if bit files from marcos_extras are used)
- install Vivado on Linux (at least 2019.2)
- go into ocra/HDL
- parse settings64-Vitis.sh
- type "make", this will create a .bit file for the fpga

To run the loopback test do:
- go into marcos_extras
- run marcos_setup_bm.sh with correct arguments
- install python3 your host pc
- edit marcos_client/local_config.py
- run loopback_test.py
