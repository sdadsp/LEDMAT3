onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -color {Green Yellow} /mbi5153_ctrl_tb/RESET
add wave -noupdate -color {Green Yellow} /mbi5153_ctrl_tb/CLK
add wave -noupdate -color {Green Yellow} /mbi5153_ctrl_tb/VSYNC_STB
add wave -noupdate /mbi5153_ctrl_tb/mbi5153_ctrl_inst/vsync_stb_latch
add wave -noupdate -color {Green Yellow} /mbi5153_ctrl_tb/EOS
add wave -noupdate /mbi5153_ctrl_tb/GCLK_DISPLAY
add wave -noupdate /mbi5153_ctrl_tb/GCLK_ON_OFF
add wave -noupdate -divider <NULL>
add wave -noupdate /mbi5153_ctrl_tb/UPDATE_GS_REQ
add wave -noupdate -color {Green Yellow} /mbi5153_ctrl_tb/UPDATE_GS_DONE
add wave -noupdate -divider <NULL>
add wave -noupdate /mbi5153_ctrl_tb/RECONFIG_REQ
add wave -noupdate -color {Green Yellow} /mbi5153_ctrl_tb/RECONFIG_DONE
add wave -noupdate -divider <NULL>
add wave -noupdate -color {Green Yellow} /mbi5153_ctrl_tb/VSYNC_CMD_REQ
add wave -noupdate /mbi5153_ctrl_tb/CMD_DONE
add wave -noupdate -divider {Internal Signals}
add wave -noupdate -radix hexadecimal /mbi5153_ctrl_tb/mbi5153_ctrl_inst/vsync_stb_cnt
add wave -noupdate /mbi5153_ctrl_tb/eos_stb_cnt
add wave -noupdate -radix hexadecimal -childformat {{{/mbi5153_ctrl_tb/mbi5153_ctrl_inst/fsm_led_drv[3]} -radix hexadecimal} {{/mbi5153_ctrl_tb/mbi5153_ctrl_inst/fsm_led_drv[2]} -radix hexadecimal} {{/mbi5153_ctrl_tb/mbi5153_ctrl_inst/fsm_led_drv[1]} -radix hexadecimal} {{/mbi5153_ctrl_tb/mbi5153_ctrl_inst/fsm_led_drv[0]} -radix hexadecimal}} -subitemconfig {{/mbi5153_ctrl_tb/mbi5153_ctrl_inst/fsm_led_drv[3]} {-height 15 -radix hexadecimal} {/mbi5153_ctrl_tb/mbi5153_ctrl_inst/fsm_led_drv[2]} {-height 15 -radix hexadecimal} {/mbi5153_ctrl_tb/mbi5153_ctrl_inst/fsm_led_drv[1]} {-height 15 -radix hexadecimal} {/mbi5153_ctrl_tb/mbi5153_ctrl_inst/fsm_led_drv[0]} {-height 15 -radix hexadecimal}} /mbi5153_ctrl_tb/mbi5153_ctrl_inst/fsm_led_drv
add wave -noupdate -radix hexadecimal -childformat {{{/mbi5153_ctrl_tb/mbi5153_ctrl_inst/dclk_cnt[1]} -radix hexadecimal} {{/mbi5153_ctrl_tb/mbi5153_ctrl_inst/dclk_cnt[0]} -radix hexadecimal}} -subitemconfig {{/mbi5153_ctrl_tb/mbi5153_ctrl_inst/dclk_cnt[1]} {-height 15 -radix hexadecimal} {/mbi5153_ctrl_tb/mbi5153_ctrl_inst/dclk_cnt[0]} {-height 15 -radix hexadecimal}} /mbi5153_ctrl_tb/mbi5153_ctrl_inst/dclk_cnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {32903350 ps} 0}
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
WaveRestoreZoom {0 ps} {180247450 ps}
