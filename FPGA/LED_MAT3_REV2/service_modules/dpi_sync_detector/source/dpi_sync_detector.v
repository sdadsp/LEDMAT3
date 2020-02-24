// DPI input sync detector
// FREQ - in kHz
// WIDTH - in pixels
// Author: Dim Su
// Date: 20171014

module dpi_sync_detector
#(
 parameter TARGET_FREQ  = 25175,
 parameter TARGET_WIDTH = 640,
 parameter HYSTERESIS_FREQ = 256,
 parameter HYSTERESIS_WIDTH = 2
)
(
 input CLK,
 input RESET,
 
 input [15:0] FREQ,
 input [10:0] WIDTH,
 
 output IS_SYNC
);

 reg is_sync;
 wire is_freq_ok, is_width_ok;

 assign  is_freq_ok  = ( (FREQ > (TARGET_FREQ-HYSTERESIS_FREQ)) && (FREQ < (TARGET_FREQ+HYSTERESIS_FREQ)) );
 assign  is_width_ok = ( (WIDTH > (TARGET_WIDTH-HYSTERESIS_WIDTH)) && (WIDTH < (TARGET_WIDTH+HYSTERESIS_WIDTH)) );
 
 always @(posedge CLK)
  is_sync <= (is_freq_ok & is_width_ok);

 assign IS_SYNC = is_sync;
 
endmodule
