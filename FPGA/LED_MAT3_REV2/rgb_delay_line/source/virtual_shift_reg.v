// virtual delay line for connecting the LED panels that have no cascading ports
// Author: Dim Su

module virtual_shift_reg
#(
  parameter DELAY_LENGTH = 128
  )
(
 input        CLK,
 input        CLK_ENA,
 input  [2:0] IN_DATA_R,
 input  [2:0] IN_DATA_G,
 input  [2:0] IN_DATA_B,
 output reg [2:0] OUT_DATA_R,
 output reg [2:0] OUT_DATA_G,
 output reg [2:0] OUT_DATA_B
);


reg [DELAY_LENGTH-1:0] delay_line_r [2:0];
reg [DELAY_LENGTH-1:0] delay_line_g [2:0];
reg [DELAY_LENGTH-1:0] delay_line_b [2:0];

//! R
always @(posedge CLK)
 if(CLK_ENA)
  begin
    delay_line_r[0] <= { delay_line_r[0][DELAY_LENGTH-2:0], IN_DATA_R[0] };
    delay_line_r[1] <= { delay_line_r[1][DELAY_LENGTH-2:0], IN_DATA_R[1] };
    delay_line_r[2] <= { delay_line_r[2][DELAY_LENGTH-2:0], IN_DATA_R[2] };
  end

always @(negedge CLK)
 if(CLK_ENA)
  begin
       OUT_DATA_R[0] <= delay_line_r[0][DELAY_LENGTH-1];
       OUT_DATA_R[1] <= delay_line_r[1][DELAY_LENGTH-1];
       OUT_DATA_R[2] <= delay_line_r[2][DELAY_LENGTH-1];
  end
  
//! G
always @(posedge CLK)
 if(CLK_ENA)
  begin
    delay_line_g[0] <= { delay_line_g[0][DELAY_LENGTH-2:0], IN_DATA_G[0] };
    delay_line_g[1] <= { delay_line_g[1][DELAY_LENGTH-2:0], IN_DATA_G[1] };
    delay_line_g[2] <= { delay_line_g[2][DELAY_LENGTH-2:0], IN_DATA_G[2] };
  end

always @(negedge CLK)
 if(CLK_ENA)
  begin
       OUT_DATA_G[0] <= delay_line_g[0][DELAY_LENGTH-1];
       OUT_DATA_G[1] <= delay_line_g[1][DELAY_LENGTH-1];
       OUT_DATA_G[2] <= delay_line_g[2][DELAY_LENGTH-1];
  end
 
//! B 
always @(posedge CLK)
 if(CLK_ENA)
  begin
    delay_line_b[0] <= { delay_line_b[0][DELAY_LENGTH-2:0], IN_DATA_B[0] };
    delay_line_b[1] <= { delay_line_b[1][DELAY_LENGTH-2:0], IN_DATA_B[1] };
    delay_line_b[2] <= { delay_line_b[2][DELAY_LENGTH-2:0], IN_DATA_B[2] };
  end

always @(negedge CLK)
 if(CLK_ENA)
  begin
       OUT_DATA_B[0] <= delay_line_b[0][DELAY_LENGTH-1];
       OUT_DATA_B[1] <= delay_line_b[1][DELAY_LENGTH-1];
       OUT_DATA_B[2] <= delay_line_b[2][DELAY_LENGTH-1];
  end
  
/*		 
assign OUT_DATA_B[0] = delay_line_b[0][DELAY_LENGTH-1],
       OUT_DATA_B[1] = delay_line_b[1][DELAY_LENGTH-1],
       OUT_DATA_B[2] = delay_line_b[2][DELAY_LENGTH-1];
*/  
  
endmodule
