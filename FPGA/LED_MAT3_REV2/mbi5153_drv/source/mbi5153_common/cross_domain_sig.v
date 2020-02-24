//******************************************************************************
// Crossing clock domains
// Slow clock domain: input signal
// Fast clock domain: output signal
// CLK: fast clock-domain clock
// Date: 20180104
// Author:  Dim Su
//******************************************************************************

// synopsys translate_off
`timescale 1 ns / 10 ps
// synopsys translate_on

`default_nettype none

// define the propagation delay (for simulation)
`define PD_TRIG 5
`define PD_COMB 5

module cross_domain_sig
(
 input  wire CLK,
 input  wire IN,
 output wire OUT
);

//******************************************************************************
reg [1:0] delay;

assign OUT = delay[1];

//******************************************************************************
// crossing clock-domains:
always @(posedge CLK)
  begin
   delay[1] <= delay[0];  delay[0] <= IN;
  end
  
//******************************************************************************

endmodule


