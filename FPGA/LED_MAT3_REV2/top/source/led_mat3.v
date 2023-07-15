//==============================================================================
//  Name:     Top-level for the [3*120x90]-array driver project
//  Hardware: LED_MAT3 Rev. 1.0
//  Version:  v1.0
//  Author: Dim Su
//  History Release:
//  20180825 - Initial version (1.0)
//  20230623 - HPD Trig option 
//
//==============================================================================

// to prevent creating the implicit nets:
`default_nettype none

module led_mat3(

 input        MCLK_25M,
	
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

 input	     DVI_ENA,
 
 output       DVI_CONFIRM, //BL_ON signal

 input 	     KEY,

 output	     LEDG,
 output       LEDY

);

wire [7:0] led;
wire [1:0] key;


assign LEDG = led[0], LEDY = led[1];

assign key[0] = 1'b0, key[1] = 1'b0;

//assign DVI_CONFIRM = 1'b1;


led_mat_core led_mat_core_inst
(
 .RESET (1'b0),
 .MCLK_IN (MCLK_25M),
	
 .DPI_H_SYNC (DPI_H_SYNC), .DPI_V_SYNC (DPI_V_SYNC),
 .DPI_PCLK (DPI_PCLK),
 .DPI_DE (DPI_DE),
 .DPI_R (DPI_R), .DPI_G (DPI_G), .DPI_B (DPI_B),
 .HPD_TRIG(DVI_CONFIRM),
	
 .HUB1_R (HUB1_R), .HUB1_G (HUB1_G), .HUB1_B (HUB1_B),
 .HUB2_R (HUB2_R), .HUB2_G (HUB2_G), .HUB2_B (HUB2_B),
 .HUB3_R (HUB3_R), .HUB3_G (HUB3_G), .HUB3_B (HUB3_B),
 .HUB_ADDR (HUB_ADDR),
 
 .HUB_LATCH (HUB_LATCH), .HUB_CLK (HUB_CLK),
 .HUB_GCLK (HUB_GCLK),
 
 .UART_RX (UART_RX), .UART_TX (UART_TX),
 
// .DVI_SDA (DVI_SDA), .DVI_SCL (DVI_SCL),

 .LED (led),
 
 .KEY (key),
 
 .TEST_LATCH_POS (1),  // 1 = ICN2038, 0 = MBI5124
 .TEST_PATTERN_SEL (2'b00),
 .TEST_STOP_CLIPPER (0),
 .TEST_TPG_RESET (0),
 .TEST_UPGS_DIS (0),
 .TEST_RGB_INPUT (~DVI_ENA)
);


endmodule
