transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+D:/PROJECTS/LED_MATRIX/Design/P2_LED_DRV/hub75_drv/source {D:/PROJECTS/LED_MATRIX/Design/P2_LED_DRV/hub75_drv/source/hub75_drv.v}

vlog -sv -work work +incdir+D:/PROJECTS/LED_MATRIX/Design/P2_LED_DRV/hub75_drv/simulation/modelsim {D:/PROJECTS/LED_MATRIX/Design/P2_LED_DRV/hub75_drv/simulation/modelsim/hub75_drv.vt}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L fiftyfivenm_ver -L rtl_work -L work -voptargs="+acc"  hub75_drv_vlg_tst

add wave *
view structure
view signals
run -all
