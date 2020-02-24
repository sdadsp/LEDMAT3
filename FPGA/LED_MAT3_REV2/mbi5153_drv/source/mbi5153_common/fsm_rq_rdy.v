//******************************************************************************
// simple request/ready FSM
// 
// 1) Waits for the REQUEST signal and latches it (REQUEST_LATCH)
// 2) Then waits for a confirmation from the connected logic (ACK)
// 3) Pulls down the READY signal
// 4) Waits for confirming from the external logic about completing a processing (DONE)
// 5) Rises up the READY signal and waits for a next REQUEST
// inputs:
// output: 
//
// Author:  Dim Su
// Initial date: 20171213
// Release History:
// 20180112 - ready signal behavior changed
// 20180113 - IDLE state added
//
//******************************************************************************
//           ______                    ________ 
// READY           |__________________| 
//                _ 
// REQ        ___| |___________________________
//                  ______  
// REQ_LATCH  _____|      |____________________
//                       __
// ACK        __________|  |___________________ 
//                                   _ 
// DONE       ______________________| |________
//
//******************************************************************************

// synopsys translate_off
`timescale 1 ns / 10 ps
// synopsys translate_on

//`default_nettype none

// define the propagation delay (for simulation)
`define PD 0

module fsm_rq_rdy (
 input CLK,
 input RESET,
 input REQ,
 input ACK,
 input DONE,
 
 output REQUEST_LATCH,
 output READY
);
//******************************************************************************
reg request, ready;
wire main_fsm_start, main_fsm_done;

//******************************************************************************
assign REQUEST_LATCH = request;
assign READY = ready;

assign main_fsm_start = ACK;
assign main_fsm_done  = DONE;

//******************************************************************************
// request-ready fsm
reg [1:0] fsm_rq_rdy;

always @(posedge CLK or posedge RESET)
 if (RESET)
   begin
            fsm_rq_rdy <= 0;
            request    <= 0;
            ready      <= 1;
   end
 else 
 case (fsm_rq_rdy)
//- - - - IDLE State - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  0:
   begin
           #`PD request    <= 0;
           #`PD ready      <= 1;
           #`PD fsm_rq_rdy <= 1;
   end
//- - - - wait for the REQUEST signal - - - - - - - - - - - - - - - - - - - - - 
  1:
   begin
    if (REQ & ready)
      begin
           #`PD request    <= 1;
           #`PD ready      <= 0;
           #`PD fsm_rq_rdy <= 2;
      end
   end
//- - - - wait for the main FSM start - - - - - - - - - - - - - - - - - - - - - 
  2:
   begin
    if (main_fsm_start)
      begin
           #`PD request    <= 0;
           #`PD fsm_rq_rdy <= 3;
      end
   end
//- - - - wait for the command sending completing - - - - - - - - - - - - - - - 
  3:
   begin
    if (main_fsm_done)
      begin
           #`PD fsm_rq_rdy <= 0;
      end
   end
//- - - - error condition - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  default:
   begin
            fsm_rq_rdy <= 0;
   end
 endcase
//******************************************************************************

endmodule
