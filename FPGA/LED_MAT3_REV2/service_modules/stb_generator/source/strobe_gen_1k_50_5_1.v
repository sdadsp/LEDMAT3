// strobes' generator
// input: Clk (50 MHz max)
// Output: 1-period strobes (1k, 50, 5, and 1 Hz)
// Author: Dim Su
// Date: 201707xx
// Updated: 20171013
// counters changed to count down to 0: 20180123

`default_nettype none

module strobe_gen_1k_50_5_1
#(
 parameter INPUT_FREQUENCY_KHZ = 10000
)
(
input  wire	CLK,
output wire	STB_1K, STB_50,	STB_5, STB_1
);

localparam CNT_50_INIT = 20;
localparam CNT_5_INIT = 10;
localparam CNT_1_INIT = 50;

reg [4:0] cnt50;
reg [3:0] cnt5;
reg [6:0] cnt1;

reg [14:0] prescaler;
reg stb_1k;
reg stb_50, stb_5, stb_1;

wire cnt50_done = (cnt50 == 0);
wire cnt5_done  = (cnt5  == 0);
wire cnt1_done  = (cnt1  == 0);

assign STB_1K = stb_1k,
       STB_50 = stb_50,
       STB_5  = stb_5,
       STB_1  = stb_1;

// perform initial reset, for the correct RTL simulaion
initial
 begin
  prescaler = 0; cnt50 = 0; cnt5 = 0; cnt1 = 0;
 end	
 
// prescaler downto 1kHz
always @ (posedge CLK)
 if(prescaler == 0)
  begin
   stb_1k <= 1;
   prescaler <= INPUT_FREQUENCY_KHZ-1;
  end 
  else
   begin
    stb_1k <= 0;
    prescaler <= prescaler - 1;
   end 
 
always @ (posedge CLK)
 if (stb_1k)
 begin
  if(cnt50_done)  cnt50 <= CNT_50_INIT-1;
   else           cnt50 <= cnt50 - 1;
	
 end

always @ (posedge CLK)
 if(stb_50)
  begin
   if(cnt5_done)  cnt5 <= CNT_5_INIT-1;
    else          cnt5 <= cnt5 - 1;
    
   if(cnt1_done)  cnt1 <= CNT_1_INIT-1;
    else          cnt1 <= cnt1 - 1;
  end

always @ (posedge CLK)
  begin
    stb_50 <= (cnt50_done && stb_1k);
    stb_5  <= ( (cnt5_done) & (stb_50) );
    stb_1  <= ( (cnt1_done) & (stb_50) );
  end
 
endmodule
