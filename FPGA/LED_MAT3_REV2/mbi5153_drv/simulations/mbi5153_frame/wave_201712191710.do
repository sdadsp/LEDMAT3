onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mbi5153_frame_tb/RESET
add wave -noupdate /mbi5153_frame_tb/REQUEST
add wave -noupdate /mbi5153_frame_tb/CLK
add wave -noupdate /mbi5153_frame_tb/LINE_TX_READY
add wave -noupdate /mbi5153_frame_tb/LINE_TX_ACTIVE
add wave -noupdate /mbi5153_frame_tb/LINE_TX_DONE
add wave -noupdate /mbi5153_frame_tb/REQUEST_TO_SEND_LINE
add wave -noupdate /mbi5153_frame_tb/DATA
add wave -noupdate /mbi5153_frame_tb/ADDR
add wave -noupdate /mbi5153_frame_tb/DCLK
add wave -noupdate /mbi5153_frame_tb/LATCH
add wave -noupdate /mbi5153_frame_tb/R
add wave -noupdate -divider {Internal (_frame)}
add wave -noupdate /mbi5153_frame_tb/mbi5153_frame_inst/line_cnt
add wave -noupdate -radix unsigned /mbi5153_frame_tb/mbi5153_frame_inst/fsm_tx_fr
add wave -noupdate /mbi5153_frame_tb/mbi5153_frame_inst/frame_tx_start
add wave -noupdate /mbi5153_frame_tb/mbi5153_frame_inst/frame_tx_run
add wave -noupdate /mbi5153_frame_tb/mbi5153_frame_inst/frame_tx_done
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {120 ps} 0}
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
WaveRestoreZoom {0 ps} {20170730 ps}
