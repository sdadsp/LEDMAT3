// 1kHz _strobe_ generator - testbench
// Author: Dim Su


// synopsys translate_off
`timescale 1 ns / 10 ps
// synopsys translate_on

`default_nettype none

module strobe_generator_tb ();

reg CLK;
wire strobe_1k;
wire strobe_50hz;

strobe_gen_1k_50_5_1 
#( .INPUT_FREQUENCY_KHZ (10000) )
strobe_gen_1k_from_10M
(
	.CLK (CLK),
 	.STB_1K (strobe_1k), .STB_50 (strobe_50hz)
);


//******************************************************************************

// main test stimilus 
initial                                                
 begin
 $display("Running testbench");                       

 CLK = 0;
 
 #200000000  $display("Simulation Paused");  
 $stop;
 
 end                                                    


//******************************************************************************
// clock 'DCLK'
always                                                 
 begin                                                  
  #50 CLK = ! CLK; // 10MHz clock
 end

 endmodule
 