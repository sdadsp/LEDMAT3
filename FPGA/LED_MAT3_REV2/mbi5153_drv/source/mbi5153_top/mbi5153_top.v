//******************************************************************************
// MBI5153 control, sync, and data(frame) sending
//                1) Init config registers
//                2) Send frame data
//                3) Send VSync
//                4) Every 4 second go to (1)
//                5) Go to (2)
//
// also: proper GCLK control; periodical registers' config 
//
// Author:  Dim Su
// Initial date: 20171220
// Release History:
// 20171222 - work in progress
// 20171225 - frame sending (without cfg) is written
// 20180108 - final wirings
// 20180113 - checking and correcting connections
// 20180130 - extended to 2 RGB lanes
// 20180301 - parameter IMG_WIDTH added
// 20180505 - IMG_WIDTH parameter replaced with bus that connected to image_width register on the top level
//******************************************************************************

// synopsys translate_off
`timescale 1 ns / 10 ps
// synopsys translate_on

`default_nettype none

// define the propagation delay (for simulation)
`define PD 0


module mbi5153_top
#(
 parameter EXT_RAM_BASE_ADDR = 0,
 parameter NUM_CH_IC = 16,      //  Possible values: 8 (debug), 16 (real value)
 parameter NUM_IC_CHAIN = 4,
 parameter IC_WORD_LENGTH = 16, //  Possible values: 8 (debug), 16 (real value)
 parameter IMG_WIDTH_MAX = 64,
 parameter PWM_DEPTH = 1'b1,    //  1 - 14 bits, 0 - 13 bits
 parameter GCLK_DCLK_RATIO = 2,
 parameter IMG_WIDTH_MAX_LOG2 = $clog2(IMG_WIDTH_MAX + 1),
 parameter RCFG_VSYNC_NUM = 150,// how many VSYNC strobes we are waiting for reconfigure regs
 parameter NUMBER_OF_LANES = 3, // max. 3 lanes per panel
// parameter MEM_ADDR_WIDTH   = $clog2(NUM_IC_CHAIN*NUM_CH_IC*32) // 32 is a MAX Scan Ratio
 parameter MEM_ADDR_WIDTH   = $clog2(IMG_WIDTH_MAX*32) // 32 is a MAX Scan Ratio
)
(
 input wire DCLK_IN,             // main clock, also will be used as DCLK
 input wire RESET,
 
 input wire GCLK_IN,             // PWM CLOCK (input)
 input wire VSYNC_STB,           // frame sending request
 input wire [IMG_WIDTH_MAX_LOG2-1:0] IMG_WIDTH,
 input wire [4:0] SCAN_RATIO,    // scan ratio (number of the lines)
 
 input wire [15:0] RCFG_R [2:0], // RCFG_R[2/1/0] must be reflected to Config Regs [3/2/1] accordingly
 input wire [15:0] RCFG_G [2:0],
 input wire [15:0] RCFG_B [2:0],
 
 input wire [23:0] MEM0_DATA,    // RGB word TOP row
 input wire [23:0] MEM1_DATA,    // RGB word MID row
 input wire [23:0] MEM2_DATA,    // RGB word BOT row
 
 output wire [MEM_ADDR_WIDTH-1:0] MEM_ADDR,// pixel's address in the external memory

 output wire HUB_DCLK_ENA,                 // serial data clock is active
 output wire HUB_DCLK,                     // serial data clock, derived from CLK
 output wire [4:0] HUB_ADDR,
 output wire HUB_LATCH,                    // LATCH signal, determines a command
 output wire [NUMBER_OF_LANES-1:0] HUB_R, HUB_G, HUB_B, // output serialized data
 output wire HUB_GCLK,
 
 input  wire TEST_UPGS_ENA,
 output wire [1:0]TEST_PIN
);

//`include "..\mbi5153_common\mbi5153_defines.vh"
//`include "mbi5153_defines.vh"
`include "../../../define_led_driver.vh"
`include "../../source/mbi5153_common/mbi5153_defines.vh"

localparam LINE_ADDR_WIDTH   = $clog2(NUM_IC_CHAIN*NUM_CH_IC);
//localparam LINE_ADDR_WIDTH   = IMG_WIDTH_MAX_LOG2;
           
//******************************************************************************
// display the data below during compilation:
initial
 begin
   $display("********************* MBI5153 Top Module *****************************");
   $display("******* Num of ICs in the chain    %d *******", NUM_IC_CHAIN);
   $display("******* Num of the channels per IC %d *******", NUM_CH_IC);
   $display("******* Maximum Image width        %d *******", IMG_WIDTH_MAX);
   $display("******* Bus Width for -Image Width-%d *******", IMG_WIDTH_MAX_LOG2);
   $display("******* Line Address Bus Width     %d *******", LINE_ADDR_WIDTH);
   $display("******* Memory Address Bus Width   %d *******", MEM_ADDR_WIDTH);
   $display("**********************************************************************");
 end

//******************************************************************************
wire line_tx_ready, line_tx_active, line_tx_done;
wire line_tx_dclk, line_tx_dclk_ena, line_tx_latch;
wire [NUMBER_OF_LANES-1:0] line_tx_r, line_tx_g, line_tx_b;
wire frame_tx_ready, frame_tx_active, frame_tx_done;
wire cmd_tx_ready, cmd_tx_active, cmd_tx_done;
wire cmd_tx_dclk, cmd_tx_dclk_ena, cmd_tx_latch, cmd_tx_r, cmd_tx_g, cmd_tx_b;

wire reconfig_req, update_gs_req, vsync_cmd_req;

wire rcfg_done;
wire frame_eos_gclk, frame_eos_dclk;
wire gclk_display_gclk, gclk_display_dclk;
wire gclk_on_off_gclk, gclk_on_off_dclk;
wire gclk_active_gclk, gclk_active_dclk;
wire gclk_out;

wire rcfg_ready, rcfg_active;

wire [4:0] scan_line_addr_gclk;
reg  [NUMBER_OF_LANES-1:0] r, g, b;                 // "HUB75" RGB outputs
reg  dclk, latch;

wire  request_prea, request_rcfg, req_to_send_cmd;
wire  req_to_send_line;

reg   [3:0] cmd_vector;             // this vector is connected to the command sending block
wire  [3:0] cmd_vector_wrc [2:0];   // a constants' array for choosing the right vector during (re-)config

reg [15:0] rcfg_data_r, rcfg_data_g, rcfg_data_b;  // configuration registers' data (r/g/b) 
wire [1:0] rcfg_index;

reg  [MEM_ADDR_WIDTH-1:0]  mem_addr; // pixels' data memory address
wire [LINE_ADDR_WIDTH-1:0] mem_line_addr;
wire [MEM_ADDR_WIDTH-1:0]  mem_base_addr; 

wire test_pin;
 
//******************************************************************************
assign MEM_ADDR = mem_addr;
assign HUB_ADDR = scan_line_addr_gclk;

assign HUB_GCLK = gclk_out;
assign HUB_DCLK = dclk; // (cmd_tx_dclk_ena | line_tx_dclk_ena) ? DCLK_IN : 1'b0; 
assign HUB_LATCH = latch; //cmd_tx_latch    | line_tx_latch;

assign HUB_R = r, HUB_G = g, HUB_B = b;

assign HUB_DCLK_ENA = (cmd_tx_dclk_ena | line_tx_dclk_ena);

//assign TEST_PIN = frame_eos_gclk;
assign TEST_PIN[0] = gclk_display_gclk, TEST_PIN[1] = gclk_on_off_gclk;

//------------------------------------------------------------------------------
always @*
 begin
   rcfg_data_r <= RCFG_R[rcfg_index];
   rcfg_data_g <= RCFG_G[rcfg_index];
   rcfg_data_b <= RCFG_B[rcfg_index];
 end

assign cmd_vector_wrc[2] = CMD_WRC3,
       cmd_vector_wrc[1] = CMD_WRC2,
       cmd_vector_wrc[0] = CMD_WRC1;
   
//------------------------------------------------------------------------------
always @*                          // HUB75 output signals MUX (cmd/pixels' data)
 if (cmd_tx_active)
   begin // tbd generate
     dclk <= cmd_tx_dclk; latch <= cmd_tx_latch;
     r <= {NUMBER_OF_LANES{cmd_tx_r}}; g <= {NUMBER_OF_LANES{cmd_tx_g}};  b <= {NUMBER_OF_LANES{cmd_tx_b}};
   end
    else
      begin
        dclk <= line_tx_dclk; latch <= line_tx_latch;
        r <= line_tx_r; g <= line_tx_g; b <= line_tx_b;
      end

assign req_to_send_cmd = request_prea | request_rcfg | vsync_cmd_req;    // the ORed request from mbi5151_ctrl and above 

always @*
 if      (vsync_cmd_req)  cmd_vector <= CMD_VSYNC;
 else if (request_prea)   cmd_vector <= CMD_PREA;
      else                cmd_vector <= cmd_vector_wrc[rcfg_index];
   
//assign cmd_vector = vsync_cmd_req ? CMD_VSYNC : cmd_vector_wrc[rcfg_index];
     
//******************************************************************************
// RAM address
always @*
 mem_addr = mem_base_addr + mem_line_addr;
 
//******************************************************************************
// common control
mbi5153_ctrl
#( 
 .DEBUG_MODE ("NO"),
 .GCLK_DCLK_RATIO (GCLK_DCLK_RATIO),
 .GCLK_CLOCKS_BEFORE_VSYNC (GCLK_CLOCKS_BEFORE_VSYNC),
 .GCLK_STOP_AFTER_VSYNC (GCLK_STOP_AFTER_VSYNC),
 .RCFG_VSYNC_NUM (RCFG_VSYNC_NUM)           // 150 - reconfig every 3 seconds ( @ 50Hz refresh)
// .FUNC_RCFG_ENA (1), .FUNC_UPGS_ENA (1)   // debug - disable RCFG and UPDATE GS
// .FUNC_RCFG_ENA (1), .FUNC_UPGS_ENA (1) 
)
mbi5153_ctrl_inst
(
 .CLK (DCLK_IN), .RESET (RESET),
 .VSYNC_STB (VSYNC_STB),
 
 .RECONFIG_REQ (reconfig_req),     // request for (re-)configuration
 .UPDATE_GS_REQ (update_gs_req),   // update GS data request
 .VSYNC_CMD_REQ (vsync_cmd_req),   // Driver VSYNC command request

 .FUNC_RCFG_ENA (1'b1), .FUNC_UPGS_ENA (TEST_UPGS_ENA),
 .RECONFIG_DONE (rcfg_done),
 .UPDATE_GS_DONE (frame_tx_done),
 .CMD_DONE (cmd_tx_done),          // command proceeded
 
 .EOS (frame_eos_dclk),            // end of frame scan strobe
 .GCLK_DISPLAY (gclk_display_dclk),// 0 - "external" control, 1 - display frame
 .GCLK_ON_OFF (gclk_on_off_dclk)   // GCLK state during "external" controlling
);
//******************************************************************************
// GCLK generator; Note that the I/O signals of this module are related to GCLK domain
mbi5153_gclk
#(
 .DEBUG_MODE ("NO"),
 .PWM13_CYCLE_NUM_SECTIONS (PWM13_CYCLE_NUM_SECTIONS),               
 .PWM14_CYCLE_NUM_SECTIONS (PWM14_CYCLE_NUM_SECTIONS),
 .PWM_CYCLE_GCLK_CLOCKS    (PWM_CYCLE_GCLK_CLOCKS),
 .GCLK_LINE_SWITCH_DEAD_TIME_H (GCLK_LINE_SWITCH_DEAD_TIME_H),             // 6  @ 20MHz
 .GCLK_LINE_SWITCH_DEAD_TIME_L (GCLK_LINE_SWITCH_DEAD_TIME_L)              // 24 @ 20MHz
)
mbi5153_gclk_inst
(
 .RESET (RESET),
 .CLK (GCLK_IN),              // PWM CLOCK (input)
                              // GCLK domain signals:
// .GCLK_DISPLAY (1), .GCLK_ON_OFF (1), // debug
 .GCLK_DISPLAY (gclk_display_gclk),//gclk domain sig, 1 - "display" sequence, 0 - external on/off control
 .GCLK_ON_OFF  (gclk_on_off_gclk), //gclk domain sig, external control: 1 - ON, 0 - OFF
 
 .SCAN_RATIO (SCAN_RATIO),    // scan ratio (number of the lines)
 .PWM_DEPTH  (PWM_DEPTH),     // 0 = 13-bit, 1 = 14-bit
 
 .EOS (frame_eos_gclk),       // End Of Scan (frame display) strobe
 .GCLK_OUT (gclk_out),
 .GCLK_ACTIVE (gclk_active_gclk),
 .SCAN_LINE_ADDR (scan_line_addr_gclk),
 .TEST_PIN (test_pin)
);

//******************************************************************************
// (re-)configuration of the drivers' chain
mbi5153_rcfg  mbi5153_rcfg_inst
(
 .CLK (DCLK_IN), .RESET (RESET),
 .REQUEST_IN (reconfig_req),              // request for (re-)configuration
 
 .CFG_WORD_ADDR (rcfg_index),             // [1:0] data/cmd index
 
 .REQUEST_TO_SEND_PREA_CMD (request_prea),
 .REQUEST_TO_SEND_RCFG_CMD (request_rcfg),
 .CMD_DONE (cmd_tx_done),                 //  input - command proceeded
 
 .IF_READY (cmd_tx_ready),                // input - the REQUEST_TO_SEND_CMD will be applied this signal is active
 
 .READY (rcfg_ready),                     // the REQUEST may be applied when this signal is active    
 .ACTIVE (rcfg_active),                   // shows that the cmd execution is running
 .DONE (rcfg_done)                        // this strobe shows that a command comletely done
);

//******************************************************************************
// commands
mbi5153_commands
#( .NUM_IC_CHAIN (NUM_IC_CHAIN ) )
mbi5153_commands_inst
(
 .CLK (DCLK_IN),  .RESET (RESET),
 .REQUEST (req_to_send_cmd),  // request to send a CMD
 .CMD (cmd_vector),           // input wire [3:0]  CMD
 .DATA_R (rcfg_data_r), .DATA_G (rcfg_data_g), .DATA_B (rcfg_data_b),
 
 .READY (cmd_tx_ready),       // the REQUEST may be applied when this signal is active
 .ACTIVE (cmd_tx_active),     // shows that the cmd execution is running
 .DCLK (cmd_tx_dclk),         // serial clock, derived from CLK
 .DCLK_ENA (cmd_tx_dclk_ena),
 .LATCH (cmd_tx_latch),       // LATCH signal, determines a command
 .R (cmd_tx_r), .G (cmd_tx_g), .B (cmd_tx_b),   // output RCFG rgb data 
 .CMD_DONE (cmd_tx_done)      // this strobe shows that a command comletely done
);

//******************************************************************************
// tx frame
mbi5153_frame
#(
 .EXT_RAM_BASE_ADDR (EXT_RAM_BASE_ADDR),
// .MAX_IMG_WIDTH_LOG2 (LINE_ADDR_WIDTH),
// .NUM_CH_IC (NUM_CH_IC),
// .NUM_IC_CHAIN (NUM_IC_CHAIN),
 .IMG_WIDTH_MAX (IMG_WIDTH_MAX),
 .IMG_WIDTH_MAX_LOG2 (IMG_WIDTH_MAX_LOG2),
 .ADDR_WIDTH (MEM_ADDR_WIDTH)
)
mbi5153_frame_inst
(
 .CLK (DCLK_IN), .RESET (RESET),
 .IMG_WIDTH (IMG_WIDTH),

 .REQUEST (update_gs_req),     // request to send a frame
 .SCAN_RATIO (SCAN_RATIO),     // scan ratio (number of the lines)
 .LINE_READY (line_tx_ready),  // Line Transmitter (mbi5153_data) is ready
 .LINE_TX_DONE (line_tx_done), // Line transmitted
  
 .READY (frame_tx_ready),      // the REQUEST may be applied when this signal is active
 .ACTIVE (frame_tx_active),    // shows that the cmd execution is running
 .FRAME_TX_DONE(frame_tx_done),// this strobe shows that the frame is comletely sent
 .REQUEST_TO_SEND_LINE (req_to_send_line),
 .ADDR (mem_base_addr)         // output - current base address of the external memory 
);

//******************************************************************************
//! tx line
//! This module configure 1 line of the panel
mbi5153_data
#(
 .NUM_IC_CHAIN (NUM_IC_CHAIN),    // number of the ICs in the chain
 .NUM_CH_IC   (NUM_CH_IC),        // number of the outputs/channels per one IC 
 .IC_WORD_LENGTH (IC_WORD_LENGTH),// number of bits per 1 data word (normally 16)
 .NUMBER_OF_LANES (NUMBER_OF_LANES),
 .RGB_LSB (8'h00)
)
mbi5153_line_inst
(
 .CLK (DCLK_IN), .RESET (RESET),
 .REQUEST (req_to_send_line),
 
 .ADDR (mem_line_addr),
 // offset address (output) and pixel data (input), 3 memory blocks that work in parallel:
 .DATA0 (MEM0_DATA), .DATA1 (MEM1_DATA), .DATA2 (MEM2_DATA), 
 
 .READY (line_tx_ready), .ACTIVE (line_tx_active), // outputs

 .DCLK (line_tx_dclk), .DCLK_ENA (line_tx_dclk_ena), .LATCH (line_tx_latch),
 .R (line_tx_r), .G (line_tx_g), .B (line_tx_b),

 .TX_DONE (line_tx_done)
);

//******************************************************************************
// fast clock domain -> slow clock domain
//******************************************************************************
stb_extender stb_extender_inst1 (
 .reset (RESET),
// fast clock domain
 .clk_in (GCLK_IN), .stb_in (frame_eos_gclk),
// slow clock domain
 .clk_out (DCLK_IN), .stb_out (frame_eos_dclk)
);
//------------------------------------------------------------------------------
stb_extender stb_extender_inst2 (
 .reset (RESET),
// fast clock domain
 .clk_in (GCLK_IN), .stb_in (gclk_active_gclk),
// slow clock domain
 .clk_out (DCLK_IN), .stb_out (gclk_active_dclk)
);
//******************************************************************************
// slow clock domain -> fast clock domain
//******************************************************************************
cross_domain_sig cross_domain_sig_inst1
( .CLK (GCLK_IN), .IN (gclk_display_dclk), .OUT (gclk_display_gclk) );
//------------------------------------------------------------------------------
cross_domain_sig cross_domain_sig_inst2
( .CLK (GCLK_IN), .IN (gclk_on_off_dclk), .OUT (gclk_on_off_gclk) );

//******************************************************************************
 
endmodule









