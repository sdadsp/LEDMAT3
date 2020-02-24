//==============================================================================
//  Purpose:  piexls' address generator for vga controller
//  Version: v1.0
//  Input:   Pixel Clock, Blanking signal
//  Output:  Horizontal address and vertical address of the current pixel
//  Author: Dim Su
//  History Release: 
//  20171009 - initial ver.
//==============================================================================

module video_address_generator
#(
 parameter VIDEO_W = 640,
 parameter VIDEO_H = 480
)
(
 input PCLK,
 input RESET,
 
 input DE,
 
 output [10:0] ADDR_H,
 output [9:0]  ADDR_V
);

//------------------------------------------------------------------------------
reg [18:0]  addr;    // tbu
reg [10:0]  addr_h;
reg [9:0]   addr_v;

//------------------------------------------------------------------------------
assign ADDR_H = addr_h, ADDR_V = addr_v;

//------------------------------------------------------------------------------
////Addresss (pixel) generator
always@(posedge PCLK, posedge RESET)
begin
  if (RESET)                  addr_h <= 11'd0;
   else if (DE) // if "data enable"
                              addr_h <= addr_h + 1;
	  else                      addr_h <= 11'd0;
end

//------------------------------------------------------------------------------
always @(posedge PCLK, posedge RESET)
begin
  if (RESET)                  addr_v <= 10'd0;
   else if ( (addr_v == VIDEO_H - 1) && (addr_h == VIDEO_W - 1) )
                              addr_v <= 10'd0;
		else if (addr_h == VIDEO_W - 1)
                              addr_v <= addr_v + 1;
end


endmodule
