//==============================================================================
//  Name:     Core module for the [3*120x90]-array driver project
//  Version:  v1.0
//  Author: Dim Su
//  History Release:
//  20180829 - Initial version (1.0)
//
//==============================================================================

// to prevent creating the implicit nets:
`default_nettype none

//`include "define_led_driver.vh"
`include "defines.vh"

module led_mat_core(

 input        RESET,
 input        MCLK_IN,
	
 input        DPI_H_SYNC, DPI_V_SYNC,
 input        DPI_PCLK,
 input        DPI_DE,
 input [7:0]  DPI_R,
 input [7:0]  DPI_G,
 input [7:0]  DPI_B,
	
 output [2:0] HUB1_R, HUB1_G, HUB1_B,
 output [2:0] HUB2_R, HUB2_G, HUB2_B,
 output [2:0] HUB3_R, HUB3_G, HUB3_B,
 output [4:0] HUB_ADDR,
 
 output       HUB_LATCH, HUB_CLK,
 output       /* HUB_OE, */ HUB_GCLK,
 
 input        UART_RX,
 output       UART_TX,
 
 inout        DVI_SDA,
 inout        DVI_SCL,

 output [7:0] LED,
 
 input  [1:0] KEY,
 
 input        TEST_LATCH_POS,
 input  [1:0] TEST_PATTERN_SEL,
 input        TEST_STOP_CLIPPER,
 input        TEST_TPG_RESET,
 input        TEST_UPGS_DIS,
 input        TEST_RGB_INPUT
);


// display the data below during compilation:
initial
 begin
    $display("********************* TOP Level Module *******************************");
`ifdef LED_DRIVER_MBI5153
    $display("******* MBI5153 mode:                         *******");
    $display("******* Number of Drv ICs per Row  %d *******", NUM_IC_CHAIN*PANEL_LANES);
`else  
    $display("******* MBI5124 mode:                         *******");
`endif
    $display("******* Panel Width                %d *******", PANEL_WIDTH);
    $display("******* Panel Height               %d *******", PANEL_HEIGHT);
    $display("******* Panels Num                 %d *******", NUM_PANELS);
    $display("******* Image Width                %d *******", IMAGE_WIDTH_RST_VAL);
    $display("******* Display Width              %d *******", DISPLAY_WIDTH);
    $display("******* Lanes Number               %d *******", PANEL_LANES);
    $display("******* Lanes Number Cnt Width     %d *******", NUM_LANES_WIDTH);
    $display("******* Pixel Depth per Color      %d *******", PIXEL_DEPTH);
    $display("******* Out Mem Block Data width   %d *******", OUTBUF_DATA_WIDTH);
    $display("******* Out Buffer Addr Width      %d *******", OUTBUF_ADDR_WIDTH);
    $display("******* Half-Buffer Size (words)   %d *******", MEMORY_WIDTH);
    $display("******* Target Scan Ratio          %d *******", MULTIPLEX_RATIO);
    $display("**********************************************************************");
 end
 
//=======================================================
//  REG/WIRE declarations
//=======================================================

// these wires will be associated later with KEY and SW inputs
wire       reset;

wire       test_tpg_reset, test_dpram_wr;
wire [1:0] test_pattern_sel;
wire       test_rgb_input, test_stop_clipper, test_latch_pos;
wire       test_upgs_dis;

// RGB HUB
wire [2:0] hub0_r, hub0_g, hub0_b, hub1_r, hub1_g, hub1_b, hub2_r, hub2_g, hub2_b;
wire [4:0] hub0_addr;
wire       hub0_latch, hub0_oe, hub0_gclk;
wire       hub0_clk, hub0_clk_g;
wire       hub0_clk_out;
wire       hub0_clk_ena;
           
wire [2:0] hub0_fsm;

// PWM for brightness control
wire       pwm_out;
wire       hub0_oe_pwm;

// DPRAM
wire outbuf_in_wr;

reg  [OUTBUF_ADDR_WIDTH-1:0] outbuf_half1_in_addr, outbuf_half2_in_addr, outbuf_half3_in_addr;
wire [OUTBUF_DATA_WIDTH-1:0] outbuf_half1_in_data, outbuf_half2_in_data, outbuf_half3_in_data;
wire [OUTBUF_DATA_WIDTH-1:0] outbuf_in_data;

wire outbuf_out_clk;
wire outbuf_out_rd;

wire [OUTBUF_ADDR_WIDTH-1:0] outbuf_out_addr;
//wire [OUTBUF_DATA_WIDTH-1:0] outbuf_out_data;

// declare these as regs to switch source in the CASE statement
reg [OUTBUF_DATA_WIDTH-1:0] outbuf_half1_out_data, outbuf_half2_out_data, outbuf_half3_out_data;

wire outbuf_half1_in_wr, outbuf_half2_in_wr, outbuf_half3_in_wr;

// I2C
wire sda_in, scl_in, sda_oe, scl_oe;

// PLL clocks
wire clk_100M, clk_80M, clk_50M, clk_25M, clk_pll_2xdclk, clk_pll_dclk, clk_1152k;
// PLL signals
wire pll_video_input_activeclock;
wire clk_25M_bad, dpi_pclk_bad;
wire pll_video_input_locked;

// time strobes
wire strobe_1khz, strobe_50hz, strobe_1hz;

// UART
wire uart_tx, uart_rx;

// QSPI
wire [3:0] qspi_data;
wire       qspi_dclk, qspi_cs_n;

// split VGA output	  
reg vga_hs, vga_vs;
reg  [3:0] vga_r, vga_g, vga_b;
 
wire hw_vga_hs, hw_vga_vs;
wire [7:0] hw_vga_r, hw_vga_g, hw_vga_b;

// DPI (PRGB) inputs
wire [7:0] dpi_r, dpi_g, dpi_b;
wire       dpi_h_sync, dpi_v_sync;
wire       dpi_de, dpi_pclk;
wire       dpi_pclk_mux;

wire       pclk_global;

wire [15:0] dpi_frequency;
wire [10:0] dpi_hor_size;
wire        is_sync_640x480, is_sync_800x480;
reg         is_sync_dpi;

// DPI decoder output
wire [7:0]  dpi_out_r, dpi_out_g, dpi_out_b;
wire [10:0] dpi_out_addr_h;
wire [ 9:0] dpi_out_addr_v;

wire dpi_out_sop, dpi_out_eop;
wire dpi_out_ovf, dpi_out_valid;

// test pattern image pixels' address
wire [9:0]   test_pattern_addr_v;
wire [10:0]  test_pattern_addr_h;

// sub-image (1 row) height
wire [5:0] lane_height;

// MBI5153 config reg values
wire [15:0] data_rcfg3_r, data_rcfg2_r, data_rcfg1_r;
wire [15:0] data_rcfg3_g, data_rcfg2_g, data_rcfg1_g;
wire [15:0] data_rcfg3_b, data_rcfg2_b, data_rcfg1_b;

wire [15:0] data_rcfg_r [2:0];
wire [15:0] data_rcfg_g [2:0];
wire [15:0] data_rcfg_b [2:0];

// latch position select
//reg signed [2:0] latch_start_pos;
//reg signed [2:0] latch_end_pos;

// this signal selects the input of RGB data
reg in_img_selector;

//------------------------------------------------------------------------------
//  PINs breaking out
//------------------------------------------------------------------------------
//assign  reset              = RESET;

assign  test_latch_pos     = TEST_LATCH_POS;   
assign  test_pattern_sel   = TEST_PATTERN_SEL;
assign  test_stop_clipper  = TEST_STOP_CLIPPER;
assign  test_tpg_reset     = TEST_TPG_RESET;
assign  test_upgs_dis      = TEST_UPGS_DIS;
assign  test_rgb_input     = TEST_RGB_INPUT;   // 0 - read image from DPI, 1 - from TPG

`ifdef LED_DRIVER_MBI5153                                                                     // HUB OE (GCLK)
assign  HUB_GCLK           = hub0_gclk;
`else
assign  HUB_GCLK           = ~hub0_oe_pwm;    // this signal is "active low"
`endif


assign  HUB_CLK            = hub0_clk_out,                                                   // HUB DCLK
        HUB_LATCH          = hub0_latch,                                                     // HUB Latch
        HUB_ADDR[4:0]      = hub0_addr;                                                      // HUB Row address
		  
//assign  HUB1_R[0]          = hub0_gclk, HUB1_G[0] = hub0_gclk, HUB1_B[0] = hub0_gclk;        // HUB0 RGB, top lane
//assign  HUB1_R[1]          = hub0_gclk, HUB1_G[1] = hub0_gclk, HUB1_B[1] = hub0_gclk;        // HUB0 RGB, mid lane
//assign  HUB1_R[2]          = hub0_gclk, HUB1_G[2] = hub0_gclk, HUB1_B[2] = hub0_gclk;        // HUB0 RGB, bot lane
assign  HUB1_R[0]          = hub0_r[0], HUB1_G[0] = hub0_g[0], HUB1_B[0] = hub0_b[0];        // HUB0 RGB, top lane
assign  HUB1_R[1]          = hub0_r[1], HUB1_G[1] = hub0_g[1], HUB1_B[1] = hub0_b[1];        // HUB0 RGB, mid lane
assign  HUB1_R[2]          = hub0_r[2], HUB1_G[2] = hub0_g[2], HUB1_B[2] = hub0_b[2];        // HUB0 RGB, bot lane

assign  HUB2_R[0]          = hub1_r[0], HUB2_G[0]  = hub1_g[0], HUB2_B[0]  = hub1_b[0];      // HUB1 RGB, top lane
assign  HUB2_R[1]          = hub1_r[1], HUB2_G[1]  = hub1_g[1], HUB2_B[1]  = hub1_b[1];      // HUB1 RGB, mid lane
assign  HUB2_R[2]          = hub1_r[2], HUB2_G[2]  = hub1_g[2], HUB2_B[2]  = hub1_b[2];      // HUB1 RGB, bot lane
		  
assign  HUB3_R[0]          = hub2_r[0], HUB3_G[0]  = hub2_g[0], HUB3_B[0]  = hub2_b[0];      // HUB2 RGB, top lane
assign  HUB3_R[1]          = hub2_r[1], HUB3_G[1]  = hub2_g[1], HUB3_B[1]  = hub2_b[1];      // HUB2 RGB, mid lane
assign  HUB3_R[2]          = hub2_r[2], HUB3_G[2]  = hub2_g[2], HUB3_B[2]  = hub2_b[2];      // HUB2 RGB, bot lane


assign  dpi_r              = DPI_R, dpi_g = DPI_G, dpi_b = DPI_B;
		  
assign  dpi_h_sync         = DPI_H_SYNC, dpi_v_sync = DPI_V_SYNC, dpi_de = DPI_DE, dpi_pclk = DPI_PCLK; 

assign  uart_rx            = UART_RX, UART_TX = uart_tx;                                     // UART

// I2C
assign sda_in = DVI_SDA;
bufif1(DVI_SDA, 1'b0, sda_oe);

assign scl_in = DVI_SCL;
bufif1(DVI_SCL, 1'b0, scl_oe);

// LEDs (inverted!)
assign LED[0] = ~outbuf_half1_in_wr; // for debug purposes: to see how the halfs of the display are written
assign LED[1] = ~is_sync_800x480;
assign LED[7:3] = 6'b111111;
//assign LED[3] = ~is_sync_640x480;
//assign LED[4] = ~1'b0;
//assign LED[5] = ~1'b0;
//assign LED[6] = ~pll_video_input_locked;	 
//assign LED[7] = dpi_pclk_bad;       // '1' shows that clk input OK

//------------------------------------------------------------------------------
//  Assignments
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// control registers/wires
wire [15:0] regfile_out [31:0];
wire [15:0] regfile_in  [31:0];

wire [7:0]                      gctrl;       // global control bits 
wire [BRIGHTNESS_PWM_DEPTH-1:0] brightness;  // global brightness - 32 levels (to modulate OE signal)
wire [IMAGE_WIDTH_MAX_LOG2-1:0] image_width; // image width 
wire [5:0]                      scan_ratio;  // 1/1..1/32 scan ratio; 0..32 for MBI5124, 0..31 for MBI5153
wire [NUM_LANES_WIDTH-1:0]      num_lanes;   // up to 4 rows (e.g. there are 2 rows in the 64x64 module with 1/32 scan ratio)
wire [PWM_QUANTUM_WIDTH-1:0]    pwmq;        // PWM quantum
wire [10:0]                     roi_x0;
wire [9:0]                      roi_y0;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// assign control registers:
assign gctrl        = regfile_out[0][7:0];
assign brightness   = regfile_out[1][BRIGHTNESS_PWM_DEPTH-1:0];
assign image_width  = regfile_out[2][IMAGE_WIDTH_MAX_LOG2-1:0];
assign scan_ratio   = regfile_out[3][5:0];
assign num_lanes    = regfile_out[4][NUM_LANES_WIDTH-1   :0];
assign pwmq         = regfile_out[5][PWM_QUANTUM_WIDTH-1:0];
assign roi_x0       = regfile_out[6][10:0];
assign roi_y0       = regfile_out[7][ 9:0];

assign data_rcfg1_r = regfile_out[16], data_rcfg1_g = regfile_out[17], data_rcfg1_b = regfile_out[18];
assign data_rcfg2_r = regfile_out[19], data_rcfg2_g = regfile_out[20], data_rcfg2_b = regfile_out[21];
assign data_rcfg3_r = regfile_out[22], data_rcfg3_g = regfile_out[23], data_rcfg3_b = regfile_out[24];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// registers mapping and reset values:
// CONTROL registers (r/w)
assign regfile_in[0]  = gctrl;         parameter REG_0_RST_VALUE = 3;
assign regfile_in[1]  = brightness;    parameter REG_1_RST_VALUE = BRIGHTNESS_PWM_MAX/2 - 2; // defaul brightness - works for MBI5124/ICN2038
assign regfile_in[2]  = image_width;   parameter REG_2_RST_VALUE = IMAGE_WIDTH_RST_VAL;
assign regfile_in[3]  = scan_ratio;    parameter REG_3_RST_VALUE = DEFAULT_SCAN_RATIO;
assign regfile_in[4]  = num_lanes;     parameter REG_4_RST_VALUE = PANEL_LANES;
assign regfile_in[5]  = pwmq;          parameter REG_5_RST_VALUE = PWM_QUANTUM_MAX/2;
assign regfile_in[6]  = roi_x0;        parameter REG_6_RST_VALUE = ROI_X0;
assign regfile_in[7]  = roi_y0;        parameter REG_7_RST_VALUE = ROI_Y0;

assign regfile_in[16] = data_rcfg_r[0];parameter REG_16_RST_VALUE = RST_VAL_DATA_RCFG1_R;
assign regfile_in[17] = data_rcfg_g[0];parameter REG_17_RST_VALUE = RST_VAL_DATA_RCFG1_G;
assign regfile_in[18] = data_rcfg_b[0];parameter REG_18_RST_VALUE = RST_VAL_DATA_RCFG1_B;
assign regfile_in[19] = data_rcfg2_r;  parameter REG_19_RST_VALUE = RST_VAL_DATA_RCFG2_R;
assign regfile_in[20] = data_rcfg2_g;  parameter REG_20_RST_VALUE = RST_VAL_DATA_RCFG2_G;
assign regfile_in[21] = data_rcfg2_b;  parameter REG_21_RST_VALUE = RST_VAL_DATA_RCFG2_B;
assign regfile_in[22] = data_rcfg3_r;  parameter REG_22_RST_VALUE = RST_VAL_DATA_RCFG3_R;
assign regfile_in[23] = data_rcfg3_g;  parameter REG_23_RST_VALUE = RST_VAL_DATA_RCFG3_G;
assign regfile_in[24] = data_rcfg3_b;  parameter REG_24_RST_VALUE = RST_VAL_DATA_RCFG3_B;

// STATUS registers (read-only)
assign regfile_in[25]  = dpi_frequency;
assign regfile_in[26]  = {5'd0, dpi_hor_size};
assign regfile_in[27] = 0, regfile_in[28] = 0, regfile_in[29] = 0; // reserved
assign regfile_in[30] = version_number[31:16];
assign regfile_in[31] = version_number[15: 0];

// RGB Config registers' data (for MBI5153)
assign data_rcfg_r[2] = data_rcfg3_r, data_rcfg_r[1] = data_rcfg2_r,
       data_rcfg_r[0] = {data_rcfg1_r[15:13], scan_ratio[4:0], data_rcfg1_r[7:0]};
		 
assign data_rcfg_g[2] = data_rcfg3_g, data_rcfg_g[1] = data_rcfg2_g,
       data_rcfg_g[0] = {data_rcfg1_g[15:13], scan_ratio[4:0], data_rcfg1_g[7:0]};
		 
assign data_rcfg_b[2] = data_rcfg3_b, data_rcfg_b[1] = data_rcfg2_b,
       data_rcfg_b[0] = {data_rcfg1_b[15:13], scan_ratio[4:0], data_rcfg1_b[7:0]};

// row height is different due to a compiling mode:
`ifdef LED_DRIVER_MBI5124
assign lane_height = scan_ratio;
`else
assign lane_height = scan_ratio + 1;
`endif

//------------------------------------------------------------------------------
//  Structural coding
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// PLL for the basic system clocks
pll1	pll1_inst
 (	.areset (1'b0), .inclk0 (MCLK_IN),	.c0 (clk_100M), .c1 (clk_25M),
   .c2 (clk_pll_2xdclk), .c3 (clk_pll_dclk),	.c4 (clk_1152k)
 );


// PLL for the video input
// 'clk_dpi_mux' feeds:
//   VGA Test Pattern Generator, Image Clipper
//   Input (Port A - Data) of the DPRAM Frame Buffer

//GLOBAL global_clk_video_in_inst (dpi_pclk, pclk_global);
/*
pll_video_input	pll_video_input_inst (
	.areset ( reset ),
	.clkswitch ( test_rgb_input ), // 1 == internal clock
	.inclk0 ( dpi_pclk ),
	.inclk1 ( clk_25M ),
	.activeclock ( pll_video_input_activeclock ),
	.c0 ( clk_dpi_mux ),
	.clkbad0 ( dpi_pclk_bad ),
	.clkbad1 ( clk_25M_bad ),
	.locked ( pll_video_input_locked )
	); 
*/
assign dpi_pclk_mux = in_img_selector ? clk_25M : ~dpi_pclk;            // the RGB data are centered on neg-edge of the dpi_clk
//assign outbuf_out_clk = clk_pll_2xdclk;                              // LED Panel clock (may not be higher than 25MHz due to the driver IC spec)
assign outbuf_out_clk = clk_pll_dclk;                                  // LED Panel clock (may not be higher than 25MHz due to the driver IC spec)

GLOBAL global_pclk (dpi_pclk_mux, pclk_global);

//------------------------------------------------------------------------------
// delayed reset
reg [8:0] start_reset_counter;
always @(posedge clk_1152k)
 if(start_reset_counter[8] == 1'b0) start_reset_counter++;
 
assign reset = ~start_reset_counter[8];
   
always @(posedge clk_25M)
 in_img_selector <= ~is_sync_dpi;// ~(is_sync_800x480 | is_sync_640x480);              // 1 - TPG, 0 - DPI

//------------------------------------------------------------------------------
// phase shift of the dpi_pclk
//
//------------------------------------------------------------------------------
// phase shift of the hub0_clk
reg [7:0] hub0_clk_dly;
always @(posedge clk_100M)
 begin
   hub0_clk_dly <= {hub0_clk_dly[6:0], hub0_clk_g};
//   hub0_clk_dly <= {hub0_clk_dly[6:0], hub0_clk};
 end
 
// assign hub0_clk_out = hub0_clk_g;
// assign hub0_clk_out = hub0_clk;
 assign hub0_clk_out = hub0_clk_dly[2];
//------------------------------------------------------------------------------
/*
always @*
  if (test_latch_pos) 
   begin                      // latch position for ICN2038
	  latch_start_pos <= $signed(-3);
	  latch_end_pos   <= $signed(0);
	end
	else                       // latch position for MBI5124
	  begin
   	 latch_start_pos <= $signed(0);
	    latch_end_pos   <= $signed(1);
	  end
*/

//------------------------------------------------------------------------------
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
`ifdef LED_DRIVER_MBI5153
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
mbi5153_top
#(
 .EXT_RAM_BASE_ADDR (0),
 .NUM_IC_CHAIN (NUM_IC_CHAIN * NUM_PANELS),
 .IMG_WIDTH_MAX (IMAGE_WIDTH_RST_VAL), // determines a width of the memory address bus
 .IMG_WIDTH_MAX_LOG2 (IMAGE_WIDTH_MAX_LOG2),
 .GCLK_DCLK_RATIO (2),             // GCLK must be 20% or more faster than DCLK
 .NUMBER_OF_LANES (PANEL_LANES),
 .RCFG_VSYNC_NUM (150),            // CFG regs update - divider for the frame update frequency:
                                   // the CFG registers will be updated Fvsync/RCFG_VSYNC_NUM freq.
// .RCFG_VSYNC_NUM (3), // debug
 .MEM_ADDR_WIDTH (OUTBUF_ADDR_WIDTH)
)
 mbi5153_top_inst
(
 .RESET (reset),
 .DCLK_IN (outbuf_out_clk),        // must be 10 MHz
 
 .GCLK_IN (clk_pll_2xdclk),        // PWM CLOCK (input), must be 20 MHz
 .VSYNC_STB (strobe_50hz),         // frame update request
// .VSYNC_STB (strobe_1hz),         // debug
 .IMG_WIDTH (image_width),         // width of the image in memory
 .SCAN_RATIO (scan_ratio[4:0]),    // scan ratio (number of the lines) .. tbd bus width
 
 .TEST_UPGS_ENA (~test_upgs_dis),  // debug - disable GS (gray scale == image data) update
 
 .RCFG_R (data_rcfg_r), .RCFG_G (data_rcfg_g), .RCFG_B (data_rcfg_b),
 
 .MEM0_DATA (outbuf_half1_out_data),// RGB word, TOP row (fetched from memory)
 .MEM1_DATA (outbuf_half2_out_data),// RGB word, MID row
 .MEM2_DATA (outbuf_half3_out_data),// RGB word, BOT row
 
 .MEM_ADDR (outbuf_out_addr),       // pixel's address in the external memory

 .HUB_DCLK_ENA (hub0_clk_ena),
 .HUB_DCLK  (hub0_clk),             // serial data clock, derived from CLK
 .HUB_ADDR  (hub0_addr),
 .HUB_LATCH (hub0_latch),           // LATCH signal, determines a command
 .HUB_R     (hub0_r), .HUB_G (hub0_g), .HUB_B (hub0_b), 
 .HUB_GCLK  (hub0_gclk)
 //, .TEST_PIN (LED[1:0])               // debug
);


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
`else
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
hub75_drv hub0_drv_inst0
(
   .CLK       (outbuf_out_clk),     .RESET (reset),
        
   .IMG_WIDTH (image_width), .PWM_Q (pwmq), .SCAN_RATIO (/*MULTIPLEX_RATIO*/ scan_ratio),
   .LATCH_POS_VER (test_latch_pos),
/*		  .LATCH_START_POS (latch_start_pos), .LATCH_END_POS (latch_end_pos), */
 
   .MEM0_DATA (outbuf_half1_out_data), // the LED panel usually split by 2 parts: Top & Bottom
   .MEM1_DATA (outbuf_half2_out_data), // thus, we use 2 memories for Top & Bot that operate simultaneuosly
   .MEM_ADDR  (outbuf_out_addr),
   .MEM_RD    (outbuf_out_rd),
 
   .HUB_ADDR  (hub0_addr),
   .HUB_LATCH (hub0_latch), .HUB_OE (hub0_oe), .HUB_SCLK (hub0_clk),
   .HUB_R (hub0_r[1:0]), .HUB_G (hub0_g[1:0]), .HUB_B (hub0_b[1:0]), // output serialized data
   .FSM       (hub0_fsm)                              // for debug only (output to the indicator)
);
 defparam
    hub0_drv_inst0.PIXEL_DEPTH = PIXEL_DEPTH, 
    hub0_drv_inst0.PANEL_WIDTH  = PANEL_WIDTH,
    hub0_drv_inst0.LATCH_START_POS_V1 = LATCH_START_POS_ICN2038S,
    hub0_drv_inst0.LATCH_END_POS_V1 = LATCH_END_POS_ICN2038S,
    hub0_drv_inst0.LATCH_START_POS_V2 = LATCH_START_POS_MBI5124,
    hub0_drv_inst0.LATCH_END_POS_V2 = LATCH_END_POS_MBI5124,
    hub0_drv_inst0.SCAN_RATIO_PRM = MULTIPLEX_RATIO,
    hub0_drv_inst0.MEM_DATA_WIDTH = OUTBUF_DATA_WIDTH,  // full width comprises of two memories: for Top and for Bot
    hub0_drv_inst0.MEM_ADDR_WIDTH = OUTBUF_ADDR_WIDTH;  // use the maximum memory size

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
`endif
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


//------------------------------------------------------------------------------
// "virtual panel" with 128-bits shift register - delay lines for hub1 and hub2 ports
  
GLOBAL global_hubclk (hub0_clk, hub0_clk_g);

virtual_shift_reg
#( .DELAY_LENGTH(PANEL_WIDTH) )
virtual_shift_reg_inst_hub1
(
// .CLK     (outbuf_out_clk), .CLK_ENA (hub0_clk_ena),
 .CLK     (hub0_clk_g),       .CLK_ENA (1'b1),
 .IN_DATA_R  ( hub0_r ), .IN_DATA_G  ( hub0_g ), .IN_DATA_B  ( hub0_b ),
 .OUT_DATA_R ( hub1_r ), .OUT_DATA_G ( hub1_g ), .OUT_DATA_B ( hub1_b )
);


virtual_shift_reg
#( .DELAY_LENGTH(PANEL_WIDTH) )
virtual_shift_reg_inst_hub2
(
// .CLK     (outbuf_out_clk), .CLK_ENA (hub0_clk_ena),
 .CLK     (hub0_clk_g),       .CLK_ENA (1'b1),
 .IN_DATA_R  ( hub1_r ), .IN_DATA_G  ( hub1_g ), .IN_DATA_B  ( hub1_b ),
 .OUT_DATA_R ( hub2_r ), .OUT_DATA_G ( hub2_g ), .OUT_DATA_B ( hub2_b )
);

//------------------------------------------------------------------------------
// cropping an input image and sending it to the dpram 
// a ROI is set by ROI_X0, ROI_Y0 inputs and parameters that define the screen resolution

//wire image_clipper_reset = reset || test_rgb_input ? 1'b0 : (test_stop_clipper ? 1'b1 : !is_sync_dpi ); // stop getting tpg or dpi image if 'reset or no sync' - tbd
wire image_clipper_reset = reset || test_stop_clipper; 

// output data from clipper (no conversion/processing), but delay to align with the address - tbd
reg [PIXEL_DEPTH-1:0] data_from_clipper_r, data_from_clipper_g, data_from_clipper_b;


`ifdef DEBUG_BIT_MASKING
wire [PIXEL_DEPTH-1:0] bcm_mask;

// for testing binary-coded modulation:
lpm_constant	lpm_const_bcm ( .result (bcm_mask) );
	defparam
		lpm_const_bcm.lpm_cvalue = 'hFF,
		lpm_const_bcm.lpm_hint = "ENABLE_RUNTIME_MOD=YES, INSTANCE_NAME=MBCM",
		lpm_const_bcm.lpm_type = "LPM_CONSTANT",
		lpm_const_bcm.lpm_width = PIXEL_DEPTH;
		
// bit-mask for debug purpose:		
assign outbuf_in_data = {data_from_clipper_r, data_from_clipper_g, data_from_clipper_b} & {3{bcm_mask}}; 
`else
assign outbuf_in_data = {data_from_clipper_r, data_from_clipper_g, data_from_clipper_b};
`endif

always @(posedge pclk_global)
 begin
  data_from_clipper_r <= ( in_img_selector ? hw_vga_r[7-:PIXEL_DEPTH] : dpi_out_r[7-:PIXEL_DEPTH] );
  data_from_clipper_g <= ( in_img_selector ? hw_vga_g[7-:PIXEL_DEPTH] : dpi_out_g[7-:PIXEL_DEPTH] );
  data_from_clipper_b <= ( in_img_selector ? hw_vga_b[7-:PIXEL_DEPTH] : dpi_out_b[7-:PIXEL_DEPTH] );
 end


// -----------------------------------------------------------------------------
// Image clipping


// Top:
image_clipper
#( .OUT_ADDR_WIDTH (OUTBUF_ADDR_WIDTH), .IMG_WIDTH_MAX_LOG2 (IMAGE_WIDTH_MAX_LOG2) )
 image_clipper_lane1
(
 .CLK   ( pclk_global ), .RESET ( image_clipper_reset ), 
 .IMAGE_WIDTH (image_width), .IMAGE_HEIGHT (lane_height),
 .ADDR_H ( in_img_selector ? test_pattern_addr_h : dpi_out_addr_h ),
 .ADDR_V ( in_img_selector ? test_pattern_addr_v : dpi_out_addr_v ),
 .OUT_DATA_VALID ( outbuf_half1_in_wr ), .OUT_DATA_ADDR  ( outbuf_half1_in_addr ),
 .ROI_X0 ( roi_x0 ), .ROI_Y0 ( roi_y0 ) 
);

// Mid:
image_clipper
#( .OUT_ADDR_WIDTH (OUTBUF_ADDR_WIDTH), .IMG_WIDTH_MAX_LOG2 (IMAGE_WIDTH_MAX_LOG2) )
 image_clipper_lane2
(
 .CLK   ( pclk_global ), .RESET ( image_clipper_reset ),
 .IMAGE_WIDTH (image_width), .IMAGE_HEIGHT (lane_height),
 .ADDR_H ( in_img_selector ? test_pattern_addr_h : dpi_out_addr_h ),
 .ADDR_V ( in_img_selector ? test_pattern_addr_v : dpi_out_addr_v ),
 .OUT_DATA_VALID ( outbuf_half2_in_wr ), .OUT_DATA_ADDR  ( outbuf_half2_in_addr ),
 .ROI_X0 ( roi_x0 ), .ROI_Y0 ( roi_y0 + lane_height ) 
);

// Bot:
image_clipper
#( .OUT_ADDR_WIDTH (OUTBUF_ADDR_WIDTH), .IMG_WIDTH_MAX_LOG2 (IMAGE_WIDTH_MAX_LOG2) )
 image_clipper_lane3
(
 .CLK   ( pclk_global ), .RESET ( image_clipper_reset ),
 .IMAGE_WIDTH (image_width), .IMAGE_HEIGHT (lane_height),
 .ADDR_H ( in_img_selector ? test_pattern_addr_h : dpi_out_addr_h ),
 .ADDR_V ( in_img_selector ? test_pattern_addr_v : dpi_out_addr_v ),
 .OUT_DATA_VALID ( outbuf_half3_in_wr ), .OUT_DATA_ADDR  ( outbuf_half3_in_addr ),
 .ROI_X0 ( roi_x0 ), .ROI_Y0 ( roi_y0 + lane_height + lane_height ) 
);


//------------------------------------------------------------------------------
// Image DPM
// inferred dual-port memory is used
// A LED Panel is split by  two   parts (TOP and BOT)       - conventional panels
//                      and three parts (TOP, MID, and BOT) - longrunled panels

`define NUMBER_OF_MEM_BLOCKS PANEL_LANES

wire [`NUMBER_OF_MEM_BLOCKS-1:0] outbuf_wr_ena                          = {outbuf_half3_in_wr, outbuf_half2_in_wr, outbuf_half1_in_wr};
wire [OUTBUF_ADDR_WIDTH-1:0]    outbuf_in_addr  [`NUMBER_OF_MEM_BLOCKS-1:0];// = {outbuf_half3_in_addr, outbuf_half2_in_addr, outbuf_half1_in_addr};
wire [OUTBUF_DATA_WIDTH-1:0]    outbuf_out_data [`NUMBER_OF_MEM_BLOCKS-1:0];

assign 
      outbuf_in_addr[2] = outbuf_half3_in_addr, outbuf_in_addr[1] = outbuf_half2_in_addr, outbuf_in_addr[0] = outbuf_half1_in_addr;
		
always @*
  begin
      outbuf_half1_out_data <= outbuf_out_data[0]; outbuf_half2_out_data <= outbuf_out_data[1]; outbuf_half3_out_data <= outbuf_out_data[2];
	end

outbuf_dpram_multi
#(
 .NUMBER_OF_BLOCKS(`NUMBER_OF_MEM_BLOCKS), .MEMORY_WIDTH (MEMORY_WIDTH),
 .DATA_WIDTH (OUTBUF_DATA_WIDTH), .ADDR_WIDTH (OUTBUF_ADDR_WIDTH) 
)
outbuf_dpram_multi_inst
(
 .RESET (1'b1),
 .IN_CLK (pclk_global), .OUT_CLK (outbuf_out_clk),
 .WR_ENA (outbuf_wr_ena),
 .OUTBUF_IN_ADDR (outbuf_in_addr),   .OUTBUF_IN_DATA (outbuf_in_data),
 .OUTBUF_OUT_ADDR (outbuf_out_addr), .OUTBUF_OUT_DATA (outbuf_out_data)
);


//------------------------------------------------------------------------------
// modulate the OE output to control brightness
pwm_var_width
#( .DC_WIDTH (BRIGHTNESS_PWM_DEPTH) )
 pwm_brightness_inst(
// .CLK ( MAX10_CLK1_50 ),       // 50MHz clock for brightness PWM
 .CLK ( clk_25M ),             // 25MHz clock
 .RESET ( reset ),
 .STB_CLK ( 1'b1 ),            // always ena
 .DC ( brightness ),           // Duty Cycle input
 .Q ( pwm_out )
);

assign hub0_oe_pwm = hub0_oe & pwm_out; // modulate the OE signal

//------------------------------------------------------------------------------
// Test VGA generator: 8 bits per color, 25M pixel clock
vga_controller
#( .VIDEO_W (640), .VIDEO_H (480) )
vga_inst
(
 .RESET(reset),
 .VGA_CLK(pclk_global),
 .TP_SEL(test_pattern_sel),
 .H_SYNC(hw_vga_hs),
 .V_SYNC(hw_vga_vs),
 .VGA_B(hw_vga_b),
 .VGA_G(hw_vga_g),
 .VGA_R(hw_vga_r),
 
 .ADDR_H ( test_pattern_addr_h ),
 .ADDR_V ( test_pattern_addr_v )
 );	

 
always @*
   begin
      vga_hs <= hw_vga_hs; vga_vs <= hw_vga_vs;                 
      vga_r  <= hw_vga_r[7:4];  vga_g  <= hw_vga_g[7:4]; vga_b <= hw_vga_b[7:4];
	end
 
//------------------------------------------------------------------------------
// Parallel RGB receiver
dpi_recevier dpi_recevier_inst
(
 .CLK (pclk_global), // currently CLK is not used in this module
 .RESET (reset),

 .RED (dpi_r), .GREEN (dpi_g), .BLUE (dpi_b),
 .HSYNC (~dpi_h_sync), .VSYNC (~dpi_v_sync),
 .DE (dpi_de), .PCLK (pclk_global),

 .ADDR_H (dpi_out_addr_h), .ADDR_V (dpi_out_addr_v),
 .Q_RED (dpi_out_r), .Q_GREEN (dpi_out_g), .Q_BLUE (dpi_out_b)
);

//------------------------------------------------------------------------------
// strobes generator
strobe_gen_1k_50_5_1
#( .INPUT_FREQUENCY_KHZ (8000) )
strobe_gen_1k_from_8M
(
	.CLK (clk_pll_dclk),
 	.STB_1K (strobe_1khz), .STB_50 (strobe_50hz), .STB_1 (strobe_1hz)
);

//------------------------------------------------------------------------------
// DPI freq measurement
reg [15:0] freq_detector;
reg        is_dpi_freq;
always @(posedge clk_pll_dclk)
 begin
   if(strobe_1khz)
	 begin
	   if(freq_detector) freq_detector--;
	 end
   else
	 if (dpi_de == 1'b0)
	  begin
	   if(freq_detector != 16'hFF) freq_detector++;
	  end
	 
	 is_dpi_freq <= freq_detector != 0;
	 
  //freq_detector <= {freq_detector[62:0], dpi_de};
  //is_dpi_freq <= (freq_detector != 32'hFF) && ((freq_detector != 32'h00));
  //is_dpi_freq <= ^freq_detector;
 end
  

freq_measure
#( .FREQ_CNT_WIDTH (16), .COUNT_MODE ("STB_1K") )
freq_measure_dpi_freq
(
 .RESET (~is_dpi_freq),
 .STB_1K (strobe_1khz),
 .DE (1'b0),
 .FREQ_TO_MEASURE (dpi_pclk),//(pclk_global), // use the same input clock edge as for clocking other modules!
 .RESULT_MEASURED (dpi_frequency)
);

//------------------------------------------------------------------------------
// DPI horiz. pixels measurement
freq_measure
#( .FREQ_CNT_WIDTH (11), .COUNT_MODE ("DE") )
freq_measure_dpi_horsize
(
 .RESET (reset),
 .STB_1K (1'b0),
 .DE (dpi_de),
 .FREQ_TO_MEASURE (dpi_pclk),//(pclk_global), 
 .RESULT_MEASURED (dpi_hor_size)
);
//------------------------------------------------------------------------------
// comparators for is_sync signal
dpi_sync_detector
#(
 .TARGET_FREQ (31500),   .TARGET_WIDTH (800),
 .HYSTERESIS_FREQ (512), .HYSTERESIS_WIDTH (4)
)
dpi_sync_detector_800x480
(
 .CLK (clk_pll_dclk), .RESET (reset),
 .FREQ (dpi_frequency), .WIDTH (dpi_hor_size),
 .IS_SYNC (is_sync_800x480)
);

dpi_sync_detector
#(
 .TARGET_FREQ (25175),   .TARGET_WIDTH (640),
 .HYSTERESIS_FREQ (256), .HYSTERESIS_WIDTH (2)
)
dpi_sync_detector_640x480
(
 .CLK (clk_pll_dclk), .RESET (reset),
 .FREQ (dpi_frequency), .WIDTH (dpi_hor_size),
 .IS_SYNC (is_sync_640x480)
);

always @(posedge clk_pll_dclk or posedge reset)
 if (reset)  is_sync_dpi <= 0;
  else       is_sync_dpi <= (is_sync_640x480 | is_sync_800x480);
	
//------------------------------------------------------------------------------
// REGISTERS' File

regfile_uart_mapper
#(
 .UART_BASIC_FREQ (1152000), .UART_BAUD_RATE  (9600),
 
 .REG_0_RST_VAL (REG_0_RST_VALUE), .REG_1_RST_VAL (REG_1_RST_VALUE),
 .REG_2_RST_VAL (REG_2_RST_VALUE), .REG_3_RST_VAL (REG_3_RST_VALUE),
 .REG_4_RST_VAL (REG_4_RST_VALUE), .REG_5_RST_VAL (REG_5_RST_VALUE),
 .REG_6_RST_VAL (REG_6_RST_VALUE), .REG_7_RST_VAL (REG_7_RST_VALUE),
 .REG_16_RST_VAL (REG_16_RST_VALUE), .REG_17_RST_VAL (REG_17_RST_VALUE), .REG_18_RST_VAL (REG_18_RST_VALUE), 
 .REG_19_RST_VAL (REG_19_RST_VALUE), .REG_20_RST_VAL (REG_20_RST_VALUE), .REG_21_RST_VAL (REG_21_RST_VALUE),
 .REG_22_RST_VAL (REG_22_RST_VALUE), .REG_23_RST_VAL (REG_23_RST_VALUE), .REG_24_RST_VAL (REG_24_RST_VALUE)
)
regfile_uart_mapper_inst
(
 .CLK   (clk_1152k),
 .RESET (reset),
 
 .REGFILE_OUT (regfile_out),
 .REGFILE_IN  (regfile_in),
 
 .RXD (uart_rx),
 .TXD (uart_tx)
);

//------------------------------------------------------------------------------
wire [31:0] version_number;
version_num version_number_inst ( .VERSION (version_number) );

//------------------------------------------------------------------------------

endmodule
