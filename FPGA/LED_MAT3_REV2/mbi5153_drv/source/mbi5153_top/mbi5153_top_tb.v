//******************************************************************************
// MBI5153 TOP module - TESTBENCH 
//
// Author:  Dim Su
// Initial date: 20180116
// Release History:
//
//******************************************************************************

// synopsys translate_off
`timescale 1 ns / 10 ps
// synopsys translate_on

`default_nettype none

module mbi5153_top_tb ();

`include "../../source/mbi5153_common/mbi5153_defines.vh"
/*
parameter  DATA_RCFG1_R = 16'b1101_1111_0010_1011,
           DATA_RCFG1_G = 16'b1101_1111_0010_1011,
           DATA_RCFG1_B = 16'b1101_1111_0010_1011;
parameter  DATA_RCFG2_R = 16'b0100_0101_0000_0000,
           DATA_RCFG2_G = 16'b0110_0101_0000_0000,
           DATA_RCFG2_B = 16'b0110_0101_0000_0000;
parameter  DATA_RCFG3_R = 16'b1100_0000_0000_0011,
           DATA_RCFG3_G = 16'b0110_0001_0000_0011,
           DATA_RCFG3_B = 16'b0011_0011_0000_0011;
*/
 
 parameter MEM_ADDR_WIDTH = 14; 
 
 
reg CLK_10M, CLK_20M, RESET;
reg VSYNC_STB;
reg [23:0] MEM_DATA;

wire [MEM_ADDR_WIDTH-1:0] OUTBUF_OUT_ADDR;
wire HUB75_GCLK, HUB75_CLK, HUB75_LATCH, HUB75_R, HUB75_G, HUB75_B;
wire [4:0] HUB75_ADDR;

// MBI5153 / ICN2053 config reg values
wire [15:0] data_rcfg3_r = DATA_RCFG3_R, data_rcfg2_r = DATA_RCFG2_R, data_rcfg1_r = DATA_RCFG1_R;
wire [15:0] data_rcfg3_g = DATA_RCFG3_G, data_rcfg2_g = DATA_RCFG2_G, data_rcfg1_g = DATA_RCFG1_G;
wire [15:0] data_rcfg3_b = DATA_RCFG3_B, data_rcfg2_b = DATA_RCFG2_B, data_rcfg1_b = DATA_RCFG1_B;

wire [15:0] data_rcfg_r [2:0];
wire [15:0] data_rcfg_g [2:0];
wire [15:0] data_rcfg_b [2:0];
// RGB Config registers' data (for MBI5153 and ICN2053)
assign data_rcfg_r[2] = data_rcfg3_r, data_rcfg_r[1] = data_rcfg2_r, data_rcfg_r[0] = data_rcfg1_r;
assign data_rcfg_g[2] = data_rcfg3_g, data_rcfg_g[1] = data_rcfg2_g, data_rcfg_g[0] = data_rcfg1_g;
assign data_rcfg_b[2] = data_rcfg3_b, data_rcfg_b[1] = data_rcfg2_b, data_rcfg_b[0] = data_rcfg1_b;


// DUT
mbi5153_top
#(
 .EXT_RAM_BASE_ADDR (0),
 .NUM_CH_IC (16),
 .NUM_IC_CHAIN (4),
 .IC_WORD_LENGTH (16),
 .MEM_ADDR_WIDTH (MEM_ADDR_WIDTH)
)
 mbi5153_top_inst
(
 .RESET (RESET),
 .DCLK_IN (CLK_10M),          // must be 10 MHz
 .GCLK_IN (CLK_20M),          // PWM CLOCK (input), must be 20 MHz
 .VSYNC_STB (VSYNC_STB),      // frame sending request
 .SCAN_RATIO (5'd3),          // scan ratio (number of the lines) 
 
 .RCFG_R (data_rcfg_r), .RCFG_G (data_rcfg_g), .RCFG_B (data_rcfg_b),
 
 .MEM_DATA (MEM_DATA), // RGB word (fetched from memory)
 
 .MEM_ADDR (OUTBUF_OUT_ADDR), // pixel's address in the external memory

 .HUB_DCLK (HUB75_CLK),           // serial data clock, derived from CLK
 .HUB_ADDR  (HUB75_ADDR),
 .HUB_LATCH (HUB75_LATCH),        // LATCH signal, determines a command
 .HUB_R     (HUB75_R), .HUB_G (HUB75_G), .HUB_B (HUB75_B), // debug
 .HUB_GCLK (HUB75_GCLK)
);

reg [16:0] vsync_stb_div;
localparam VSYNC_STB_DIV = 100000; // 10M / 100000 = 100Hz

//******************************************************************************
// main test stimilus 
initial                                                
 begin
 $display("Running testbench");                       

 CLK_10M = 0; CLK_20M = 0; RESET = 0;
 VSYNC_STB = 0;
 MEM_DATA = 24'hAA55AA;
 
 #100  RESET = 1;
 #100  RESET = 0;
 
 #100000000  $display("Simulation Paused");  
 $stop;
 
 end                                                    

//******************************************************************************
// clock 'DCLK'
always                                                 
 begin                                                  
  #50 CLK_10M = ! CLK_10M; // 10MHz clock
 end
//******************************************************************************
// clock 'GCLK'
always                                                 
 begin                                                  
  #25 CLK_20M = ! CLK_20M; // 20MHz clock
 end
 
//******************************************************************************
// VSYNC strobe
always @(posedge CLK_10M or posedge RESET)
  if (RESET)                 vsync_stb_div <= VSYNC_STB_DIV;                                               
  else
    if (vsync_stb_div != 0)  vsync_stb_div <= vsync_stb_div - 1;
    else                     vsync_stb_div <= VSYNC_STB_DIV;
      
always @(posedge CLK_10M or posedge RESET)
  if (RESET)  VSYNC_STB <= 0;
  else        VSYNC_STB <= (vsync_stb_div == 0);
  
endmodule

