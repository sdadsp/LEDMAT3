// Settings for ICN2053 (not checked in HW)
// Author:  Dim Su

 // parameters of the LATCH clock numbers for MBI5153
 
 //`define DEBUG_GCLK
 
 parameter CMD_STOP_CED   = 1,
           CMD_DL         = 2,
           CMD_VSYNC      = 3,
           CMD_WRC1       = 4,
           CMD_RDC1       = 5,
           CMD_START_CED  = 6,
           CMD_WRC2       = 7,
           CMD_RDC2       = 8,
           CMD_SRST       = 9,
           CMD_PREA       = 10,
           CMD_WRC3       = 11,
           CMD_RDC3       = 12;
           
parameter CMD_STOP_CED_DCLK   = 1,
          CMD_DL_DCLK         = 1,
          CMD_VSYNC_DCLK      = 2,
          CMD_WRC1_DCLK       = 4,
          CMD_RDC1_DCLK       = 5,
          CMD_START_CED_DCLK  = 7,
          CMD_WRC2_DCLK       = 8,
          CMD_RDC2_DCLK       = 9,
          CMD_SRST_DCLK       = 10,
          CMD_PREA_DCLK       = 14,
          CMD_WRC3_DCLK       = 16,
          CMD_RDC3_DCLK       = 17;
           
parameter  GCLK_CLOCKS_BEFORE_VSYNC = 60, //50,
           GCLK_STOP_AFTER_VSYNC = 50; //30;
           
`ifdef DEBUG_GCLK          
parameter PWM13_CYCLE_NUM_SECTIONS   = 2,               // 16
          PWM14_CYCLE_NUM_SECTIONS   = 4,               // 32
          PWM_CYCLE_GCLK_CLOCKS      = 8,              // 512
          GCLK_LINE_SWITCH_DEAD_TIME_H = 6,              // 6  @ 20MHz
          GCLK_LINE_SWITCH_DEAD_TIME_L = 8;             // 24 @ 20MHz
`else 
parameter PWM13_CYCLE_NUM_SECTIONS   = 16,               // 16
          PWM14_CYCLE_NUM_SECTIONS   = 32,               // 32
          PWM_CYCLE_GCLK_CLOCKS      = 512,              // 512
          GCLK_LINE_SWITCH_DEAD_TIME_H = 8,              // 8  @ 20MHz = 400ns
          GCLK_LINE_SWITCH_DEAD_TIME_L = 24;             // 24 @ 20MHz = 1200ns
`endif

// default values for the configuration registers:
//............................FEDC.BA98.7654.3210        
parameter  DATA_RCFG1_R = 16'b1101_1101_0000_0011,
           DATA_RCFG1_G = 16'b1101_1101_0000_0011,
           DATA_RCFG1_B = 16'b1101_1101_0000_0011;
//............................FEDC.BA98.7654.3210           
parameter  DATA_RCFG2_R = 16'b0100_0101_0000_0000,
           DATA_RCFG2_G = 16'b0110_0101_0000_0000,
           DATA_RCFG2_B = 16'b0110_0101_0000_0000;
//............................FEDC.BA98.7654.3210           
parameter  DATA_RCFG3_R = 16'b1100_0000_0000_0011,
           DATA_RCFG3_G = 16'b0110_0001_0000_0011,
           DATA_RCFG3_B = 16'b0011_0011_0000_0011;
           