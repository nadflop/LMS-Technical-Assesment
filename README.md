# Nadhira Technical Assesment for LMS

This repository contains codes and written answers for LMS Technical Assesment.

This is the hierarchy of the msg_parser.sv design:
--Top level
	+ msg_parser.sv
	(instantiates 3 modules: msg_counter.sv, msg_controller.sv, axi_slave.sv)
----- msg_counter.sv
				+ Count the "byte" size of msg_length
----- msg_controller.sv
				+ Configure data related settings & output
----- axi_slave.sv
				+ Controls the logic of s_tready signal generation

Steps to simulate the design:
1. Compile the verilog files
			vlog *.sv
2. Open modelsim
			vsim
3. Run the simulation command to create a simulation environment
			vsim -voptargs=+acc work.tb_msg_parser
4. Add the waveform using .do file
			do wave.do
5. Run the simulation
			run -all
			
If you made any changes and would like to simulate it again:
vlog *.sv; restart -f; run -all;


 
