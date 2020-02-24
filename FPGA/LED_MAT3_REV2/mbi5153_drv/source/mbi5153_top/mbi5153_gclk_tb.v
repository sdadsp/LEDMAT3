//******************************************************************************
// MBI5153 GCLK and line switching (scan) control - TESTBENCH
//
// Author:  Dim Su
// Initial date: 20180103
// Release History:
//
//******************************************************************************

// synopsys translate_off
`timescale 1 ns / 10 ps
// synopsys translate_on

`default_nettype none

//`define SHORT_SIM

module mbi5153_gclk_tb ();

// input signals for the DUT
reg RESET, CLK; 
reg GCLK_DISPLAY, GCLK_ON_OFF;

wire EOS;
wire GCLK_OUT;
wire GCLK_ACTIVE;
wire [4:0] SCAN_LINE_ADDR;

// DUT
mbi5153_gclk
#(
 .DEBUG_MODE ("YES"),
`ifdef SHORT_SIM
 .PWM13_CYCLE_NUM_SECTIONS (2),
 .PWM14_CYCLE_NUM_SECTIONS (4),
 .PWM_CYCLE_GCLK_CLOCKS    (8),
 .GCLK_LINE_SWITCH_DEAD_TIME_H (3),
 .GCLK_LINE_SWITCH_DEAD_TIME_L (5) 
`else
 .PWM13_CYCLE_NUM_SECTIONS (16),
 .PWM14_CYCLE_NUM_SECTIONS (32),
 .PWM_CYCLE_GCLK_CLOCKS    (512),
 .GCLK_LINE_SWITCH_DEAD_TIME_H (6),
 .GCLK_LINE_SWITCH_DEAD_TIME_L (24) 
`endif
)
mbi5153_gclk_inst
(
 .RESET (RESET),
 .CLK (CLK),
 
 .GCLK_DISPLAY (GCLK_DISPLAY),
 .GCLK_ON_OFF (GCLK_ON_OFF),
 .SCAN_RATIO (5'd3), // 3 = 4 scan lines
 .PWM_DEPTH (1'b1),  // 0 = 13-bit, 1 = 14-bit; different PWM depths are related to different number of PWM-cycle sections
 
 .EOS (EOS),
 .GCLK_OUT (GCLK_OUT),
 .GCLK_ACTIVE (GCLK_ACTIVE),
 .SCAN_LINE_ADDR (SCAN_LINE_ADDR)
);

//******************************************************************************
// main test stimilus 
initial                                                
 begin
 $display("Running testbench");                       

 CLK = 0;
 RESET = 1'b1;
 GCLK_DISPLAY = 0;
 GCLK_ON_OFF = 0;
 
 #100  RESET = 0;
 
 #1000 GCLK_ON_OFF = 1;
 #1000 GCLK_ON_OFF = 0;
 #1000  GCLK_DISPLAY = 1;

 wait (EOS == 1'b1);
 wait (EOS == 1'b0);
 
 #50   GCLK_DISPLAY = 0;
 #1000 GCLK_ON_OFF = 1;
 #1000 GCLK_ON_OFF = 0;
 #1000 GCLK_DISPLAY = 1;
 
`ifdef SHORT_SIM
 #100000  $display("Simulation Paused");  
`else
 #10000000  $display("Simulation Paused");  
`endif
 $stop;
 
 end                                                    


//******************************************************************************
// clock 'GCLK_IN'
always                                                 
 begin                                                  
  #25 CLK = ! CLK; // 20MHz clock
 end

endmodule

