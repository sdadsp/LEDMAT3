onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /hub75_drv_vlg_tst/eachvec
add wave -noupdate /hub75_drv_vlg_tst/CLK_PWM
add wave -noupdate /hub75_drv_vlg_tst/MEM_DATA
add wave -noupdate /hub75_drv_vlg_tst/CLK
add wave -noupdate /hub75_drv_vlg_tst/RESET
add wave -noupdate /hub75_drv_vlg_tst/FSM
add wave -noupdate /hub75_drv_vlg_tst/PWM_BIT_NUM
add wave -noupdate /hub75_drv_vlg_tst/PWM_STEP
add wave -noupdate /hub75_drv_vlg_tst/PWM_WAIT_CNT
add wave -noupdate /hub75_drv_vlg_tst/PWM_QUANTUM_CNT
add wave -noupdate -radix hexadecimal /hub75_drv_vlg_tst/HUB_ADDR
add wave -noupdate -radix hexadecimal /hub75_drv_vlg_tst/HUB_R
add wave -noupdate /hub75_drv_vlg_tst/HUB_G
add wave -noupdate /hub75_drv_vlg_tst/HUB_B
add wave -noupdate -radix hexadecimal /hub75_drv_vlg_tst/MEM_ADDR
add wave -noupdate /hub75_drv_vlg_tst/HUB_SCLK
add wave -noupdate /hub75_drv_vlg_tst/HUB_LATCH
add wave -noupdate /hub75_drv_vlg_tst/HUB_OE
add wave -noupdate /hub75_drv_vlg_tst/MEM_RD
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1300000 ps} 0} {{Cursor 2} {1197084 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 46
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 5
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 50
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {7478752 ps}
