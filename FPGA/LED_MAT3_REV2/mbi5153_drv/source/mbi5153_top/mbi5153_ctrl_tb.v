//******************************************************************************
// MBI5153 main FSM - TESTBENCH
//
// Author:  Dim Su
// Initial date: 20180106
// Release History:
//
//******************************************************************************

// synopsys translate_off
`timescale 1 ns / 10 ps
// synopsys translate_on

`default_nettype none

module mbi5153_ctrl_tb ();

parameter VSYNC_STB_DIV = 200; // VSYNC strobe will be active each VSYNC_STB_DIV's clock
parameter EOS_STB_DIV   = 80; 

// input signals for the DUT
reg RESET, CLK; 
reg EOS;                      // end of frame scanning
reg VSYNC_STB;                // vertical sync
reg RECONFIG_DONE;
reg UPDATE_GS_DONE;
reg CMD_DONE;

wire RECONFIG_REQ;
wire UPDATE_GS_REQ;
wire VSYNC_CMD_REQ;
wire GCLK_DISPLAY, GCLK_ON_OFF;

reg [7:0] vsync_stb_cnt;
reg [7:0] eos_stb_cnt;

// DUT
mbi5153_ctrl
#( 
 .DEBUG_MODE ("YES"),
 .GCLK_DCLK_RATIO (2),
 .GCLK_CLOCKS_BEFORE_VSYNC (6),
 .GCLK_STOP_AFTER_VSYNC (8)
)
mbi5153_ctrl_inst
(
 .CLK (CLK), .RESET (RESET),
 .VSYNC_STB (VSYNC_STB),
 .RECONFIG_REQ (RECONFIG_REQ),    // request for (re-)configuration
 .UPDATE_GS_REQ (UPDATE_GS_REQ),  // update GS data request
 .VSYNC_CMD_REQ (VSYNC_CMD_REQ),  // Driver VSYNC command
 .RECONFIG_DONE (RECONFIG_DONE),
 .UPDATE_GS_DONE (UPDATE_GS_DONE),
 .CMD_DONE (CMD_DONE),            // command proceeded
 .EOS (EOS),                      // end of scan strobe
 .GCLK_DISPLAY (GCLK_DISPLAY),    // 0 - "external" control, 1 - display frame
 .GCLK_ON_OFF (GCLK_ON_OFF)       // GCLK state during "external" controlling
);

//******************************************************************************
task automatic tsk_eos_gs_cycle;
 begin
  //vsync_stb_cnt > 1 here, a gs update will be requested when vsync_stb come
//   #10000  EOS = 1;
//   #100    EOS = 0;

   $display("Waiting for UPDATE_GS_REQ");  
   wait (UPDATE_GS_REQ == 1'b1);
   wait (UPDATE_GS_REQ == 1'b0);

   #2000 UPDATE_GS_DONE = 1;
   #100  UPDATE_GS_DONE = 0;

  // the VSYNC_CMD_REQ will be generated at this point; we have to wait it and reply with CMD_DONE
   $display("Waiting for VSYNC_CMD_REQ");  
   wait (VSYNC_CMD_REQ == 1'b1);
   wait (VSYNC_CMD_REQ == 1'b0);
   #200 CMD_DONE = 1;
   #100 CMD_DONE = 0;
 end  
endtask
//******************************************************************************
// main test stimilus 
initial                                                
 begin
 $display("Running testbench");                       

 CLK = 0; RESET = 0;
 EOS = 0;
 VSYNC_STB = 0;
 RECONFIG_DONE = 0; UPDATE_GS_DONE = 0; CMD_DONE = 0;
 
 #100  RESET = 1;
 #100  RESET = 0;

 // put End Of Scan; vsync_stb_ctn == 0 here, thus the reconfig will be requested
// #30000  EOS = 1;
// #100    EOS = 0;
 
 $display("Waiting for RECONFIG_REQ");  
 wait (RECONFIG_REQ == 1'b1);
 wait (RECONFIG_REQ == 1'b0);

 #1000 RECONFIG_DONE = 1;
 #100  RECONFIG_DONE = 0;
 
 tsk_eos_gs_cycle();
 #2000 RESET = 0;
 tsk_eos_gs_cycle();
 #2000 RESET = 0;
 tsk_eos_gs_cycle();
 #2000 RESET = 0;
 tsk_eos_gs_cycle();
 
 #200000  $display("Simulation Paused");  
 $stop;
 
 end                                                    

//******************************************************************************
// clock 'DCLK'
always                                                 
 begin                                                  
  #50 CLK = ! CLK; // 10MHz clock
 end
 
//******************************************************************************
// VSYNC strobe
always @(posedge CLK or posedge RESET)
  if (RESET)                 vsync_stb_cnt <= VSYNC_STB_DIV;                                               
  else
    if (vsync_stb_cnt != 0)  vsync_stb_cnt <= vsync_stb_cnt - 1;
    else                     vsync_stb_cnt <= VSYNC_STB_DIV;
      
always @(posedge CLK or posedge RESET)
  if (RESET)  VSYNC_STB <= 0;
  else        VSYNC_STB <= (vsync_stb_cnt == 0);
//******************************************************************************
// EOS strobe
always @(posedge CLK or posedge RESET)
  if (RESET)                                           eos_stb_cnt <= EOS_STB_DIV;
  else
    if ((GCLK_DISPLAY == 1'b0) || (eos_stb_cnt == 0))  eos_stb_cnt <= EOS_STB_DIV;
    else                                               eos_stb_cnt <= eos_stb_cnt - 1;
      
always @(posedge CLK or posedge RESET)
  if (RESET)                              EOS <= 0;
  else 
    if ((EOS == 0) && (eos_stb_cnt == 0)) EOS <= 1;
      else                                EOS <= 0;
  
endmodule

