OUTPUT_DIR := output
BUILD_CMD := vivado -mode batch -source build.tcl -notrace -log $(OUTPUT_DIR)/buld.log -jou $(OUTPUT_DIR)/build.jou
BUILD_BD_CMD := vivado -mode batch -source build_bd.tcl -notrace -log $(OUTPUT_DIR)/build_bd.log -jou $(OUTPUT_DIR)/build_bd.jou
PROG_CMD := vivado -mode batch -source prog.tcl -notrace -log $(OUTPUT_DIR)/prog.log -jou $(OUTPUT_DIR)/prog.jou

ifeq ($(OS),Windows_NT)
	# Windows
	RM_CMD = powershell if (Test-Path ./$(OUTPUT_DIR)/*) { Remove-Item -Recurse -Force -ErrorAction SilentlyContinue ./$(OUTPUT_DIR)/* };
	RM_CMD += if (Test-Path ./.gen) { Remove-Item -Recurse -Force -ErrorAction SilentlyContinue ./.gen };
	RM_CMD += if (Test-Path ./.srcs) { Remove-Item -Recurse -Force -ErrorAction SilentlyContinue ./.srcs };
	RM_CMD += if (Test-Path ./.Xil) { Remove-Item -Recurse -Force -ErrorAction SilentlyContinue ./.Xil };
else
	# Unix-like
	RM_CMD = rm -rf $(OUTPUT_DIR)/* ./.gen ./.srcs ./.Xil
endif

.PHONY: all clean

all: clean build prog

build_bd: clean
	$(BUILD_BD_CMD)

build: build_bd
	$(BUILD_CMD)

prog: build
	$(PROG_CMD)

clean:
	$(RM_CMD)
