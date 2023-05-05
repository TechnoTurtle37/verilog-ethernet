The main files here that we wrote are storage.v, analyzer,v, dns_ip_rx,v (under the lib directory), and sbdm2048.v. While we did not create fpga_core.v from scratch, it has been heavilty modified from the original. We also wrote the testbench fpga_core_tb.v

The visualzer and RS232 receiver are in the vizualizer directory, and the software simualtions are in the dns-parse-sim directory.

To build the project, simply open the fpga.qpf file in Intel Quartus Prime Lite Edition and compile. Program the board with the Programmer, connect the DNS traffic source the the first interface, and optionally the bridged traffic destination to the second interface. 

To run the Icarus Verilog Simulations, Icarus Verilog and GTKWave are required. Comment out the MAC, TAP, ETH, IP, DNS, SDRAM Controller, and AXIS_UART modules and uncomment the Analzyer tester (but not the hash tester) section under fpga_core.v, then run 

```
iverilog -s fpga_core_tb -o fpga_core_tb_output fpga_core_tb.v fpga_core.v analyzer.v storage.v sbdm2048.v
vvp fpga_core_tb_output
gtkwave fpga_core_tb.vcd
```

The necesarry singals will need to be added to the view.

This is a port of Alex Forencich's verilog-ethernet repo's DE2-115 example of a UDP echo running on PHY0.
