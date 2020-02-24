// VGA Sync generator
// Author: Dim Su, based on DevKit examples 

module video_sync_generator
#(
// timing parameters
parameter hor_line  = 800,
parameter hor_front = 16,
parameter H_sync_cycle = 96,
parameter hor_back  = 144, //48?

parameter vert_line  = 525,

parameter vert_front = 11,
parameter V_sync_cycle = 2,
parameter vert_back  = 34
)

(
 input RESET,
 input VGA_CLK,
 output reg DE,
 output reg HS,
 output reg VS,
 
 output  [10:0] CNT_H,
 output  [9 :0] CNT_V
 );


/*
--VGA Timing
--Horizontal :
--                   ___________                 _____________
--                  |           |               |
--__________________|  VIDEO    |_______________|  VIDEO (next line)
--
--            _                       _
--___________| |_____________________| |______________________
--            B <-C-><----D----><-E->
--           <------------A--------->
--The Unit used below are pixels;  
--  B->Sync_cycle                   :H_sync_cycle
--  C->Back_porch                   :hor_back
--  D->Visible Area
--  E->Front porch                  :hor_front
--  A->horizontal line total length :hor_line
--Vertical :
--                  ___________                 _____________
--                 |           |               |          
--_________________|  VIDEO    |_______________|  VIDEO (next frame)
--
--           _                       _
--__________| |_____________________| |______________________
--           P <-Q-><----R----><-S->
--          <-----------O---------->
--The Unit used below are horizontal lines;  
--  P->Sync_cycle                   :V_sync_cycle
--  Q->Back_porch                   :vert_back
--  R->Visible Area
--  S->Front porch                  :vert_front
--  O->vertical line total length   :vert_line
*/

//////////////////////////
reg [10:0] h_cnt;
reg [9:0]  v_cnt;
wire cHD, cVD, cDE, hor_valid, vert_valid;
///////
always@(posedge VGA_CLK, posedge RESET)
begin
  if (RESET)
  begin
     h_cnt<=11'd0;
     v_cnt<=10'd0;
  end
    else
    begin
      if (h_cnt==hor_line-1)
      begin 
         h_cnt<=11'd0;
         if (v_cnt==vert_line-1)   v_cnt<=10'd0;
          else                     v_cnt<=v_cnt+1;
      end
      else                         h_cnt<=h_cnt+1;
    end
end

//
assign cHD = (h_cnt < H_sync_cycle) ? 1'b1 : 1'b0; // these signals are POS active
assign cVD = (v_cnt < V_sync_cycle) ? 1'b1 : 1'b0;

assign hor_valid =  (h_cnt < (hor_line-hor_front-1)   && h_cnt >= hor_back-1)  ? 1'b1 : 1'b0;
assign vert_valid = (v_cnt < (vert_line-vert_front-1) && v_cnt >= vert_back-1) ? 1'b1 : 1'b0;

assign cDE = hor_valid && vert_valid;

always @(posedge VGA_CLK)
begin
  HS    <= cHD;
  VS    <= cVD;
  DE    <= cDE;
end

assign CNT_H = h_cnt,
       CNT_V = v_cnt;

endmodule


