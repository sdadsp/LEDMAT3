onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mbi5153_top_tb/RESET
add wave -noupdate /mbi5153_top_tb/CLK_20M
add wave -noupdate /mbi5153_top_tb/CLK_10M
add wave -noupdate /mbi5153_top_tb/VSYNC_STB
add wave -noupdate /mbi5153_top_tb/HUB75_GCLK
add wave -noupdate /mbi5153_top_tb/HUB75_CLK
add wave -noupdate /mbi5153_top_tb/mbi5153_top_inst/mbi5153_line_inst/dclk_cnt
add wave -noupdate /mbi5153_top_tb/HUB75_LATCH
add wave -noupdate -radix hexadecimal /mbi5153_top_tb/HUB75_ADDR
add wave -noupdate /mbi5153_top_tb/HUB75_R
add wave -noupdate -radix hexadecimal /mbi5153_top_tb/mbi5153_top_inst/mbi5153_ctrl_inst/vsync_stb_cnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {5775688690 ps} 0}
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
WaveRestoreZoom {5769310910 ps} {5816295110 ps}
