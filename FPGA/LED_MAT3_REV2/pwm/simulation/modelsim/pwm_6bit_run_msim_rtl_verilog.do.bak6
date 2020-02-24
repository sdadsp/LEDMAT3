transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+D:/PROJECTS/LED_MATRIX/Design/P2_LED_DRV/pwm/source {D:/PROJECTS/LED_MATRIX/Design/P2_LED_DRV/pwm/source/pwm.v}

vlog -sv -work work +incdir+D:/PROJECTS/LED_MATRIX/Design/P2_LED_DRV/pwm/source {D:/PROJECTS/LED_MATRIX/Design/P2_LED_DRV/pwm/source/pwm_6bit.vt}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L fiftyfivenm_ver -L rtl_work -L work -voptargs="+acc"  pwm_6bit_vlg_tst

add wave *
view structure
view signals
run -all
