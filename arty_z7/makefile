OUTPUT_DIR := output
BUILD_CMD := vivado -mode batch -source build.tcl -notrace
ELAB_CMD := vivado -mode batch -source elab.tcl -notrace
PROG_CMD := vivado -mode batch -source prog.tcl -notrace

ifeq ($(OS), Windows_NT)
	# Windows
	RM_CMD = cmd //C del //F //S //Q .\\vivado.log .\\vivado.jou .\\$(OUTPUT_DIR)\\*.*
else
	# Unix-like
	RM_CMD = rm -rf ./vivado.log ./vivado.jou ./$(OUTPUT_DIR)/*
endif

.PHONY: all clean

all: clean build prog

build: clean
	$(BUILD_CMD)

elab:
	$(ELAB_CMD)

prog: build
	$(PROG_CMD)
	
clean:
	$(RM_CMD)
