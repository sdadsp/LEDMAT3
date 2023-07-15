
// parameters of the system: buses width, limitations, parameters, etc.

`ifndef _ledmat_main_defines_
`define _ledmat_main_defines_

`include "define_led_driver.vh"

// this defines the debug things, like bit-masking, etc.
//`define DEBUG_BIT_MASKING
//`define COMPILE_MODE_ICN2053
//`define COMPILE_MODE_MBI5153

//`define ROWS_NUM_PER_LANE 30

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// User configurable parameters
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
`ifdef LED_DRIVER_MBI5153
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 parameter DEFAULT_SCAN_RATIO = 30-1; // 29 means '30', 30 means '31', 31 means '32'(max)
// parameter DEFAULT_SCAN_RATIO = 32-1;
 parameter IMAGE_WIDTH_RST_VAL = 384; // 

 parameter NUM_LANES_MAX = 3;    // actual number of lanes ("target" ("longrunled") panel comprises of 3 lanes)
 parameter NUM_IC_CHAIN = 8;     // 4 - for the small panel 64x64, 8- for the panel 120x90

 parameter MULTIPLEX_RATIO = 32; // maximum scan ratio for the selected panel

 parameter NUM_PANELS      = 3;  // maximim number of LED matrix panels - will be used to calculate the memory buffer size
 parameter PIXEL_DEPTH     = 8;  // number of bits per color
    
// Special parameters 
 parameter PANEL_WIDTH  = 128;   // the panel width is 120 pixels, but actually every 16th pixel is omitted
 parameter PANEL_HEIGHT = 90;    // height of the panel in pixels
 parameter PANEL_LANES  = 3;
 
 parameter OUTBUF_DATA_WIDTH = PIXEL_DEPTH * 3;
 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//`elsif LED_DRIVER_ICN2053
`else
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 parameter DEFAULT_SCAN_RATIO = 16;
 parameter IMAGE_WIDTH_RST_VAL = 192;

 parameter NUM_LANES_MAX = 2;    // maximum number of lanes ("classic" LED panel comprises of 2 lanes)

 parameter MULTIPLEX_RATIO = 16;

 parameter NUM_PANELS      = 3;  // maximim number of LED matrix panels - will be used to calculate the memory buffer size
 parameter PIXEL_DEPTH     = 8;  // number of bits per color
    
// Special parameters 
 parameter PANEL_WIDTH  = 64; // width of the panel in pixels
 parameter PANEL_HEIGHT = 32; // height of the panel in pixels
 parameter PANEL_LANES = 2;   // normally 2
 
 parameter OUTBUF_DATA_WIDTH = PIXEL_DEPTH * 3;
 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
`endif // COMPILE_MODE_MBI5153    
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

 parameter BRIGHTNESS_PWM_DEPTH = 5; // how many bits are used for the global brightness control
 parameter PWM_QUANTUM_MAX = 15; // for the MBI5124 driver we perform a binary-coded PWM; the smallest quantum for that PWM is set here (in DCLK's periods)
// LATCH position for ICN2038S:
 parameter LATCH_START_POS_ICN2038S = -3;
 parameter LATCH_END_POS_ICN2038S   = 0;
// LATCH position for MBI5124:
 parameter LATCH_START_POS_MBI5124 = 0;
 parameter LATCH_END_POS_MBI5124   = 1;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Parameters for memory definitions


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Common constants
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 parameter ROI_X0 = 128;
 parameter ROI_Y0 = 128;

 parameter IMAGE_WIDTH_MAX = 256;
 parameter IMAGE_WIDTH_MAX_LOG2 = $clog2(IMAGE_WIDTH_MAX + 1);

// Derived parameters
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 parameter BRIGHTNESS_PWM_MAX = 2 ** BRIGHTNESS_PWM_DEPTH;

 parameter NUM_LANES_WIDTH   = $clog2(NUM_LANES_MAX + 1);
 parameter PWM_QUANTUM_WIDTH = $clog2(PWM_QUANTUM_MAX + 1);
 parameter NUM_PANELS_WIDTH  = $clog2(NUM_PANELS + 1);

 parameter OUTBUF_ADDR_WIDTH  = $clog2(NUM_PANELS * PANEL_WIDTH * PANEL_HEIGHT/PANEL_LANES);
 
 parameter DISPLAY_WIDTH     = PANEL_WIDTH * NUM_PANELS;
// parameter IMG_WIDTH_ACTUAL_LOG2     = $clog2(IMG_WIDTH_ACTUAL); 
 
 parameter MEMORY_WIDTH = MULTIPLEX_RATIO * DISPLAY_WIDTH; 
 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 

`ifdef LED_DRIVER_MBI5153
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// MBI5153 specific parameters
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/*          
parameter  DATA_RCFG1_R = 16'b1101_1111_0010_1011,
           DATA_RCFG1_G = 16'b1101_1111_0010_1011,
           DATA_RCFG1_B = 16'b1101_1111_0010_1011;
*/           
// Register 1, 30 rows per lane:
//....................................FEDC.BA98.7654.3210           
parameter  RST_VAL_DATA_RCFG1_R = 16'b0001_1101_0000_0100,
           RST_VAL_DATA_RCFG1_G = 16'b0001_1101_0000_0000,
           RST_VAL_DATA_RCFG1_B = 16'b0001_1101_0000_1000;
/*			  
// Register 1, 32 rows per lane:
//....................................FEDC.BA98.7654.3210           
parameter  RST_VAL_DATA_RCFG1_R = 16'b0001_1111_0000_0011,
           RST_VAL_DATA_RCFG1_G = 16'b0001_1111_0000_0011,
           RST_VAL_DATA_RCFG1_B = 16'b0001_1111_0000_0011;
*/
//....................................FEDC.BA98.7654.3210           
parameter  RST_VAL_DATA_RCFG2_R = 16'b0100_0001_0000_0000,
           RST_VAL_DATA_RCFG2_G = 16'b0110_0001_0000_0000,
           RST_VAL_DATA_RCFG2_B = 16'b0110_0001_0000_0000;
//....................................FEDC.BA98.7654.3210           
parameter  RST_VAL_DATA_RCFG3_R = 16'b1100_0000_0000_0011,
           RST_VAL_DATA_RCFG3_G = 16'b0110_0001_0000_0011,
           RST_VAL_DATA_RCFG3_B = 16'b0011_0011_0000_0011;

`else
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// ICN2053 specific parameters
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/*          
parameter  DATA_RCFG1_R = 16'b1101_1111_0010_1011,
           DATA_RCFG1_G = 16'b1101_1111_0010_1011,
           DATA_RCFG1_B = 16'b1101_1111_0010_1011;
*/           
//....................................FEDC.BA98.7654.3210           
parameter  RST_VAL_DATA_RCFG1_R = 16'b0001_1111_0000_0011,
           RST_VAL_DATA_RCFG1_G = 16'b0001_1111_0000_0000,
           RST_VAL_DATA_RCFG1_B = 16'b0001_1111_0000_0111;
//....................................FEDC.BA98.7654.3210           
parameter  RST_VAL_DATA_RCFG2_R = 16'b0100_0001_0000_0000,
           RST_VAL_DATA_RCFG2_G = 16'b0110_0001_0000_0000,
           RST_VAL_DATA_RCFG2_B = 16'b0110_0001_0000_0000;
//....................................FEDC.BA98.7654.3210           
parameter  RST_VAL_DATA_RCFG3_R = 16'b1100_0000_0000_0011,
           RST_VAL_DATA_RCFG3_G = 16'b0110_0001_0000_0011,
           RST_VAL_DATA_RCFG3_B = 16'b0011_0011_0000_0011;        
           
`endif // COMPILE_MODE_MBI5153       
         

`endif //_ledmat_main_defines_



