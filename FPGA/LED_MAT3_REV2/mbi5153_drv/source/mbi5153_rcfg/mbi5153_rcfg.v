//******************************************************************************
// MBI5153 configuration registers programming
// 
// (re-)configuration of the drivers' chain:
//  1) set x = 2 (x = 3 for ICN2053)
//  2) requesting for PREA command; waiting for completing
//  3) sending the RCFG[x] command (Programming Configuration Register [x])
//  4) waiting for completing command
//  5) if (x == 0) goto (6), else { x--; goto (2) }
//  6) generating DONE strobe; Finish
//
// Author:  Dim Su
// Initial date: 20180108
// Release History:
// 20180112 - simulation done (1st approach)
// 20180113 - sim done (2nd approach)
// 
//******************************************************************************

// synopsys translate_off
`timescale 1 ns / 10 ps
// synopsys translate_on

`default_nettype none

// define the propagation delay (for simulation)
`define PD 0

module mbi5153_rcfg
(
input wire CLK,
input wire RESET,
 
input wire  REQUEST_IN,     // request to send a CMD
output wire [1:0] CFG_WORD_ADDR, // config vector's address (0,1,2 - for RCFG1/2/3)
 
output wire REQUEST_TO_SEND_PREA_CMD,
output wire REQUEST_TO_SEND_RCFG_CMD,
input wire  CMD_DONE,       // input - command sent
 
input wire  IF_READY,       // input - the REQUEST_TO_SEND_CMD will be applied this signal is active
 
output wire READY,          // the REQUEST may be applied when this signal is active
output wire ACTIVE,         // shows that the cmd execution is running
output wire DONE            // this strobe shows that a command comletely done
);

//******************************************************************************
localparam RCFG_INIT_INDEX = 2; // index will be conunted from 2 downto 0

//******************************************************************************
reg [1:0] rcfg_cnt;
reg rcfg_cnt_ena, rcfg_cnt_load;
reg rcfg_ready, rcfg_active, rcfg_done;
reg request_prea, request_rcfg;

wire request_in  = REQUEST_IN;
wire cmd_tx_done = CMD_DONE;
wire cmd_tx_ready = IF_READY;

assign CFG_WORD_ADDR = rcfg_cnt;
assign ACTIVE = rcfg_active, READY = rcfg_ready, DONE = rcfg_done;

assign REQUEST_TO_SEND_PREA_CMD = request_prea, REQUEST_TO_SEND_RCFG_CMD = request_rcfg;

//******************************************************************************
// config register data (and appropriated command) index
always @(posedge CLK or posedge RESET)
 if (RESET)            rcfg_cnt <= RCFG_INIT_INDEX;
 else
   if (rcfg_cnt_load)  rcfg_cnt <= RCFG_INIT_INDEX;
   else
     if (rcfg_cnt_ena) rcfg_cnt <= rcfg_cnt - 1;

//******************************************************************************
// FSM
localparam FSM_RCFG_IDLE          = 0,
           FSM_RCFG_PREA          = 1,
           FSM_RCFG_WAIT_PREA     = 2,
           FSM_RCFG_RCFG          = 3,
           FSM_RCFG_WAIT_RCFG     = 4,
           FSM_RCFG_DONE          = 5;

// cfg regs fsm
reg [2:0] fsm_rcfg, fsm_rcfg_next_state;

// registered block
always @(posedge CLK or posedge RESET)
 if (RESET)   fsm_rcfg <= FSM_RCFG_IDLE;
 else         fsm_rcfg <= fsm_rcfg_next_state;

// comb block
//always @(fsm_rcfg or request_in or cmd_tx_ready or cmd_tx_done or rcfg_cnt)
always @(posedge CLK or posedge RESET)
 if (RESET)   fsm_rcfg_next_state <= FSM_RCFG_IDLE;
 else
// case (fsm_rcfg)
 case (fsm_rcfg_next_state)
//- - - - wait for the REQUEST signal - - - - - - - - - - - - - - - - - - - - - 
  FSM_RCFG_IDLE:
   begin
     rcfg_ready    <= 1; rcfg_active    <= 0; rcfg_done <= 0; 
     rcfg_cnt_ena  <= 0; rcfg_cnt_load  <= 0;
     request_prea  <= 0; request_rcfg <= 0;
            
    if (request_in)
      begin
         rcfg_active   <= 1;  // set ACTIVE flag
         rcfg_cnt_load <= 1;  // load data/cmd index
         fsm_rcfg_next_state <= FSM_RCFG_PREA;
      end
   end
//- - - - set PRE-ACTIVE - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  FSM_RCFG_PREA:
   begin
     rcfg_cnt_load <= 0; rcfg_cnt_ena <= 0;
     if (cmd_tx_ready)
       begin
         rcfg_ready   <= 0;
         request_prea <= 1;
         fsm_rcfg_next_state <= FSM_RCFG_WAIT_PREA;
       end
   end
//- - - - wait for CMD PREA DONE - - - - - - - - - - - - - - - - - - - - - - - -
  FSM_RCFG_WAIT_PREA:
   begin
     request_prea <= 0;
     if (cmd_tx_done)
         fsm_rcfg_next_state <= FSM_RCFG_RCFG;
   end
//- - - - send RCFG REQUEST  - - - - - - - - - - - - - - - - - - - - - - - - - -
  FSM_RCFG_RCFG:
   begin
     if (cmd_tx_ready)
       begin
        request_rcfg <= 1;
        fsm_rcfg_next_state <= FSM_RCFG_WAIT_RCFG;
       end
   end
//- - - - wait for CMD RCFG DONE - - - - - - - - - - - - - - - - - - - - - - - -
  FSM_RCFG_WAIT_RCFG:
   begin
     request_rcfg <= 0;
     if (cmd_tx_done)
       begin
         if (rcfg_cnt != 0)
           begin
               rcfg_cnt_ena <= 1;  // enable decrement of the index counter
               fsm_rcfg_next_state <= FSM_RCFG_PREA;
           end
         else  fsm_rcfg_next_state <= FSM_RCFG_DONE;        
           
       end
   end
//- - - - generating a DONE strobe - - - - - - - - - - - - - - - - - - - - - - -
  FSM_RCFG_DONE:
   begin
     rcfg_done <= 1;
     fsm_rcfg_next_state <= FSM_RCFG_IDLE;
   end
//- - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  default:
   begin
//     rcfg_ready    <= 1; rcfg_active    <= 0; rcfg_done <= 0; 
//     rcfg_cnt_ena  <= 0; rcfg_cnt_load  <= 0;
//     request_prea  <= 0; request_rcfg <= 0;

     fsm_rcfg_next_state <= FSM_RCFG_IDLE;
   end
 endcase
 
 
endmodule









