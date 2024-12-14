set PROJ_DIR "./output_bd"
set PART_NM "xc7z010clg400-1"
set_part $PART_NM

create_project -in_memory -part $PART_NM

source ./rtl/design_1.tcl
