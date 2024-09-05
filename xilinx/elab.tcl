set PART_NM "xc7z020clg400-1"
set PROJ_DIR "./output"

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
#append SYNTH_ARGS " " -shreg_min_size " {" 3 "} "
append SYNTH_ARGS " " -shreg_min_size " {" 5 "} "
append SYNTH_ARGS " " -max_bram " {" -1 "} "
append SYNTH_ARGS " " -max_dsp " {" -1 "} "
append SYNTH_ARGS " " -cascade_dsp " " auto " "
append SYNTH_ARGS " " -verbose
set DEFINES ""
append DEFINES -verilog_define " " USE_DEBUG " "
set TOP_MODULE "fir_filter"


read_verilog ../sdr_rtl/fir_filter.v
read_xdc "./sdr_constraint.xdc"

if {![file exists ${PROJ_DIR}]} {
  file mkdir ${PROJ_DIR}
  puts "Creating directory ${PROJ_DIR}"
}

eval "synth_design $DEFINES $SYNTH_ARGS -top $TOP_MODULE -part $PART_NM -rtl"
start_gui
