//******************************************************************************
// MBI5153 Configuration registers' programming - TESTBENCH
//
// Author:  Dim Su
// Initial date: 20180112
// Release History:
// 20180112 - simulation done (1st approach)
//
//******************************************************************************

// synopsys translate_off
`timescale 1 ns / 10 ps
// synopsys translate_on

`default_nettype none

module mbi5153_rcfg_tb ();

// input signals for the DUT
reg RESET, CLK; 
reg REQUEST; 
reg TX_READY;
reg CMD_DONE;

wire [1:0] INDEX;
wire READY, ACTIVE, DONE;

wire REQUEST_PREA, REQUEST_RCFG;

// DUT
mbi5153_rcfg  mbi5153_rcfg_inst
(
 .CLK (CLK), .RESET (RESET),
 .REQUEST_IN (REQUEST),     // request for (re-)configuration
 .CFG_WORD_ADDR (INDEX),    // data/cmd index
 
 .REQUEST_TO_SEND_PREA_CMD (REQUEST_PREA),
 .REQUEST_TO_SEND_RCFG_CMD (REQUEST_RCFG),
 .CMD_DONE (CMD_DONE),      // command proceeded
 
 .IF_READY (TX_READY),      // input - the REQUEST_TO_SEND_CMD will be applied this signal is active
 
 .READY (READY),            
 .ACTIVE (ACTIVE),          // shows that the cmd execution is running
 .DONE (DONE)
);

//******************************************************************************
task /*automatic*/ tsk_request_wait;
input request_in;
 begin
   wait  (request_in == 1);
   wait  (request_in == 0);
//   if (request_in == 1'b1)
//    @(posedge request_in)
//     begin
       $display("at: %d ns:", $time);                       
       TX_READY = 0;
       #1000  CMD_DONE = 1;
       #100   CMD_DONE = 0;
       #150   TX_READY = 1;
       #50    TX_READY = 1;
//     end
 end  
endtask

//******************************************************************************
// main test stimilus 
initial                                                
 begin
 $display("Running testbench");                       

 CLK = 0; RESET = 0;
 REQUEST  = 0;
 TX_READY = 1;
 CMD_DONE = 0;
 
 #100  RESET = 1;
 #100  RESET = 0;

 #200  REQUEST = 1;
 #100  REQUEST = 0;

// RCFG2
       wait (REQUEST_PREA == 1);
       wait (REQUEST_PREA == 0);
       $display("at: %d ns:", $time);                       
       TX_READY = 0;
       #1000  CMD_DONE = 1;
       #100   CMD_DONE = 0;
       #150   TX_READY = 1;
       #50    TX_READY = 1;
// tsk_request_wait (REQUEST_PREA);
 $display("PREA received");                       
       wait (REQUEST_RCFG == 1);
       wait (REQUEST_RCFG == 0);
       $display("at: %d ns:", $time);                       
       TX_READY = 0;
       #1000  CMD_DONE = 1;
       #100   CMD_DONE = 0;
       #150   TX_READY = 1;
       #50    TX_READY = 1;
// tsk_request_wait (REQUEST_RCFG);
 $display("RCFG received"); 

// RCFG1
       wait (REQUEST_PREA == 1);
       wait (REQUEST_PREA == 0);
       $display("at: %d ns:", $time);                       
       TX_READY = 0;
       #1000  CMD_DONE = 1;
       #100   CMD_DONE = 0;
       #150   TX_READY = 1;
       #50    TX_READY = 1;
// tsk_request_wait (REQUEST_PREA);
 $display("PREA received");                       
       wait (REQUEST_RCFG == 1);
       wait (REQUEST_RCFG == 0);
       $display("at: %d ns:", $time);                       
       TX_READY = 0;
       #1000  CMD_DONE = 1;
       #100   CMD_DONE = 0;
       #150   TX_READY = 1;
       #50    TX_READY = 1;
// tsk_request_wait (REQUEST_RCFG);
 $display("RCFG received"); 
 
// RCFG0
       wait (REQUEST_PREA == 1);
       wait (REQUEST_PREA == 0);
       $display("at: %d ns:", $time);                       
       TX_READY = 0;
       #1000  CMD_DONE = 1;
       #100   CMD_DONE = 0;
       #150   TX_READY = 1;
       #50    TX_READY = 1;
// tsk_request_wait (REQUEST_PREA);
 $display("PREA received");                       
       wait (REQUEST_RCFG == 1);
       wait (REQUEST_RCFG == 0);
       $display("at: %d ns:", $time);                       
       TX_READY = 0;
       #1000  CMD_DONE = 1;
       #100   CMD_DONE = 0;
       #150   TX_READY = 1;
       #50    TX_READY = 1;
// tsk_request_wait (REQUEST_RCFG);
 $display("RCFG received"); 

 
 #100000  $display("Simulation Paused");  
 $stop;
 
 end                                                    

//******************************************************************************
// clock 
always                                                 
 begin                                                  
  #50 CLK = ! CLK; // 10MHz clock
 end
 
endmodule

