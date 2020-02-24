onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mbi5153_rcfg_tb/RESET
add wave -noupdate /mbi5153_rcfg_tb/CLK
add wave -noupdate /mbi5153_rcfg_tb/REQUEST
add wave -noupdate /mbi5153_rcfg_tb/TX_READY
add wave -noupdate /mbi5153_rcfg_tb/CMD_DONE
add wave -noupdate /mbi5153_rcfg_tb/REQUEST_PREA
add wave -noupdate /mbi5153_rcfg_tb/REQUEST_RCFG
add wave -noupdate -radix hexadecimal /mbi5153_rcfg_tb/INDEX
add wave -noupdate /mbi5153_rcfg_tb/READY
add wave -noupdate /mbi5153_rcfg_tb/ACTIVE
add wave -noupdate /mbi5153_rcfg_tb/DONE
add wave -noupdate -divider {Internal Signals}
add wave -noupdate -radix hexadecimal /mbi5153_rcfg_tb/mbi5153_rcfg_inst/fsm_rcfg_next_state
add wave -noupdate -radix hexadecimal /mbi5153_rcfg_tb/mbi5153_rcfg_inst/fsm_rcfg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {556110 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 135
configure wave -valuecolwidth 42
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
WaveRestoreZoom {0 ps} {14339730 ps}
