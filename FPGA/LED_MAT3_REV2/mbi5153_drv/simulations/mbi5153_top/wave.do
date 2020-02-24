onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mbi5153_top_tb/RESET
add wave -noupdate /mbi5153_top_tb/CLK_20M
add wave -noupdate /mbi5153_top_tb/CLK_10M
add wave -noupdate -color Aquamarine /mbi5153_top_tb/VSYNC_STB
add wave -noupdate /mbi5153_top_tb/HUB75_GCLK
add wave -noupdate /mbi5153_top_tb/HUB75_CLK
add wave -noupdate /mbi5153_top_tb/HUB75_LATCH
add wave -noupdate -radix hexadecimal /mbi5153_top_tb/HUB75_ADDR
add wave -noupdate /mbi5153_top_tb/HUB75_R
add wave -noupdate -radix unsigned /mbi5153_top_tb/mbi5153_top_inst/mbi5153_ctrl_inst/vsync_stb_cnt
add wave -noupdate /mbi5153_top_tb/mbi5153_top_inst/frame_eos_dclk
add wave -noupdate -divider {Internal (_gclk)}
add wave -noupdate /mbi5153_top_tb/mbi5153_top_inst/mbi5153_gclk_inst/EOS
add wave -noupdate -radix unsigned /mbi5153_top_tb/mbi5153_top_inst/mbi5153_gclk_inst/pwm_cycle_cnt
add wave -noupdate -radix unsigned /mbi5153_top_tb/mbi5153_top_inst/mbi5153_gclk_inst/pwm_scan_line_cnt
add wave -noupdate -radix unsigned /mbi5153_top_tb/mbi5153_top_inst/mbi5153_gclk_inst/pwm_section_cnt
add wave -noupdate -radix unsigned /mbi5153_top_tb/mbi5153_top_inst/mbi5153_gclk_inst/dtime_cnt
add wave -noupdate -divider {Internal (_ctrl)}
add wave -noupdate /mbi5153_top_tb/mbi5153_top_inst/mbi5153_ctrl_inst/gclk_display
add wave -noupdate /mbi5153_top_tb/mbi5153_top_inst/mbi5153_ctrl_inst/gclk_on_off
add wave -noupdate /mbi5153_top_tb/mbi5153_top_inst/mbi5153_ctrl_inst/RECONFIG_REQ
add wave -noupdate /mbi5153_top_tb/mbi5153_top_inst/mbi5153_ctrl_inst/UPDATE_GS_REQ
add wave -noupdate /mbi5153_top_tb/mbi5153_top_inst/mbi5153_ctrl_inst/VSYNC_CMD_REQ
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 3} {2642060600 ps} 0} {{Cursor 4} {10673223700 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 137
configure wave -valuecolwidth 38
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
WaveRestoreZoom {10510632980 ps} {10894331050 ps}
