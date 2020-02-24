onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mbi5153_commands_tst/CLK
add wave -noupdate /mbi5153_commands_tst/RESET
add wave -noupdate /mbi5153_commands_tst/CMD
add wave -noupdate /mbi5153_commands_tst/DATA
add wave -noupdate /mbi5153_commands_tst/REQUEST
add wave -noupdate /mbi5153_commands_tst/READY
add wave -noupdate /mbi5153_commands_tst/ACTIVE
add wave -noupdate /mbi5153_commands_tst/DCLK
add wave -noupdate /mbi5153_commands_tst/LATCH
add wave -noupdate /mbi5153_commands_tst/Q
add wave -noupdate -divider {Internal Signals}
add wave -noupdate /mbi5153_commands_tst/mbi5153_cmd_inst1/request
add wave -noupdate /mbi5153_commands_tst/mbi5153_cmd_inst1/data
add wave -noupdate /mbi5153_commands_tst/mbi5153_cmd_inst1/fsm_cmd
add wave -noupdate /mbi5153_commands_tst/mbi5153_cmd_inst1/cmd_start
add wave -noupdate /mbi5153_commands_tst/mbi5153_cmd_inst1/cmd_run
add wave -noupdate /mbi5153_commands_tst/mbi5153_cmd_inst1/cmd_done
add wave -noupdate /mbi5153_commands_tst/mbi5153_cmd_inst1/dclk_cnt
add wave -noupdate /mbi5153_commands_tst/mbi5153_cmd_inst1/latch_cnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {786960 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 50
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {9810130 ps}
