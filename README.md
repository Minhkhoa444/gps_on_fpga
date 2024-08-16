# GPS on FPGA

## Description

GPS radio receiver fully implemented on FPGA

### eth\_mac
RTL code for an RMII 100BASE-TX MAC. Currently in progress of implementing UPD/IPv4 protocol.

### eth\_mac\_tb
Simulation files for eth\_mac RTL code.

### gps\_rtl
RTL code for GPS portion of the project.

### gps\_rtl\_tb
Simulation files for gps\_rtl RTL code.

### sdr\_rtl
RTL code for software defined radio front end of the project.

### sdr\_tb
Simulation files for sdr\_rtl RTL code.

### arty\_z7
Files used for synthesis, elaboration, place and route, programming.

### matlab\_analysis
MATLAB files used to analyze the project.

## Usage
### Tools required
- Simulator: Questa Advanced Simulator. This project used qrun so Questa 2019.4 and up is required. Questa-Intel FPGA Starter Edition should be fine but support not tested yet.

- Synthesis, elaboration, place and route: Vivado Design Suite. Currently, the script used for synthesis, elaboration, place and route used the part xc7z020clg400-1, the part on Digilent Arty Z7-20 board. Other part should be fine but support not tested yet.

### Simulation
In each ...\_tb folder, there will be a specific makefile used to invoke qrun. Therefore, Questa environment must be set properly first (adding questasim64\_2024.1\win64 to PATH variable).

To run a simulation for module ...\_tb in ...\_tb.sv file, run:
```
make TEST_MODULE=...\_tb
```

### Synthesis, elaboration, place and route
In arty\_z7 folder, there will be a make file used to invoke Vivado in non project mode. Therefore, Vivado environment must be set properly first (execute Xilinx\Vivado\2021.2\settinsg64.bat).

To run RTL elaboration, run:
```
make elab
```
