PROJECT=gps_on_fpga
TOP=gps_on_fpga.bdf
FAMILY="MAX 10"
PART=10M50DAF484C6GES
PACKING_OPTION=minimize_area

.PHONY: all

all: synthesis fitter assembler

synthesis:
	quartus_map $(PROJECT) --source=$(TOP) --family=$(FAMILY)

fitter: synthesis
	quartus_fit $(PROJECT) --part=$(PART) --pack_register=$(PACKING_OPTION)

assembler: fitter
	quartus_asm $(PROJECT)

sta: fitter
	quartus_sta $(PROJECT)
