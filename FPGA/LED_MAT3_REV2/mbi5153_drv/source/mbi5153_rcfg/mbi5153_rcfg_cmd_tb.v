//******************************************************************************
// MBI5153 Configuration registers' programming (with command's module) - TESTBENCH
//
// Author:  Dim Su
// Initial date: 20180112
// Release History:
// 20180113 - simulation done
//******************************************************************************

// synopsys translate_off
`timescale 1 ns / 10 ps
// synopsys translate_on

`default_nettype none

module mbi5153_rcfg_cmd_tb ();

`include "../../source/mbi5153_common/mbi5153_defines.vh"
parameter NUM_IC_CHAIN = 3;

// input signals for the DUT
reg RESET, CLK; 
reg REQUEST; 

wire [1:0] index;
wire RCFG_READY, RCFG_ACTIVE, RCFG_DONE;

wire DCLK, LATCH, R, G, B;

wire cmd_ready, cmd_active, cmd_done;

reg [3:0] cmd;          // command code
reg [15:0] data [2:0]; // DATA[2] = R, DATA[1] = G, DATA[0] = B

wire request_prea, request_rcfg;
wire request;

// DUT1
mbi5153_rcfg  mbi5153_rcfg_inst
(
 .CLK (CLK), .RESET (RESET),
 .REQUEST_IN (REQUEST),     // request for (re-)configuration
 
 .CFG_WORD_ADDR (index),    // data/cmd index
 
 .REQUEST_TO_SEND_PREA_CMD (request_prea),
 .REQUEST_TO_SEND_RCFG_CMD (request_rcfg),
 .CMD_DONE (cmd_done),      // command proceeded
 
 .IF_READY (cmd_ready),     // input - the REQUEST_TO_SEND_CMD will be applied this signal is active
 
 .READY (RCFG_READY),            
 .ACTIVE (RCFG_ACTIVE),     // shows that the cmd execution is running
 .DONE (RCFG_DONE)
);

// DUT2
mbi5153_commands
#( .NUM_IC_CHAIN(NUM_IC_CHAIN) )
mbi5153_cmd_inst
// port map - connection between master ports and signals/registers   
(
 .CLK (CLK),
 .RESET (RESET),
 .REQUEST (request),
 .CMD (cmd),        //  input wire [3:0]  CMD
 .DATA_R (data[2]), .DATA_G (data[1]), .DATA_B (data[0]),
 
 .READY (cmd_ready),
 .ACTIVE (cmd_active),
 .DCLK (DCLK),
 .LATCH (LATCH),
 .R (R), .G (G), .B (B),
 .CMD_DONE (cmd_done)
);

//******************************************************************************
always @*
 if (request_prea) cmd <= CMD_PREA;
 else
   case (index)
     0:            cmd <= CMD_WRC1;
     1:            cmd <= CMD_WRC2;
     2:            cmd <= CMD_WRC3;
     3:            cmd <= CMD_WRC1;
     default:      cmd <= CMD_WRC1;
   endcase

always @*
 case (index)
     0:  begin data[2] <= DATA_RCFG1_R; data[1] <= DATA_RCFG1_G; data[0] <= DATA_RCFG1_B; end
     1:  begin data[2] <= DATA_RCFG2_R; data[1] <= DATA_RCFG2_G; data[0] <= DATA_RCFG2_B; end
     2:  begin data[2] <= DATA_RCFG3_R; data[1] <= DATA_RCFG3_G; data[0] <= DATA_RCFG3_B; end
     3:  begin data[2] <= DATA_RCFG1_R; data[1] <= DATA_RCFG1_G; data[0] <= DATA_RCFG1_B; end
     default:
         begin data[2] <= DATA_RCFG1_R; data[1] <= DATA_RCFG1_G; data[0] <= DATA_RCFG1_B; end
 endcase
   
assign request = request_prea | request_rcfg;
   
//******************************************************************************
// main test stimilus 
initial                                                
 begin
 $display("Running testbench");                       

 CLK = 0; RESET = 0;
 REQUEST  = 0;
 
 #100  RESET = 1;
 #100  RESET = 0;

 #200  REQUEST = 1;
 #100  REQUEST = 0;

 
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

