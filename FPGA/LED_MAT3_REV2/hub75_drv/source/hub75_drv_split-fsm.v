//=======================================================
//  Name:    driver for a chinese -_- LED-64x64 panel
//  Version: v1.0
//  Date:    20170829
//  Author:  Dim Su
//=======================================================

// prevent creating the implicit nets:
// ( note that this prevents the RTL simulation to start (ModelSim requires explicitly net declaration) )
// # ** Error: D:/PROJECTS/LED_MATRIX/Design/P2_LED_DRV/hub75_drv/source/hub75_drv.v(30): (vlog-2892) Net type of 'MEM_DATA' must be explicitly declared.

//`default_nettype none


module hub75_drv #( 
 parameter PIXEL_DEPTH = 3, 
 parameter PANELS_NUM = 2,
 parameter PANEL_WIDTH  = 8, 
 parameter MULTIPLEX_RATIO = 4,
 parameter MEM_DATA_WIDTH = 18,
 parameter MEM_ADDR_WIDTH = 4,
 parameter PWM_QUANTUM = 3
)

(
 input CLK,
 input RESET,
 
 input  CLK_PWM,
 
 input  [MEM_DATA_WIDTH-1:0] MEM_DATA,
 
 output [MEM_ADDR_WIDTH-1:0] MEM_ADDR,
 output MEM_RD,
 
 output [1:0] HUB_R,
 output [1:0] HUB_G,
 output [1:0] HUB_B,
 output [4:0] HUB_ADDR,
 output HUB_LATCH,
 output HUB_OE,
 output HUB_SCLK,
 
 // for debug/simulation purposes:
 output [2:0] FSM,
 output [PIXEL_DEPTH-1:0] PWM_BIT_CNT,
 output [7:0]             PWM_WAIT_CNT,
 output [3:0]             PWM_QUANTUM_CNT
 

);

//Derived parameters
 parameter PIXEL_DEPTH_MSB = 1 >> (PIXEL_DEPTH-1); 


//=======================================================
//  REG/WIRE declarations
//=======================================================
 reg [MEM_ADDR_WIDTH-1:0] mem_addr;
 reg [MEM_ADDR_WIDTH-1:0] base_addr;
 reg [MEM_ADDR_WIDTH-1:0] column_addr;
 
 reg [PIXEL_DEPTH-1:0] pwm_bit_counter;
 reg [3:0]             pwm_quantum_counter;
 reg [7:0]             pwm_wait_counter;

 reg [3:0]             row_number;
 
 reg                   sclk_ena;

 reg [2:0] fsm_pwm;
 parameter FSM_PWM_IDLE          = 0,
           FSM_PWM_START_ROW     = 1,
           FSM_PWM_READ_ROW      = 2,
           FSM_PWM_LATCH         = 3,
           FSM_PWM_DUTY_ON       = 4,
           FSM_PWM_NEXT_BIT      = 5,
           FSM_PWM_INC_NEXT_ROW  = 6,
			  FSM_PWM_LAST_ROW_DONE = 7;
 
 wire reset_mem_addr = RESET;
 wire stop_fsm       = RESET;

 wire clk_rd_outbuf = CLK;

 reg [1:0] r, g, b;
 reg [4:0] row_addr;
 reg sclk;
 reg latch;
 reg oe;

 
//=======================================================
//  PINS breaking out
//=======================================================   
assign MEM_ADDR = mem_addr;
assign MEM_RD   = 1'b1;

assign HUB_SCLK = sclk;
assign HUB_R = r, HUB_G = g, HUB_B = b;
assign HUB_LATCH = latch;
assign HUB_OE = oe;

assign row_addr = {1'b0, row_number};
assign HUB_ADDR = row_addr;

assign FSM = fsm_pwm,
       PWM_BIT_CNT = pwm_bit_counter,
       PWM_WAIT_CNT = pwm_wait_counter,
		 PWM_QUANTUM_CNT = pwm_quantum_counter;

//=======================================================
//  Structural coding
//=======================================================

// we must perform initial reset, for the correct RTL simulaion
initial
 begin

 end	

// sclk signal
always @*
  sclk <= sclk_ena ? ~clk_rd_outbuf : 1'b0;

// the complete memory address comprises of base address (1st pixel in the line) and column address
always @ (posedge CLK)
  mem_addr <= base_addr + column_addr;

// FSM change conditions
wire pwm_wait_done      = ( pwm_wait_counter == (1 >> pwm_bit_counter) );
wire pwm_last_bit       = ( pwm_bit_counter == PIXEL_DEPTH - 1 );
wire column_last_addr   = ( column_addr == PANELS_NUM*PANEL_WIDTH - 1 );
wire row_last_number    = ( row_number  == MULTIPLEX_RATIO - 1 );

/******************************************************************************/ 
// main driver state machine
always @ (posedge clk_rd_outbuf or posedge stop_fsm)
begin
 if (stop_fsm)       fsm_pwm <= FSM_PWM_IDLE;
  else
   case (fsm_pwm)
	
//------------------------------------------------------------------------------
// 0.
//------------------------------------------------------------------------------
	 FSM_PWM_IDLE:    fsm_pwm <= FSM_PWM_START_ROW;
	 
//------------------------------------------------------------------------------
// 1. Read and shift row out
//------------------------------------------------------------------------------
	 FSM_PWM_START_ROW:
	                  fsm_pwm <= FSM_PWM_READ_ROW;
//------------------------------------------------------------------------------
// 2. the whole row (line) read out completely, go to put LATCH out
//------------------------------------------------------------------------------
	 FSM_PWM_READ_ROW: 
	  if (column_last_addr)
	                  fsm_pwm <= FSM_PWM_LATCH;
							
//------------------------------------------------------------------------------
// 3.
//------------------------------------------------------------------------------
	 FSM_PWM_LATCH:   fsm_pwm <= FSM_PWM_DUTY_ON;
	 
//------------------------------------------------------------------------------
// 4. waiting for the [PWM_QUANTUMx(1 >> pwm_bit_counter)] time
//------------------------------------------------------------------------------
	 FSM_PWM_DUTY_ON:
     if (pwm_wait_done)
                     fsm_pwm <= FSM_PWM_NEXT_BIT;
	 
//------------------------------------------------------------------------------
// 5. a next GS bit will be processed
//------------------------------------------------------------------------------
    FSM_PWM_NEXT_BIT:
	  if (pwm_last_bit)
	                  fsm_pwm <= FSM_PWM_INC_NEXT_ROW;
		else           fsm_pwm <= FSM_PWM_READ_ROW;
	 
//------------------------------------------------------------------------------
// 6. a next row bit will be processed
//------------------------------------------------------------------------------
    FSM_PWM_INC_NEXT_ROW:	 
	  if (row_last_number)
	                  fsm_pwm <= FSM_PWM_LAST_ROW_DONE;

//------------------------------------------------------------------------------
// 7.
//------------------------------------------------------------------------------
    FSM_PWM_LAST_ROW_DONE:
	                  fsm_pwm <= FSM_PWM_IDLE;
	 
//------------------------------------------------------------------------------
	 default:         fsm_pwm <= FSM_PWM_IDLE;
	 
   endcase

end

always @ (posedge clk_rd_outbuf)
begin

   case (fsm_pwm)

//------------------------------------------------------------------------------
// reset state before reading out a whole display memory
//------------------------------------------------------------------------------
	 FSM_PWM_IDLE:
	  begin
	   latch       <= 0;
		oe          <= 0;
	   sclk_ena    <= 0;
		row_number  <= 0;
		base_addr   <= 0;
	  end
 
//------------------------------------------------------------------------------
// 1. reset the column address
//------------------------------------------------------------------------------
	 FSM_PWM_START_ROW:
	  begin
		column_addr         <= 0;
		pwm_bit_counter     <= 0;
      pwm_quantum_counter <= 0;
      pwm_wait_counter    <= 0;
	  end

//------------------------------------------------------------------------------
// 2. reading and clocking out a complete line. The mem_addr is incrementing at each CLK
//------------------------------------------------------------------------------
	 FSM_PWM_READ_ROW:
	  begin
		sclk_ena  <= 1;           // SCLK (inverted clk_rd_buf at the output) enable
		oe        <= 0;           // OE is disable while shifting data
	   tsk_rgb_bits_fetch();     // fetching the R/G/B bits
		column_addr++;            // increment the column address
	  end

//------------------------------------------------------------------------------
// 3. stopping the line readout, and forming the LATCH signal
//------------------------------------------------------------------------------
    FSM_PWM_LATCH:
	  begin
		sclk_ena  <= 0;
	   latch     <= 1;
	  end

//------------------------------------------------------------------------------
// 4. set OE signal and waiting [PWM_QUANTUMx(1 >> pwm_bit_counter)] time
//------------------------------------------------------------------------------
	 FSM_PWM_DUTY_ON:
	  begin
	   latch     <= 0;
	   oe        <= 1;
	   tsk_pwm_wait();
	  end
	  
//------------------------------------------------------------------------------
// 5. increment the bit_counter for the next PWM step
//------------------------------------------------------------------------------
	 FSM_PWM_NEXT_BIT:
	  begin
	   pwm_bit_counter++;
	   oe          <= 0;
	   column_addr <= 0;
	  end

//------------------------------------------------------------------------------
// 6. next row
//------------------------------------------------------------------------------
	 FSM_PWM_INC_NEXT_ROW:
	  begin
		base_addr <= base_addr + (PANEL_WIDTH*PANELS_NUM);
		pwm_bit_counter <= 0;
		row_number++;
	  end

//------------------------------------------------------------------------------
// 7. Last row has been processed
//------------------------------------------------------------------------------
	 FSM_PWM_LAST_ROW_DONE:
	  begin
		
	  end

//------------------------------------------------------------------------------
// nothing to do here...
//------------------------------------------------------------------------------
	 default:
	  begin
	  
	  end

	 
   endcase


end
/******************************************************************************/ 

//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
task tsk_pwm_wait_counters_reset;
      pwm_quantum_counter <= 0;
		pwm_wait_counter    <= 0;
endtask

//------------------------------------------------------------------------------
task tsk_pwm_wait;
 begin
 
  if (fsm_pwm != FSM_PWM_DUTY_ON)
    tsk_pwm_wait_counters_reset(); // reset PWM wait (duty on) out of PWM duty ON stage
    else

	  begin
  		  if (pwm_quantum_counter == PWM_QUANTUM)
		   begin
		           pwm_quantum_counter <= 0;
					  pwm_wait_counter++;
		   end
		    else   pwm_quantum_counter++;
		end
		
 end  
endtask


//------------------------------------------------------------------------------
task tsk_rgb_bits_fetch;
	   r[0] <= MEM_DATA[MEM_DATA_WIDTH - (1 + pwm_bit_counter)];
	   g[0] <= MEM_DATA[MEM_DATA_WIDTH - (1 + PIXEL_DEPTH + pwm_bit_counter)];
	   b[0] <= MEM_DATA[MEM_DATA_WIDTH - (1 + PIXEL_DEPTH + PIXEL_DEPTH + pwm_bit_counter)];
	   r[1] <= MEM_DATA[MEM_DATA_WIDTH/2 - (1 + pwm_bit_counter)];
	   g[1] <= MEM_DATA[MEM_DATA_WIDTH/2 - (1 + PIXEL_DEPTH + pwm_bit_counter)];
	   b[1] <= MEM_DATA[MEM_DATA_WIDTH/2 - (1 + PIXEL_DEPTH + PIXEL_DEPTH + pwm_bit_counter)];
endtask


endmodule
