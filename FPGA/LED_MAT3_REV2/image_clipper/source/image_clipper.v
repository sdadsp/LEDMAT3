//==============================================================================
// Author:  Dim Su
// Date:    20170929
// Updated: 20171004
//          20171017 - parameter IMAGE_HEIGHT replaced by an input bus
// History Release:
//
// IMAGE CROPPER
// input: 640x480 image (may be any resolution)
// output: (IMAGE_WIDTH * IMAGE_HEIGHT) cropped image address
//==============================================================================

`default_nettype none


module image_clipper #( 
parameter OUT_ADDR_WIDTH = 11,
parameter IMG_WIDTH_MAX_LOG2
)
(
 input CLK,
 input RESET,
 
 input [IMG_WIDTH_MAX_LOG2-1:0] IMAGE_WIDTH,
 input [5:0] IMAGE_HEIGHT,
 
 input [10:0] ADDR_H, ROI_X0,
 input [9:0]  ADDR_V, ROI_Y0,

 output reg OUT_DATA_VALID,
 
 output reg [OUT_ADDR_WIDTH-1:0] OUT_DATA_ADDR
);

reg is_roi_x;
reg is_roi_y;
reg is_not_roi_yet;
always @(posedge CLK)
 begin
  is_roi_x       <= (ADDR_H >= ROI_X0) && (ADDR_H < ROI_X0 + IMAGE_WIDTH);
  is_roi_y       <= (ADDR_V >= ROI_Y0) && (ADDR_V < ROI_Y0 + IMAGE_HEIGHT);
  is_not_roi_yet <= (ADDR_H < ROI_X0)  && (ADDR_V < ROI_Y0);
 end

wire is_roi = is_roi_x && is_roi_y;
 
always @(posedge CLK or posedge RESET)
 if (RESET)   OUT_DATA_ADDR <= 0;
  else
   begin
	 if (is_roi)
	           OUT_DATA_ADDR++;
	  else
       if (is_not_roi_yet)
              OUT_DATA_ADDR <= 0;
   end

// data write strobes
always @(posedge CLK or posedge RESET)
 if (RESET)   OUT_DATA_VALID <= 1'b0;
  else
   begin
	 if (is_roi)
	           OUT_DATA_VALID <= 1'b1;
	  else     OUT_DATA_VALID <= 1'b0;
   end


endmodule

