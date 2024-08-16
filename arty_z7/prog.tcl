set PROJ_NM "dvb_s2_tvbox"
set PROJ_DIR "./output"

connect_hw_server -url localhost:3121
current_hw_target [get_hw_targets */xilinx_tcf/Digilent/12345]
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE {$PROJ_DIR/${PROJ_NM}_${WNS}ns.bit} [lindex [get_hw_devices] 0]
set_property PROBES.FILE {$PROJ_DIR/${PROJ_NM}_${WNS}ns.ltx} [lindex [get_hw_devices] 0]
program_hw_devices [lindex [get_hw_devices] 0]
refresh_hw_device [lindex [get_hw_devices] 0]
