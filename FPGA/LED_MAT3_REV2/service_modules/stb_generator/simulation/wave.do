onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /strobe_generator_tb/CLK
add wave -noupdate /strobe_generator_tb/strobe_1k
add wave -noupdate /strobe_generator_tb/strobe_50hz
add wave -noupdate /strobe_generator_tb/strobe_gen_1k_from_10M/stb_5
add wave -noupdate /strobe_generator_tb/strobe_gen_1k_from_10M/stb_1
add wave -noupdate -radix unsigned -childformat {{{/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[14]} -radix unsigned} {{/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[13]} -radix unsigned} {{/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[12]} -radix unsigned} {{/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[11]} -radix unsigned} {{/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[10]} -radix unsigned} {{/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[9]} -radix unsigned} {{/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[8]} -radix unsigned} {{/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[7]} -radix unsigned} {{/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[6]} -radix unsigned} {{/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[5]} -radix unsigned} {{/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[4]} -radix unsigned} {{/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[3]} -radix unsigned} {{/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[2]} -radix unsigned} {{/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[1]} -radix unsigned} {{/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[0]} -radix unsigned}} -subitemconfig {{/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[14]} {-height 15 -radix unsigned} {/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[13]} {-height 15 -radix unsigned} {/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[12]} {-height 15 -radix unsigned} {/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[11]} {-height 15 -radix unsigned} {/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[10]} {-height 15 -radix unsigned} {/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[9]} {-height 15 -radix unsigned} {/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[8]} {-height 15 -radix unsigned} {/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[7]} {-height 15 -radix unsigned} {/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[6]} {-height 15 -radix unsigned} {/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[5]} {-height 15 -radix unsigned} {/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[4]} {-height 15 -radix unsigned} {/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[3]} {-height 15 -radix unsigned} {/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[2]} {-height 15 -radix unsigned} {/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[1]} {-height 15 -radix unsigned} {/strobe_generator_tb/strobe_gen_1k_from_10M/prescaler[0]} {-height 15 -radix unsigned}} /strobe_generator_tb/strobe_gen_1k_from_10M/prescaler
add wave -noupdate -radix unsigned /strobe_generator_tb/strobe_gen_1k_from_10M/cnt50
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {562850 ps} 0} {{Cursor 2} {159887830630 ps} 0}
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
WaveRestoreZoom {0 ps} {2210820 ps}
