# filenale: build.tcl
#### Template Script for Vivado RTL->Synthesis->P&R->Bitstream
##############################################################################
## Preset global variables and attributes
##############################################################################
set_param synth.elaboration.rodinMoreOptions "rt::set_parameter var_size_limit 4194304"
set PROJ_NM "gps_on_fpga"
set PROJ_DIR "./output"
set PART_NM "xczu3eg-sbva484-1-i"
set SYNTH_ARGS ""
append SYNTH_ARGS " " -flatten_hierarchy " " rebuilt " "
append SYNTH_ARGS " " -gated_clock_conversion " " off " "
append SYNTH_ARGS " " -bufg " {" 12 "} "
append SYNTH_ARGS " " -fanout_limit " {" 10000 "} "
append SYNTH_ARGS " " -directive " " RuntimeOptimized " "
append SYNTH_ARGS " " -fsm_extraction " " auto " "
#append SYNTH_ARGS " " -keep_equivalent_registers " "
append SYNTH_ARGS " " -resource_sharing " " auto " "
append SYNTH_ARGS " " -control_set_opt_threshold " " auto " "
#append SYNTH_ARGS " " -no_lc " "
append SYNTH_ARGS " " -shreg_min_size " {" 5 "} "
append SYNTH_ARGS " " -max_bram " {" -1 "} "
append SYNTH_ARGS " " -max_dsp " {" -1 "} "
append SYNTH_ARGS " " -cascade_dsp " " auto " "
append SYNTH_ARGS " " -verbose
set DEFINES ""
append DEFINES -verilog_define " " USE_DEBUG " "
set TOP_MODULE "gps_top"
set_part $PART_NM

####################################################################
## Load Design
####################################################################

# read rtl files
read_verilog -sv [glob ../gps_rtl/*.v]
read_verilog -sv [glob ../gps_rtl/gps_top/*.sv]
read_verilog -sv [glob ../gps_rtl/gps_acquisition/rtl/*.sv]
read_verilog -sv [glob ../gps_rtl/gps_acquisition/rtl/*.v]
#read_verilog -sv [glob ../gps_rtl/gps_acquisition/rtl/fft_pkg.sv]
#read_verilog -sv [glob ../gps_rtl/gps_acquisition/rtl/input_buffer_pkg.sv]
read_verilog -sv [glob ../gps_rtl/gps_tracker/*.sv]

# read constraints
read_xdc ./sdr_constraint.xdc

if {![file exists ${PROJ_DIR}]} {
  file mkdir ${PROJ_DIR}
  puts "Creating directory ${PROJ_DIR}"
}

# read ip
#read_ip [glob ./rtl/*.xci]

####################################################################
## Synthesize Design
####################################################################
#   out of context mode synthesis
eval "synth_design $DEFINES $SYNTH_ARGS -top $TOP_MODULE -part $PART_NM -mode out_of_context"   
report_timing_summary -file $PROJ_DIR/${PROJ_NM}_post_synth_tim.rpt
report_power -file $PROJ_DIR/${PROJ_NM}_post_synth_power.rpt
report_utilization -file $PROJ_DIR/${PROJ_NM}_post_synth_util.rpt
write_checkpoint -force $PROJ_DIR/${PROJ_NM}_post_synth.dcp

puts "============================"
puts "Build Process Finished......"
puts "============================"
