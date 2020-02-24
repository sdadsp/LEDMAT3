//=======================================================
//  Name:    24B PRGB DPI Recevier
//   
//  Input:   24-bit Parallel RGB
//  Output:  synchronized RGB-data, vertical and horizontal pixel-address
//
//  Version: v1.0
//  Date:    20170901
//  Updated: 20171003
//  History Release:
//  20180519 - registered outputs
//
//  Author:  Dim Su
//=======================================================


module dpi_recevier
#(
parameter INPUT_RESOLUTION_H = 640,
parameter INPUT_RESOLUTION_V = 480,
parameter WHOLE_LINE = 800,
parameter WHOLE_FRAME = 525,
parameter BACK_PORCH_V = 33,
parameter BACK_PORCH_H = 48,
parameter FRONT_PORCH_V = 16,
parameter FRONT_PORCH_H = 10
)

(
input CLK,
input RESET,

input [7:0] RED, GREEN, BLUE,
input HSYNC, VSYNC,
input DE,
input PCLK,

output [10:0] ADDR_H,
output [ 9:0] ADDR_V,
output [ 7:0] Q_RED, Q_GREEN, Q_BLUE

);

reg [10:0]cnt_h;
reg [9:0] cnt_v;
reg [7:0] reg_red, reg_green, reg_blue;

//wire is_x1 = (cnt_h == 1);
wire is_x0 = (cnt_h == 11'd0);

// count the incoming pixel data
always @ (posedge PCLK or posedge RESET)
 if (RESET)
  begin
    cnt_h <= 0; cnt_v <= 0;
  end
  else
   begin

    if (HSYNC)    cnt_h <= 0;
	  else if (DE) cnt_h++;
	  
    if (VSYNC)               cnt_v <= 0;
	  else if ( DE && is_x0 ) cnt_v++;
	   
   end

	
// delay and sync line for RGB
always @ (posedge PCLK)
 begin
   reg_red   <= RED;
   reg_green <= GREEN;
	reg_blue  <= BLUE;
 end
	

assign ADDR_H = cnt_h; 
assign ADDR_V = cnt_v; 
assign Q_RED  = reg_red, Q_GREEN = reg_green, Q_BLUE = reg_blue;


endmodule
