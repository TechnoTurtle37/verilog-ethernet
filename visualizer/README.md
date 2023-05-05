# Visualizer

What was this intended for? It was created to visualize outputted data from the DE2-115. Specifically it would plot the top n queried urls output from the DE2-115.

Due to issues finishing the logic on the FPGA, this only has simulated input. 

To try and use, upload "dns_sim.ino" to an arduino and connect it to a host. Then run "python main.py" on the host.

If an error occurs when initially running, re-run the program once as it may be due to an empty "data.csv" file.