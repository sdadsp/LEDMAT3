//=======================================================
//  PWM 
//  Author: Dim Su, the open sources were used
//  v1.1
//  20171018
//=======================================================

module pwm_8bit (CLK, RESET, STB_CLK, DC, Q);
input CLK;
input RESET;
input STB_CLK;
input [7:0] DC;  // Duty Cycle input
output Q;

reg [8:0] acc;      // accumulator has one more bit than the duty cycle
assign Q = acc[8];  // output is the 8th bit

initial acc = 0;

always @(posedge CLK or posedge RESET)
begin
  if (RESET) acc <= 0;
   else
    if(STB_CLK)
             acc <= acc[7:0] + DC;
end

endmodule


module pwm_var_width
#( parameter DC_WIDTH = 4 )
(
input CLK,
input RESET,
input STB_CLK,
input [DC_WIDTH-1:0] DC,  // Duty Cycle input
output Q
);

reg [DC_WIDTH-1:0] pwm_counter = 0;
reg pwm_out;

assign Q = pwm_out;


always @(posedge CLK or posedge RESET)
begin
  if (RESET) pwm_counter <= 0;
   else
    if(STB_CLK)
             pwm_counter++;
end

always @(posedge CLK)
  pwm_out <= (pwm_counter <= DC);


endmodule
