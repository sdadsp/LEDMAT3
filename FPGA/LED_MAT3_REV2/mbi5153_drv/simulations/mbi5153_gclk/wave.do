onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mbi5153_gclk_tb/RESET
add wave -noupdate /mbi5153_gclk_tb/CLK
add wave -noupdate /mbi5153_gclk_tb/GCLK_DISPLAY
add wave -noupdate /mbi5153_gclk_tb/GCLK_ON_OFF
add wave -noupdate /mbi5153_gclk_tb/GCLK_OUT
add wave -noupdate /mbi5153_gclk_tb/GCLK_ACTIVE
add wave -noupdate -radix unsigned /mbi5153_gclk_tb/SCAN_LINE_ADDR
add wave -noupdate /mbi5153_gclk_tb/EOS
add wave -noupdate -divider {Internal Signals}
add wave -noupdate /mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt_load
add wave -noupdate -radix unsigned -childformat {{{/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[9]} -radix unsigned} {{/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[8]} -radix unsigned} {{/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[7]} -radix unsigned} {{/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[6]} -radix unsigned} {{/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[5]} -radix unsigned} {{/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[4]} -radix unsigned} {{/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[3]} -radix unsigned} {{/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[2]} -radix unsigned} {{/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[1]} -radix unsigned} {{/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[0]} -radix unsigned}} -subitemconfig {{/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[9]} {-height 15 -radix unsigned} {/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[8]} {-height 15 -radix unsigned} {/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[7]} {-height 15 -radix unsigned} {/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[6]} {-height 15 -radix unsigned} {/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[5]} {-height 15 -radix unsigned} {/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[4]} {-height 15 -radix unsigned} {/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[3]} {-height 15 -radix unsigned} {/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[2]} {-height 15 -radix unsigned} {/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[1]} {-height 15 -radix unsigned} {/mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt[0]} {-height 15 -radix unsigned}} /mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_cycle_cnt
add wave -noupdate /mbi5153_gclk_tb/mbi5153_gclk_inst/dtime_cnt_load
add wave -noupdate -radix unsigned /mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_section_cnt
add wave -noupdate /mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_section_cnt_load
add wave -noupdate /mbi5153_gclk_tb/mbi5153_gclk_inst/pwm_section_cnt_ena
add wave -noupdate -radix unsigned -childformat {{{/mbi5153_gclk_tb/mbi5153_gclk_inst/dtime_cnt[5]} -radix unsigned} {{/mbi5153_gclk_tb/mbi5153_gclk_inst/dtime_cnt[4]} -radix unsigned} {{/mbi5153_gclk_tb/mbi5153_gclk_inst/dtime_cnt[3]} -radix unsigned} {{/mbi5153_gclk_tb/mbi5153_gclk_inst/dtime_cnt[2]} -radix unsigned} {{/mbi5153_gclk_tb/mbi5153_gclk_inst/dtime_cnt[1]} -radix unsigned} {{/mbi5153_gclk_tb/mbi5153_gclk_inst/dtime_cnt[0]} -radix unsigned}} -subitemconfig {{/mbi5153_gclk_tb/mbi5153_gclk_inst/dtime_cnt[5]} {-height 15 -radix unsigned} {/mbi5153_gclk_tb/mbi5153_gclk_inst/dtime_cnt[4]} {-height 15 -radix unsigned} {/mbi5153_gclk_tb/mbi5153_gclk_inst/dtime_cnt[3]} {-height 15 -radix unsigned} {/mbi5153_gclk_tb/mbi5153_gclk_inst/dtime_cnt[2]} {-height 15 -radix unsigned} {/mbi5153_gclk_tb/mbi5153_gclk_inst/dtime_cnt[1]} {-height 15 -radix unsigned} {/mbi5153_gclk_tb/mbi5153_gclk_inst/dtime_cnt[0]} {-height 15 -radix unsigned}} /mbi5153_gclk_tb/mbi5153_gclk_inst/dtime_cnt
add wave -noupdate /mbi5153_gclk_tb/mbi5153_gclk_inst/gclk_force_high
add wave -noupdate -radix unsigned /mbi5153_gclk_tb/mbi5153_gclk_inst/fsm_gclk
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {28876310 ps} 0} {{Cursor 2} {6890080110 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 154
configure wave -valuecolwidth 52
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
WaveRestoreZoom {6602482030 ps} {7274254340 ps}
