// 0.1, 0.2, and 1s strobe generator
// input: Clk (50 MHz max)
// Output: 1-period strobes (10, 5, and 1 Hz)
// Author: Dim Su
// Date: 201707xx
// Updated: 20171013

// this prevents the RTL simulation to start (ModelSim requires explicit net declaration):
//`default_nettype none

module strobe_gen_1k_50_5_1
#(
 parameter INPUT_FREQUENCY_KHZ = 10000
)
(
input 	CLK,
output 	STB_1K, STB_50,	STB_5, STB_1
);

reg [4:0] cnt50;
reg [3:0] cnt5;
reg [6:0] cnt1;

reg [15:0] prescaler;
reg stb_1k;
reg stb_50, stb_5, stb_1;
wire cnt50_done = (cnt50 == 19);
wire cnt5_done  = (cnt5  == 9);
wire cnt1_done  = (cnt1  == 49);

assign STB_1K = stb_1k,
       STB_50 = stb_50,
       STB_5  = stb_5,
       STB_1  = stb_1;

// we must perform initial reset, for the correct RTL simulaion
initial
 begin
  cnt50 = 0; cnt5 = 0; cnt1 = 0;
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
    prescaler--;
   end 
 
always @ (posedge CLK)
 if (stb_1k)
 begin
  if(cnt50_done)  cnt50 <= 0;
   else           cnt50 <= cnt50 + 1;
	
  stb_50 <= (cnt50_done);
  stb_5  <= ( (cnt5_done) & (stb_50) );
  stb_1  <= ( (cnt1_done) & (stb_50) );
 end

always @ (posedge CLK)
 if(stb_50)
  begin
   if(cnt5_done)  cnt5 <= 0;
    else          cnt5 <= cnt5 + 1;
    
   if(cnt1_done)  cnt1 <= 0;
    else          cnt1 <= cnt1 + 1;
  end

 
 
endmodule
