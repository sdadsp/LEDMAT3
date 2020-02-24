//******************************************************************************
// MBI5153 commands
// the module sends a selected command
// Author:  Dim Su
// Initial date: 20171026
// Release History:
// 20171225 - extended to the 3 output wires: r/g/b; the LATCH paremeters moved to '_defines.vh'
// 20180113 - demux of WRC3 added; corrections related to the randon ICs number (in a chain) added
// 20180113 - simulation done
// 20170127 - inverted CLK for generating DCLK
//******************************************************************************

// synopsys translate_off
`timescale 1 ns / 10 ps
// synopsys translate_on

`default_nettype none

// define the propagation delay (for simulation)
`define PD 0


module mbi5153_commands
#(
// parameter DEFINES_H = "../../source/mbi5153_common/mbi5153_defines.vh",
 parameter NUM_IC_CHAIN = 4  // TBD: preferrable values are 2^n
)
(
 input wire CLK,             // main clock, also will be used as the DCLK
 input wire RESET,
 input wire REQUEST,         // request to send a CMD
 input wire [3:0]  CMD,
 input wire [15:0] DATA_R,   // some of the commands care of data (e.g. writes to the config. registers)...
 input wire [15:0] DATA_G,
 input wire [15:0] DATA_B,
 
 output wire READY,          // the REQUEST may be applied when this signal is active
 output wire ACTIVE,         // shows that the cmd execution is running
 output wire DCLK, DCLK_ENA, // serial clock, derived from CLK
 output wire LATCH,          // LATCH signal, determines a command
 output wire R, G, B,        // output wire data (actually, shifted DATA out)
 
 output wire CMD_DONE        // this strobe shows that a command comletely done
);

//******************************************************************************
//`include "mbi5153_defines.vh"

//`include "..\mbi5153_common\mbi5153_defines.vh"
//`include "mbi5153_defines.vh"
//`include DEFINES_H
`include "../../source/mbi5153_common/mbi5153_defines.vh"

localparam IC_WORD_LENGTH = 16;
localparam NUM_IC_CHAIN_MAX = 32;
localparam DCLK_CNT_WIDTH = $clog2(IC_WORD_LENGTH*NUM_IC_CHAIN_MAX);
localparam IC_CNT_WIDTH   = $clog2(NUM_IC_CHAIN_MAX);

//******************************************************************************
reg [DCLK_CNT_WIDTH-1:0] dclk_cnt;  // cmd_run phase length
reg [DCLK_CNT_WIDTH-1:0] latch_cnt; // time to rise up LATCH

reg [3:0]  cmd;
reg [15:0] data [2:0];               // r, g, b
//reg [IC_CNT_WIDTH-1:0] ic_chain_num; // number of the driver's ICs in the chain (32 ICs maximum)

reg request, ready;
wire dclk;
reg dclk_ena;
reg latch;
wire q_r, q_g, q_b;

reg cmd_start, cmd_run, cmd_run_dly, cmd_done;

wire fsm_drv_ena = 1;

//******************************************************************************
assign READY  = ready;
assign ACTIVE = cmd_run;
assign LATCH  = latch;
assign DCLK   = dclk, DCLK_ENA = dclk_ena;

assign R      = q_r, G = q_g, B = q_b;

assign CMD_DONE = cmd_done;

//******************************************************************************
// delaying cmd_run for a late data shift enablig
always @(posedge CLK) cmd_run_dly <= cmd_run;

//******************************************************************************
// DCLK, LATCH, and DATA output wires
// dclk_cnt sets a number of active DCLK clocks
reg dclk_ena_dly;       // delay register for DCLK enable, for aligning 1st DCLK and LATCH
always @(negedge CLK)   // !!! here the NEGedge CLK used to provide correct DCLK forming 
 begin
//   #`PD dclk_ena <= (dclk_cnt != 0);
        dclk_ena_dly <= (dclk_cnt != 0);
   #`PD dclk_ena <= dclk_ena_dly;
 end

assign dclk   = dclk_ena ? ~CLK : 1'b0; // inverted CLK to align the rising edge to the middle of DATA

assign q_r    = data[2][15], q_g = data[1][15], q_b = data[0][15];

//------------------------------------------------------------------------------
// enable LATCH when latch_cnt == 0
// latch_cnt sets a number of clocks before switching LATCH to high level
always @(posedge CLK or posedge RESET) // pos-edge CLK 
 if (RESET)      #`PD latch <= 0;
 else
   if ((cmd_run) && (latch_cnt == 0))
                 #`PD latch <= 1;
   else          #`PD latch <= 0;

//******************************************************************************
//******************************************************************************
// main FSM
 localparam FSM_CMD_IDLE = 0,
            FSM_CMD_SEL  = 1,
            FSM_CMD_RUN  = 2,
            FSM_CMD_DONE = 3;
//------------------------------------------------------------------------------
// main FSM registered block
reg [2:0] fsm_cmd, fsm_cmd_next_state;
always @(posedge CLK or posedge RESET)
 if (RESET)             #`PD fsm_cmd <= FSM_CMD_IDLE;
 else if (fsm_drv_ena)  #`PD fsm_cmd <= fsm_cmd_next_state;

//------------------------------------------------------------------------------
// main FSM combinational block 
//always @(fsm_cmd or request or dclk_cnt)
always @(posedge CLK or posedge RESET)
if (RESET)             #`PD fsm_cmd_next_state <= FSM_CMD_IDLE;
else
begin: main_fsm
// case (fsm_cmd)
 case (fsm_cmd_next_state)
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
   FSM_CMD_IDLE:
    begin
                  cmd_start <= 0; cmd_run <= 0; cmd_done <= 0;
     if (request) 
       begin 
                  cmd_start <= 1;              // loading dclk_cnt and latch_cnt
                  fsm_cmd_next_state <= FSM_CMD_SEL;
       end
    end
//- - - Choosing a number of CMD_DL_DCLKs according to CMD code - - - - - - - - 
   FSM_CMD_SEL:
    begin
                  cmd_start <= 0;
                  cmd_run   <= 1;
                  fsm_cmd_next_state <= FSM_CMD_RUN;
    end
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
   FSM_CMD_RUN:
    begin
     if (dclk_cnt == 0)
       begin
                  cmd_run   <= 0;
                  fsm_cmd_next_state <= FSM_CMD_DONE;
       end
    end
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
   FSM_CMD_DONE:
    begin
                  cmd_done  <= 1;
                  fsm_cmd_next_state <= FSM_CMD_IDLE;
    end
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
   default:
    begin
//      cmd_start <= 0; cmd_run <= 0; cmd_done <= 0;
      fsm_cmd_next_state <= FSM_CMD_IDLE;
    end
    
 endcase
end //main_fsm

//******************************************************************************
//******************************************************************************
// store CMD code
always @(posedge CLK or posedge RESET)
 if (RESET)
   begin   cmd <= 0;   end
   else if (REQUEST)
     begin cmd <= CMD; end

//------------------------------------------------------------------------------
// store and shift (cyclic - to support multiple ICs in the chain) out the DATA
wire is_cmd_wrc = ((cmd == CMD_WRC1) || (cmd == CMD_WRC2) || (cmd == CMD_WRC3));
always @(posedge CLK or posedge RESET)
 if (RESET)
   begin
            #`PD data[2] <= 0; #`PD data[1] <= 0; #`PD data[0] <= 0; 
   end
   else if ( REQUEST )
     begin
	   	    #`PD data[2] <= DATA_R; #`PD data[1] <= DATA_G; #`PD data[0] <= DATA_B;
     end
        else if (cmd_run_dly & is_cmd_wrc)
		  begin
            #`PD data[2] <= {data[2][14:0], data[2][15]}; // cyclic shift left
            #`PD data[1] <= {data[1][14:0], data[1][15]}; 
            #`PD data[0] <= {data[0][14:0], data[0][15]}; 
          end
                  
//******************************************************************************
// DCLK and LATCH counters control 
// (to put out a desired number of the DCLKs and a LATCH signal at the exact position related to the DCLK sequence)
always @(posedge CLK or posedge RESET)
 if (RESET)
   begin          dclk_cnt <= 0; latch_cnt <= 0;
   end
 else
 begin
  if (cmd_start)
   case (cmd)
   CMD_STOP_CED:
     begin        dclk_cnt  <= CMD_STOP_CED_DCLK*NUM_IC_CHAIN;
                  latch_cnt <= 0;                 // '0' value here means that the LATCH signal will be output wire with DCLK simultaneuosly
     end
   CMD_DL:        
     begin        dclk_cnt  <= CMD_DL_DCLK*NUM_IC_CHAIN;
                  latch_cnt <= 0;
     end
   CMD_VSYNC:     
     begin        dclk_cnt  <= CMD_VSYNC_DCLK;
                  latch_cnt <= 0;
     end
   CMD_PREA:   
     begin        dclk_cnt  <= CMD_PREA_DCLK;
                  latch_cnt <= 0;
     end
   CMD_WRC1:
     begin        dclk_cnt  <= 16*NUM_IC_CHAIN;
                  latch_cnt <= 16*NUM_IC_CHAIN - CMD_WRC1_DCLK;
     end
   CMD_WRC2:
     begin        dclk_cnt  <= 16*NUM_IC_CHAIN;
                  latch_cnt <= 16*NUM_IC_CHAIN - CMD_WRC2_DCLK;
     end
   CMD_WRC3:
     begin        dclk_cnt  <= 16*NUM_IC_CHAIN;
                  latch_cnt <= 16*NUM_IC_CHAIN - CMD_WRC3_DCLK;
     end
   CMD_START_CED:
     begin        dclk_cnt  <= CMD_START_CED_DCLK;
                  latch_cnt <= 0;
     end
   CMD_SRST:
     begin        dclk_cnt  <= CMD_SRST_DCLK;
                  latch_cnt <= 0;
     end
   CMD_RDC1:      
     begin        dclk_cnt  <= CMD_RDC1_DCLK;
                  latch_cnt <= 0;
     end
   CMD_RDC2:
     begin        dclk_cnt  <= CMD_RDC2_DCLK;
                  latch_cnt <= 0;
     end
   default:
     begin        dclk_cnt  <= CMD_DL_DCLK;   // default
                  latch_cnt <= 0;
     end
   endcase
  else if (cmd_run)
    begin
     if (dclk_cnt)  #`PD dclk_cnt  <= dclk_cnt - 1;
     if (latch_cnt) #`PD latch_cnt <= latch_cnt - 1;
    end
 end
 
//******************************************************************************
// request-ready fsm
fsm_rq_rdy fsm_rq_rdy_inst (
 .CLK (CLK), .RESET (RESET),                 // inputs
 .REQ (REQUEST), .ACK (cmd_start), .DONE (cmd_done),
 .REQUEST_LATCH (request), .READY (ready)    // outputs
);

//******************************************************************************
 
endmodule
