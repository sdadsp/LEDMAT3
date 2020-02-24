//==============================================================================
//  Purpose:  top level of the vga controller
//  Version: v1.2
//  Input:   Pixel Clock
//  Output:  H/V sync, DE
//  Author:  DS, based on DevKit examples
//  History Release: 
//  20170901 - initial ver.
//  20171009 - linting performed
//==============================================================================

module vga_controller
#( parameter VIDEO_W = 640, parameter VIDEO_H = 480)

(
 input RESET,
 input VGA_CLK,
 input [1:0]TP_SEL,    // test pattern selector
 
 output reg DE,
 output reg H_SYNC,
 output reg V_SYNC,
 output reg [7:0] VGA_B,
 output reg [7:0] VGA_G,
 output reg [7:0] VGA_R,
 
 output reg [10:0] ADDR_H,
 output reg [9:0]  ADDR_V

 );
 
//------------------------------------------------------------------------------
wire [7:0] tpg_vga_r, tpg_vga_b, tpg_vga_g;

wire h_sync, v_sync, de;

wire [10:0] cnt_h;
wire [ 9:0] cnt_v;

wire [10:0]  addr_h;
wire [9:0]   addr_v;

//------------------------------------------------------------------------------
//assign VGA_R = tpg_vga_r, VGA_G = tpg_vga_g, VGA_B = tpg_vga_b;
always @(posedge VGA_CLK)
 begin
             //if ( !( (addr_h > 0) && (addr_h <= VIDEO_W) ) )
  if ( ~de ) // it is mandatory to blank the RGB data at the inactive (blanked) 
    begin    // periods to achieve proper synchronization and color recovering
       VGA_R <= 0; VGA_G <= 0; VGA_B <= 0;
    end 
		else
     begin
       VGA_R <= tpg_vga_r; VGA_G <= tpg_vga_g; VGA_B <= tpg_vga_b;
     end
 end
 
// we should align address with r/g/b data
always @(posedge VGA_CLK)
 begin
  ADDR_H <= addr_h;
  ADDR_V <= addr_v;
 end

 
//Delay the HS, VS, DE for 1 clock cycle, as well
//reg m_h_sync, m_v_sync, m_de;
always @(posedge VGA_CLK)
begin
  H_SYNC   <= h_sync;  // output signals are pos. active!
  V_SYNC   <= v_sync; 
  DE       <= ~de;   
end
 
//------------------------------------------------------------------------------
// generates H_SYNC, V_SYNC, and BLANK signals
video_sync_generator video_sync_inst
 (
 .VGA_CLK (VGA_CLK),
 .RESET(RESET),
 .DE(de),
 .HS(h_sync),
 .VS(v_sync),
 .CNT_H(cnt_h),
 .CNT_V(cnt_v)
);
  defparam
  video_sync_inst.hor_line  = 800,
  video_sync_inst.hor_front = 16,
  video_sync_inst.H_sync_cycle = 96,
  video_sync_inst.hor_back  = 144, // 48?
  video_sync_inst.vert_line  = 525,
  video_sync_inst.vert_front = 11,
  video_sync_inst.V_sync_cycle = 2,
  video_sync_inst.vert_back  = 34;

//------------------------------------------------------------------------------
// generates the Horizontal address and vertical address of a current pixel
video_address_generator
#(
 .VIDEO_W (VIDEO_W),
 .VIDEO_H (VIDEO_H)
)
 video_address_generator_inst
(
 .PCLK (VGA_CLK),
 .RESET (RESET),
 .DE (de),
 
 .ADDR_H (addr_h),
 .ADDR_V (addr_v)
);

//------------------------------------------------------------------------------
// 4 test patterns can be chosen using TP_SEL input
test_pattern_generator
#(
 .VIDEO_W (VIDEO_W),
 .VIDEO_H (VIDEO_H)
)
 test_pattern_generator_inst
(
 .PCLK (VGA_CLK),
 .RESET (RESET),
 .TP_SEL (TP_SEL),
 .ADDR_H (addr_h),
 .ADDR_V (addr_v),
 
 .VGA_B (tpg_vga_b),
 .VGA_G (tpg_vga_g),
 .VGA_R (tpg_vga_r)
);

//------------------------------------------------------------------------------

endmodule
