//==============================================================================
//  Purpose: test pattern generator for vga controller
//  Version: v1.0
//  Input:   Pixel Clock, Pixels's address
//  Output:  RGB test patterns (select by TP_SEL input)
//  Author: Dim Su
//  History Release: 
//  20171009 - initial ver.
//==============================================================================

module test_pattern_generator
#(
 parameter VIDEO_W = 640,
 parameter VIDEO_H = 480
)

(
 input PCLK,
 input RESET,
 input [1:0]TP_SEL,    // test pattern selector
 input [1:0]TP_COLOR,  // test patter color

 input [10:0] ADDR_H,
 input [ 9:0] ADDR_V,
 
 output [7:0] VGA_B,
 output [7:0] VGA_G,
 output [7:0] VGA_R
);

// to show "grey breath" on the 256x64 screen area
localparam PANEL_HEIGHT = 64;
localparam IMG_WIDTH    = 256;

//------------------------------------------------------------------------------
reg [23:0] rgb_data;

wire [10:0] addr_h = ADDR_H;
wire [ 9:0] addr_v = ADDR_V;

reg  [7:0]  corr_red, corr_green, corr_blue;
reg  [3:0]  corr_speed_div;
reg         flag_count_dir;

wire [13:0] test_gray_data; 
wire [21:0] test_gray_data_corrected; 

wire [23:0] COLOR_WHITE    = {8'hFF, 8'hFF, 8'hFF};
wire [23:0] COLOR_YELLOW   = {8'hFF, 8'hFF, 8'h00};
wire [23:0] COLOR_CYAN     = {8'h00, 8'hFF, 8'hFF};
wire [23:0] COLOR_GREEN    = {8'h00, 8'hFF, 8'h00};
wire [23:0] COLOR_MAGENTA  = {8'hFF, 8'h00, 8'hFF};
wire [23:0] COLOR_RED      = {8'hFF, 8'h00, 8'h00};
wire [23:0] COLOR_BLUE     = {8'h00, 8'h00, 8'hFF};
wire [23:0] COLOR_GREY     = {8'h20, 8'h20, 8'h20};
wire [23:0] COLOR_WHITE2    = {8'h88, 8'h88, 8'h88};
wire [23:0] COLOR_YELLOW2   = {8'h88, 8'h88, 8'h00};
wire [23:0] COLOR_CYAN2     = {8'h00, 8'h88, 8'h88};
wire [23:0] COLOR_GREEN2    = {8'h00, 8'h88, 8'h00};
wire [23:0] COLOR_MAGENTA2  = {8'h88, 8'h00, 8'h88};
wire [23:0] COLOR_RED2      = {8'h88, 8'h00, 8'h00};
wire [23:0] COLOR_BLUE2     = {8'h00, 8'h00, 8'h88};
wire [23:0] COLOR_GREY2     = {8'h18, 8'h18, 8'h18};

//------------------------------------------------------------------------------
assign VGA_R = rgb_data[23:16];
assign VGA_G = rgb_data[15:8]; 
assign VGA_B = rgb_data[7:0];

//------------------------------------------------------------------------------
wire is_pixel_1  = ( (addr_v == 1) && (addr_h == 1) );
wire is_pixel_32 = ( (addr_v == 32) && (addr_h == 32) );

//------------------------------------------------------------------------------
// slow gray-scale breathing
always @(posedge PCLK)
 begin
    if (corr_red == 8'hff)        flag_count_dir = 1;
	   else if (corr_red == 8'h00)  flag_count_dir = 0;
		
	 if (is_pixel_1) corr_speed_div++;
 end

always @(posedge PCLK)
 if ( (corr_speed_div == 0)  && is_pixel_1 )
 begin
   if (flag_count_dir == 0) corr_red++;
    else                    corr_red--;
 end

 /*
// put a probe out, for debug
test_vector_1 u0 (
//		.source (<connected-to-source>), // sources.source
		.probe  (corr_red)   //  probes.probe
	);
*/ 
 
// atn: a multiplyer is to be used
assign  test_gray_data = ( addr_h[7:0] * addr_v[5:0] ); // tbd - to adjust all colors independly
//assign  test_gray_data_corrected = test_gray_data * corr_red;

//------------------------------------------------------------------------------
// Pattern generator
always @* // TBD - sensitivity list
//always @(posedge PCLK)
begin
/*  if (RESET)
  begin
     rgb_data <= 24'h000000;
  end
    else*/
	 case (TP_SEL)
	 2'b00:          // vertical bars
    begin
            if ( (addr_v == 10) && (addr_h == 10) ) // mark the test pixel #(10,10)
		         rgb_data <= 24'h00AA00;
				else	
			   if (0<addr_h && addr_h <= VIDEO_W*1/16)
					rgb_data <= COLOR_WHITE;
				else if (addr_h > VIDEO_W*1/16 && addr_h <= VIDEO_W*2/16)
					rgb_data <= COLOR_YELLOW;
				else if (addr_h > VIDEO_W*2/16 && addr_h <= VIDEO_W*3/16)
					rgb_data <= COLOR_CYAN;
				else if (addr_h > VIDEO_W*3/16 && addr_h <= VIDEO_W*4/16)
					rgb_data <= COLOR_GREEN;
				else if (addr_h > VIDEO_W*4/16 && addr_h <= VIDEO_W*5/16)
					rgb_data <= COLOR_MAGENTA;
				else if (addr_h > VIDEO_W*5/16 && addr_h <= VIDEO_W*6/16)
					rgb_data <= COLOR_RED;
				else if (addr_h > VIDEO_W*6/16 && addr_h <= VIDEO_W*7/16)
					rgb_data <= COLOR_BLUE;
				else if (addr_h > VIDEO_W*7/16 && addr_h <= VIDEO_W*8/16)
					rgb_data <= COLOR_GREY;
				else if (addr_h > VIDEO_W*8/16 && addr_h <= VIDEO_W*9/16)
					rgb_data <= COLOR_GREY2;
				else if(addr_h > VIDEO_W*9/16  && addr_h <=VIDEO_W*10/16)
					rgb_data <= COLOR_YELLOW2;
				else if(addr_h > VIDEO_W*10/16 && addr_h <=VIDEO_W*11/16)
					rgb_data <= COLOR_CYAN2;
				else if(addr_h > VIDEO_W*11/16 && addr_h <=VIDEO_W*12/16)
					rgb_data <= COLOR_GREEN2;
				else if(addr_h > VIDEO_W*12/16 && addr_h <=VIDEO_W*13/16)
					rgb_data <= COLOR_MAGENTA2;
				else if(addr_h > VIDEO_W*13/16 && addr_h <=VIDEO_W*14/16)
					rgb_data <= COLOR_RED2;
				else if(addr_h > VIDEO_W*14/16 && addr_h <=VIDEO_W*15/16)
					rgb_data <= COLOR_BLUE2;
				else if(addr_h > VIDEO_W*15/16 && addr_h <=VIDEO_W)
					rgb_data <= COLOR_GREY;
				else rgb_data <= 24'h000000;
    end
	 
	 2'b01:         // plain color
    begin
//	   if ( !( (addr_h > 0) && (addr_h <= VIDEO_W) ) ) // it is mandatory to blank the RGB data at the inactive (blanked) periods
//		         rgb_data <= 24'h0000;                  // to achieve proper synchronization and color recovering
//		 else
		  begin
	 
         if      ( TP_COLOR == 2'b00 )		rgb_data <= {8'h0F, 8'h0F, 8'h0F}; // grey
		 	else if ( TP_COLOR == 2'b01 )		rgb_data <= {8'hFF, 8'h00, 8'h00}; // red
		 	else if ( TP_COLOR == 2'b10 )		rgb_data <= {8'h00, 8'hFF, 8'h00}; // green
		 	else if ( TP_COLOR == 2'b11 )		rgb_data <= {8'h00, 8'h00, 8'hFF}; // blue
			
		  end
    end
/*
	 2'b10: // diagonal line
	 begin
         if (  ( (addr_v >= 1) && (addr_v <= VIDEO_H) ) && ( (addr_h >= 1) && (addr_h <= VIDEO_W) ) )
			begin
			 if ( (addr_v == (addr_h >> 1))  )
		           rgb_data <= 24'h22AA22;
			  else  rgb_data <= 24'h0000;
			end
			 else   rgb_data <= 24'h000000;
	 end
*/

	 2'b10: // black screen
	 begin
        rgb_data <= 24'h000000;
	 end

	 default: // grey gradient (2'b11)
	 begin
       if ( is_pixel_32 ) // mark the pixel #(4,4)
		           rgb_data <= 24'h005555;
		  else
       if ( is_pixel_1 ) // mark the pixel #(1,1)
		           rgb_data <= 24'h0000AA;
		  else
         if (  ( (addr_v >= 1) && (addr_v <= PANEL_HEIGHT) ) && ( (addr_h >= 1) && (addr_h <= IMG_WIDTH) ) )
	  				  rgb_data <= { 3{test_gray_data[13-:8]} }; 
	  				  //rgb_data <= { 3{test_gray_data_corrected[21-:8]} }; 
			 else   rgb_data <= 24'h000000;
	 end

	 endcase
	 
end
//------------------------------------------------------------------------------


endmodule
