onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mbi5153_frame_tb/RESET
add wave -noupdate /mbi5153_frame_tb/REQUEST
add wave -noupdate /mbi5153_frame_tb/CLK
add wave -noupdate /mbi5153_frame_tb/LINE_TX_READY
add wave -noupdate /mbi5153_frame_tb/LINE_TX_ACTIVE
add wave -noupdate /mbi5153_frame_tb/LINE_TX_DONE
add wave -noupdate /mbi5153_frame_tb/REQUEST_TO_SEND_LINE
add wave -noupdate -radix binary /mbi5153_frame_tb/DATA
add wave -noupdate -radix hexadecimal -childformat {{{/mbi5153_frame_tb/ADDR[13]} -radix hexadecimal} {{/mbi5153_frame_tb/ADDR[12]} -radix hexadecimal} {{/mbi5153_frame_tb/ADDR[11]} -radix hexadecimal} {{/mbi5153_frame_tb/ADDR[10]} -radix hexadecimal} {{/mbi5153_frame_tb/ADDR[9]} -radix hexadecimal} {{/mbi5153_frame_tb/ADDR[8]} -radix hexadecimal} {{/mbi5153_frame_tb/ADDR[7]} -radix hexadecimal} {{/mbi5153_frame_tb/ADDR[6]} -radix hexadecimal} {{/mbi5153_frame_tb/ADDR[5]} -radix hexadecimal} {{/mbi5153_frame_tb/ADDR[4]} -radix hexadecimal} {{/mbi5153_frame_tb/ADDR[3]} -radix hexadecimal} {{/mbi5153_frame_tb/ADDR[2]} -radix hexadecimal} {{/mbi5153_frame_tb/ADDR[1]} -radix hexadecimal} {{/mbi5153_frame_tb/ADDR[0]} -radix hexadecimal}} -subitemconfig {{/mbi5153_frame_tb/ADDR[13]} {-radix hexadecimal} {/mbi5153_frame_tb/ADDR[12]} {-radix hexadecimal} {/mbi5153_frame_tb/ADDR[11]} {-radix hexadecimal} {/mbi5153_frame_tb/ADDR[10]} {-radix hexadecimal} {/mbi5153_frame_tb/ADDR[9]} {-radix hexadecimal} {/mbi5153_frame_tb/ADDR[8]} {-radix hexadecimal} {/mbi5153_frame_tb/ADDR[7]} {-height 15 -radix hexadecimal} {/mbi5153_frame_tb/ADDR[6]} {-height 15 -radix hexadecimal} {/mbi5153_frame_tb/ADDR[5]} {-height 15 -radix hexadecimal} {/mbi5153_frame_tb/ADDR[4]} {-height 15 -radix hexadecimal} {/mbi5153_frame_tb/ADDR[3]} {-height 15 -radix hexadecimal} {/mbi5153_frame_tb/ADDR[2]} {-height 15 -radix hexadecimal} {/mbi5153_frame_tb/ADDR[1]} {-height 15 -radix hexadecimal} {/mbi5153_frame_tb/ADDR[0]} {-height 15 -radix hexadecimal}} /mbi5153_frame_tb/ADDR
add wave -noupdate /mbi5153_frame_tb/DCLK
add wave -noupdate /mbi5153_frame_tb/LATCH
add wave -noupdate /mbi5153_frame_tb/R
add wave -noupdate -divider {Internal (_frame)}
add wave -noupdate -radix unsigned /mbi5153_frame_tb/mbi5153_frame_inst/line_cnt
add wave -noupdate -radix unsigned /mbi5153_frame_tb/mbi5153_frame_inst/fsm_tx_fr
add wave -noupdate /mbi5153_frame_tb/mbi5153_frame_inst/frame_tx_start
add wave -noupdate /mbi5153_frame_tb/mbi5153_frame_inst/frame_tx_run
add wave -noupdate /mbi5153_frame_tb/mbi5153_frame_inst/frame_tx_done
add wave -noupdate -radix unsigned /mbi5153_frame_tb/mbi5153_frame_inst/base_addr
add wave -noupdate -divider {Internal (_data)}
add wave -noupdate -radix unsigned /mbi5153_frame_tb/mbi5153_data_inst/ic_cnt
add wave -noupdate /mbi5153_frame_tb/mbi5153_data_inst/mem_addr_load
add wave -noupdate /mbi5153_frame_tb/mbi5153_data_inst/mem_addr_dec
add wave -noupdate -radix unsigned /mbi5153_frame_tb/mbi5153_data_inst/mem_addr
add wave -noupdate /mbi5153_frame_tb/mbi5153_data_inst/data_load
add wave -noupdate /mbi5153_frame_tb/mbi5153_data_inst/ch_num_dec
add wave -noupdate -radix unsigned /mbi5153_frame_tb/mbi5153_data_inst/ch_num
add wave -noupdate -radix unsigned /mbi5153_frame_tb/mbi5153_data_inst/fsm_tx_ln_next_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {221850000 ps} 0}
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
WaveRestoreZoom {0 ps} {490007260 ps}
