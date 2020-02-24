onerror {resume}
quietly virtual function -install /mbi5153_data_tst/mbi5153_data_inst -env /mbi5153_data_tst/#INITIAL#53 { &{/mbi5153_data_tst/mbi5153_data_inst/dclk_cnt[3], /mbi5153_data_tst/mbi5153_data_inst/dclk_cnt[2], /mbi5153_data_tst/mbi5153_data_inst/dclk_cnt[1], /mbi5153_data_tst/mbi5153_data_inst/dclk_cnt[0] }} dclk_cnt_lsb
quietly WaveActivateNextPane {} 0
add wave -noupdate /mbi5153_data_tst/RESET
add wave -noupdate /mbi5153_data_tst/REQUEST
add wave -noupdate -radix hexadecimal /mbi5153_data_tst/DATA
add wave -noupdate /mbi5153_data_tst/CLK
add wave -noupdate /mbi5153_data_tst/READY
add wave -noupdate /mbi5153_data_tst/ACTIVE
add wave -noupdate /mbi5153_data_tst/TX_DONE
add wave -noupdate -radix unsigned /mbi5153_data_tst/mbi5153_data_inst/dclk_cnt_lsb
add wave -noupdate /mbi5153_data_tst/DCLK
add wave -noupdate /mbi5153_data_tst/LATCH
add wave -noupdate -radix hexadecimal -childformat {{{/mbi5153_data_tst/ADDR[3]} -radix hexadecimal} {{/mbi5153_data_tst/ADDR[2]} -radix hexadecimal} {{/mbi5153_data_tst/ADDR[1]} -radix hexadecimal} {{/mbi5153_data_tst/ADDR[0]} -radix hexadecimal}} -subitemconfig {{/mbi5153_data_tst/ADDR[3]} {-height 15 -radix hexadecimal} {/mbi5153_data_tst/ADDR[2]} {-height 15 -radix hexadecimal} {/mbi5153_data_tst/ADDR[1]} {-height 15 -radix hexadecimal} {/mbi5153_data_tst/ADDR[0]} {-height 15 -radix hexadecimal}} /mbi5153_data_tst/ADDR
add wave -noupdate /mbi5153_data_tst/R
add wave -noupdate -divider {Internal Signals}
add wave -noupdate /mbi5153_data_tst/mbi5153_data_inst/fsm_tx_ch
add wave -noupdate /mbi5153_data_tst/mbi5153_data_inst/tx_start
add wave -noupdate /mbi5153_data_tst/mbi5153_data_inst/load_data
add wave -noupdate -radix hexadecimal -childformat {{{/mbi5153_data_tst/mbi5153_data_inst/dclk_cnt[6]} -radix hexadecimal} {{/mbi5153_data_tst/mbi5153_data_inst/dclk_cnt[5]} -radix hexadecimal} {{/mbi5153_data_tst/mbi5153_data_inst/dclk_cnt[4]} -radix hexadecimal} {{/mbi5153_data_tst/mbi5153_data_inst/dclk_cnt[3]} -radix hexadecimal} {{/mbi5153_data_tst/mbi5153_data_inst/dclk_cnt[2]} -radix hexadecimal} {{/mbi5153_data_tst/mbi5153_data_inst/dclk_cnt[1]} -radix hexadecimal} {{/mbi5153_data_tst/mbi5153_data_inst/dclk_cnt[0]} -radix hexadecimal}} -subitemconfig {{/mbi5153_data_tst/mbi5153_data_inst/dclk_cnt[6]} {-height 15 -radix hexadecimal} {/mbi5153_data_tst/mbi5153_data_inst/dclk_cnt[5]} {-height 15 -radix hexadecimal} {/mbi5153_data_tst/mbi5153_data_inst/dclk_cnt[4]} {-height 15 -radix hexadecimal} {/mbi5153_data_tst/mbi5153_data_inst/dclk_cnt[3]} {-height 15 -radix hexadecimal} {/mbi5153_data_tst/mbi5153_data_inst/dclk_cnt[2]} {-height 15 -radix hexadecimal} {/mbi5153_data_tst/mbi5153_data_inst/dclk_cnt[1]} {-height 15 -radix hexadecimal} {/mbi5153_data_tst/mbi5153_data_inst/dclk_cnt[0]} {-height 15 -radix hexadecimal}} /mbi5153_data_tst/mbi5153_data_inst/dclk_cnt
add wave -noupdate -radix hexadecimal /mbi5153_data_tst/mbi5153_data_inst/reg_r
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1625000 ps} 0}
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
WaveRestoreZoom {0 ps} {4096 ns}
