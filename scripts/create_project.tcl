# ==========================================
# create_vivado_project.tcl
# Создание Vivado-проекта из файлов репозитория
# ==========================================

# Корневая папка репозитория:
# если скрипт лежит в sintezator/scripts/,
# то корень проекта = на уровень выше
set repo_root [file normalize [file join [file dirname [info script]] ".."]]

# Имя проекта Vivado
set project_name "sintezator"

# Куда Vivado создаст служебные файлы
set project_dir [file join $repo_root "vivado_project"]

# FPGA part
set fpga_part "xc7a100tcsg324-1"

# -------------------------------
# Очистка старого проекта
# -------------------------------
if {[file exists $project_dir]} {
    file delete -force $project_dir
}

# -------------------------------
# Создание проекта
# -------------------------------
create_project $project_name $project_dir -part $fpga_part

set_property target_language Verilog [current_project]

# -------------------------------
# Добавление RTL
# -------------------------------
set rtl_files [glob -nocomplain [file join $repo_root "rtl" "*.v"]]
if {[llength $rtl_files] > 0} {
    add_files $rtl_files
    set_property top sintezator_top [get_filesets sources_1]
} else {
    puts "WARNING: RTL files not found"
}

# -------------------------------
# Добавление constraints
# -------------------------------
set all_xdc_files [glob -nocomplain [file join $repo_root "constraints" "*.xdc"]]
set xdc_files {}
foreach xdc_file $all_xdc_files {
    # The supplied master file is kept only as a pin-reference template. Its
    # wrapped comment lines are not valid Tcl/XDC commands, so do not load it.
    if {[file tail $xdc_file] ne "NexysA7_UART.xdc"} {
        lappend xdc_files $xdc_file
    }
}
if {[llength $xdc_files] > 0} {
    add_files -fileset constrs_1 $xdc_files
} else {
    puts "WARNING: XDC files not found"
}

# -------------------------------
# Добавление testbench / simulation files
# -------------------------------
set tb_files [glob -nocomplain [file join $repo_root "tb" "*.v"]]
if {[llength $tb_files] > 0} {
    add_files -fileset sim_1 $tb_files
    set_property top sintezator_top_tb [get_filesets sim_1]
} else {
    puts "WARNING: TB files not found"
}

# -------------------------------
# Обновление порядка компиляции
# -------------------------------
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Vivado project created successfully."
puts "Repository root: $repo_root"
puts "Project dir: $project_dir"
