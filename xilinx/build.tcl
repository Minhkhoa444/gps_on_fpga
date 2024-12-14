# filenale: build.tcl
#### Template Script for Vivado RTL->Synthesis->P&R->Bitstream
##############################################################################
## Preset global variables and attributes
##############################################################################

set PROJ_NM "gps_on_fpga"
set PROJ_DIR "./output"
set PART_NM "xczu7ev-ffvc1156-2-e"
set SYNTH_ARGS ""
append SYNTH_ARGS " " -flatten_hierarchy " " rebuilt " "
append SYNTH_ARGS " " -gated_clock_conversion " " off " "
append SYNTH_ARGS " " -bufg " {" 12 "} "
append SYNTH_ARGS " " -fanout_limit " {" 10000 "} "
append SYNTH_ARGS " " -directive " " Default " "
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
set TOP_MODULE "sdr_top"
set_part $PART_NM

####################################################################
## Load Design
####################################################################

# read rtl files
read_verilog -sv [glob ../sdr_rtl/*.v]

# read block designs
#read_bd ./.srcs/sources_1/bd/design_1/design_1.bd
#generate_target all -force [get_files ./.srcs/sources_1/bd/design_1/design_1.bd]
#make_wrapper -files [get_files ./.srcs/sources_1/bd/design_1/design_1.bd] -top -import -force

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
eval "synth_design $DEFINES $SYNTH_ARGS -top $TOP_MODULE -part $PART_NM"   #   normal synthesis
report_timing_summary -file $PROJ_DIR/${PROJ_NM}_post_synth_tim.rpt
report_power -file $PROJ_DIR/${PROJ_NM}_post_synth_power.rpt
report_utilization -file $PROJ_DIR/${PROJ_NM}_post_synth_util.rpt
write_checkpoint -force $PROJ_DIR/${PROJ_NM}_post_synth.dcp

####################################################################
## Optimize Design
####################################################################

opt_design -directive Explore
report_timing_summary -file $PROJ_DIR/${PROJ_NM}_post_opt_tim.rpt
report_utilization -file $PROJ_DIR/${PROJ_NM}_post_opt_util.rpt
write_checkpoint -force $PROJ_DIR/${PROJ_NM}_post_opt.dcp
set_property SEVERITY {ERROR} [get_drc_checks DSPS-*]
report_drc -file $PROJ_DIR/${PROJ_NM}_post_opt_drc.rpt

####################################################################
## Place Design
####################################################################

place_design -directive Explore
report_timing_summary -file $PROJ_DIR/${PROJ_NM}_post_place_tim.rpt
report_utilization -file $PROJ_DIR/${PROJ_NM}_post_place_util.rpt
write_checkpoint -force $PROJ_DIR/${PROJ_NM}_post_place.dcp

####################################################################
## Physical Optimization
####################################################################

phys_opt_design -directive AggressiveExplore
phys_opt_design -directive AggressiveFanoutOpt
phys_opt_design -directive AlternateReplication
report_timing_summary -file $PROJ_DIR/${PROJ_NM}_post_place_physopt_tim.rpt
report_utilization -file $PROJ_DIR/${PROJ_NM}_post_place_physopt_util.rpt
write_checkpoint -force $PROJ_DIR/${PROJ_NM}_post_place_physopt.dcp

####################################################################
## Route Design
####################################################################

route_design -directive Explore
report_timing_summary -file $PROJ_DIR/${PROJ_NM}_post_route_tim.rpt
report_utilization -hierarchical -file $PROJ_DIR/${PROJ_NM}_post_route_util.rpt
report_route_status -file $PROJ_DIR/${PROJ_NM}_post_route_status.rpt
report_io -file $PROJ_DIR/${PROJ_NM}_post_route_io.rpt
report_power -file $PROJ_DIR/${PROJ_NM}_post_route_power.rpt
report_design_analysis -logic_level_distribution \
 -of_timing_paths [get_timing_paths -max_paths 10000 -slack_lesser_than 0] \
 -file $PROJ_DIR/${PROJ_NM}_post_route_vios.rpt
write_checkpoint -force $PROJ_DIR/${PROJ_NM}_post_route.dcp

# write netlist and xdc
write_verilog -force $PROJ_DIR/${PROJ_NM}_impl_netlist.v
#write_vhdl -force $PROJ_DIR/${PROJ_NM}_impl_netlist.vhd
write_xdc -no_fixed_only -force $PROJ_DIR/${PROJ_NM}_impl.xdc

####################################################################
## Write Bitstream
####################################################################

write_debug_probes -force $PROJ_DIR/${PROJ_NM}}.ltx
write_bitstream -force $PROJ_DIR/${PROJ_NM}.bit -bin_file

####################################################################
## Export Hardware
####################################################################

open_checkpoint $PROJ_DIR/${PROJ_NM}_post_route.dcp
write_hw_platform -fixed -include_bit -force -file $PROJ_DIR/${PROJ_NM}.xsa
validate_hw_platform -verbose $PROJ_DIR/${PROJ_NM}.xsa

puts "============================"
puts "Build Process Finished......"
puts "============================"
