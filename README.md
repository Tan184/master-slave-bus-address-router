# master-slave-bus-address-router
A Verilog-based bus routing module that connects one master to multiple slaves using address-based decoding logic. Includes a modular SystemVerilog testbench (driver, monitor, scoreboard, etc.) to verify correct routing and functionality across defined address ranges.

Done with the top level module, and a full blown SystemVerilog testbench with a monitor, scoreboard, generator, driver, env, and transaction classes.
In the full_sv_tb code, I've constrained the address to e32c, and made it so that all odd transactions write into one address, and even transactions read from the same address, to test functionality. This can be changed later for true randomized testing.
</br>

The overall system is structured as follows: </br>
<img width="510" height="428" alt="image" src="https://github.com/user-attachments/assets/4f199843-41ed-4d83-8719-5e081f92b35b" /> 
</br>

Slave inputs/outputs: </br>
<img width="416" height="457" alt="image" src="https://github.com/user-attachments/assets/98642dcb-fe08-4931-90d5-012541456563" />
</br>

Master inputs/outputs (implemented through testbench): </br>
<img width="445" height="451" alt="image" src="https://github.com/user-attachments/assets/4ee726c2-c1d8-40e7-8a3a-ba3f4375d3af" />
</br>


Data is routed based on the address as follows: </br>
<img width="212" height="188" alt="image" src="https://github.com/user-attachments/assets/6bcc026a-f713-48dc-96d6-33065c1770b5" />
</br>

Following is the output waveform of the testbench:
<img width="1819" height="434" alt="image" src="https://github.com/user-attachments/assets/83e77987-cb83-4e6b-841d-c6c4271cc191" /> 
</br>

The waveform shows 3 transactions taking place - 
1. Writing data e5e9 into address e32c at 25,000ps. Slave 3 has been picked as its address falls in the range 0xC000 to 0xFFFF.
2. Reading e5e9 from address e32c at 45,000ps. The value is updated at 55,00ps - that is because in this particular design, both read and write operations take 2 cycles to complete. Enable is set to low for the first cycle, and high for the second. However, for the write operation, data is written at the first cycle regardless of enable, but for the read operation, data is read at the second cycle.
3. Writing data 95a4 into (same) address e32c at 65,000ps.




