//=======================================================
//  Purpose:    driver for a Chinese -_- LED-64x64 panel based on MBI5124 driver IC
//  Version: v1.1
//  Date:    20170829, initial ver.
//  Author:  Dim Su
//  History Release: 
//  20170831 - simulation done
//  20170926 - mem addr correction added
//  20170928 - PWM_QUANTUM replaced by PWM_Q, PWM_STEP parametrizied
//  20170930 - R/G/B positions have been corrected
//  20171005 - panels num scaling added
//  20171017 - input bus 'SCAN_RATIO' added 
//  20171018 - inversion for SCLK has made 
//  20171019 - + 1 fsm state to make a gap between LATCH and OE
//  20171111 - free LATCH positioning and width options added (parameters LATCH_START_POS and LATCH_END_POS)
//             For example, for ICN2038S the LATCH signal is 3 SCLK-width and is active during last 3 clocks,
//             so we set the parameters as '-3' and '0';
//             For MBI5124 the LATCH must be active any time >50 ns after last SCLK clock. Thus, we set 
//             the parameters to '0' and '1' (or '0' and '2" - wider pulse)
//  20171220 - switching between ICN2038 and MBI5124 (_POS_V1 and _POS_V2) added
//
//  The module works as following:
//  1. Set the memory address to 0. Reset the in-color bit counter for PWM.
//  2. Shift actual 'PWM' bit (0, then 1, ...up to PIXEL_DEPTH-1) of each pixel’s red, green, and blue values for row 0 (1, 2, ..) into the column drivers.
//  3. Latch the contents of the column drivers‘ shift registers into the column drivers‘ output registers using the LATCH signal.
//  4. Set OE signal to enable display.
//     Wait some amount of time, [ PWM_QUANTUM * (1'b1 << actual_pwm_bit_number) ].
//  5. Reset OE (turn-off display), reset column address, increment "pwm_bit_counter", which points to the next PWM bit.
//     If all the bits have gone through PWM process, then increment the row number. Goto #2.
//=======================================================

// to prevent creating the implicit nets:
`default_nettype none


module hub75_drv #( 
// these default parameters are set for simulation only
// the real values must be set extarnally by defparam directive
 parameter PIXEL_DEPTH = 3, 
 parameter PANEL_WIDTH  = 8, // for simulation only; for instatiating the module use the IMG_WIDTH input BUS
 parameter SCAN_RATIO_PRM = 4,
 parameter MEM_DATA_WIDTH = PIXEL_DEPTH*3,                            // R, G, B
 parameter MEM_ADDR_WIDTH = $clog2(2 * PANEL_WIDTH * SCAN_RATIO_PRM), // 2 = number of panels for simulation
 parameter MAX_IMG_WIDTH_LOG2 = 9,
 parameter LATCH_START_POS_V1 = -3,
 parameter LATCH_END_POS_V1 = 0,
 parameter LATCH_START_POS_V2 = 0,
 parameter LATCH_END_POS_V2 = 1
)
(
 input CLK,
 input RESET,
 
 input  [3:0] PWM_Q,         // minimum PWM quantum (LED's lighting period) power [0 = 1, 1 = 2, 2 = 4, 3 = 8, 4 = 16, ...]
 input  [MAX_IMG_WIDTH_LOG2-1:0] IMG_WIDTH,
 input  [5:0] SCAN_RATIO,    // up to 1/32 scan ratio
 //input signed [2:0] LATCH_START_POS,
 //input signed [2:0] LATCH_END_POS,
 input LATCH_POS_VER,         // switch between different LATCH pos. variants
 
 input  [MEM_DATA_WIDTH-1:0] MEM0_DATA, MEM1_DATA,
 
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
 output [3:0] FSM,
 output [PIXEL_DEPTH-1:0] PWM_BIT_NUM,
 output [PIXEL_DEPTH-1:0] PWM_WAIT_CNT,
 output [3:0]             PWM_QUANTUM_CNT,
 output [PIXEL_DEPTH-1:0] PWM_STEP
);

localparam OUT_SIG_DELAY = 3;  // for aligning data and strobes

//------------------------------------------------------------------------------
//  REG/WIRE declarations
//------------------------------------------------------------------------------
 reg [MEM_ADDR_WIDTH-1:0]     mem_addr;
 reg [MEM_ADDR_WIDTH-1:0]     base_addr;
 reg [MAX_IMG_WIDTH_LOG2:0]   column_addr;                                           // 'long' column_addr bus, for the free LATCH positioning
 wire[MAX_IMG_WIDTH_LOG2-1:0] column_addr_mem = column_addr[MAX_IMG_WIDTH_LOG2-1:0]; // 'short' column_addr bus, for memory addressing
 reg                          column_addr_cnt_ena;
 wire[MAX_IMG_WIDTH_LOG2-1:0] row_length;
 //wire signed [MAX_IMG_WIDTH_LOG2:0] row_length_s;
 
 reg [3:0]             pwm_bit_number;     // max 16 PWM quantum levels
 reg [3:0]             pwm_quantum_counter;
 reg [PIXEL_DEPTH-1:0] pwm_wait_counter;
 wire[PIXEL_DEPTH-1:0] pwm_step;
 
 reg                   sclk_ena;          // this signal enables SPICLK whish is derived of main module clock

 reg [3:0] fsm_pwm;
 localparam FSM_PWM_IDLE                 = 0,
            FSM_PWM_START_ROW_FULL_COLOR = 1,
            FSM_PWM_READ_ROW_BIT         = 2,
            FSM_PWM_READ_ROW_BIT_DONE    = 3,
            FSM_PWM_LATCH_DONE           = 4,
            FSM_PWM_DUTY_ON              = 5,
            FSM_PWM_NEXT_BIT             = 6,
            FSM_PWM_INC_NEXT_ROW         = 7;

 
 wire stop_fsm      = RESET;

 reg [4:0] row_number; // row number which is scanned at the moment
 reg [1:0] r, g, b;
 reg sclk, latch, oe;
 
 reg [3:0] latch_delayed, oe_delayed;
 reg [4:0] row_number_delayed [3:0];

 
//------------------------------------------------------------------------------
//  PINS breaking out
//------------------------------------------------------------------------------
assign MEM_ADDR = mem_addr;
assign MEM_RD   = 1'b1;

assign HUB_SCLK = sclk;
assign HUB_R = r, HUB_G = g, HUB_B = b;
assign HUB_LATCH = latch_delayed[OUT_SIG_DELAY];
//assign HUB_LATCH = latch_delayed[OUT_SIG_DELAY] ? CLK : 1'b0; // debug 2 latch (did not help for ICN2038)

assign HUB_OE    = oe_delayed[OUT_SIG_DELAY];
//assign HUB_OE    = oe_delayed[OUT_SIG_DELAY] ? CLK : 1'b0; // debug 2+ OE  (did not help for ICN2038)
assign HUB_ADDR = row_number_delayed[OUT_SIG_DELAY];

//assign FSM = fsm_pwm; // debug output

assign PWM_BIT_NUM = pwm_bit_number,
       PWM_WAIT_CNT = pwm_wait_counter,
		   PWM_QUANTUM_CNT = pwm_quantum_counter,
		   PWM_STEP = pwm_step; 

//------------------------------------------------------------------------------
//  Structural coding
//------------------------------------------------------------------------------

// we must perform initial reset, for the correct RTL simulaion ..tbd
initial
 begin
   latch_delayed <= 0; oe_delayed <= 0;
 end	

// calculate the actual length of the row:
//always @(posedge CLK)
assign row_length = IMG_WIDTH; 
//assign row_length_s = $signed(IMG_WIDTH);
 
// current PWM duty time
// this vector shows the number of "PWM_QUANTUM" time-slots that are actual in the moment
wire [15:0] pwm_step_max_width;
assign  pwm_step_max_width = (16'b0000_0000_0000_0001 << pwm_bit_number);
assign  pwm_step = pwm_step_max_width[PIXEL_DEPTH-1:0];
 
//------------------------------------------------------------------------------
// SCLK ena signal

reg [3:0] sclk_ena_dly;
always @ (posedge CLK)
  sclk_ena_dly <= {sclk_ena_dly[2:0], sclk_ena};
  
// delay the SCLK signal by 2 clocks to make it synchronous with the memory data
always @*
  //sclk <= sclk_ena_dly[OUT_SIG_DELAY] ? CLK : 1'b0; 
  sclk <= sclk_ena_dly[OUT_SIG_DELAY] ? ~CLK : 1'b0; // 20171018, inversion made because 1st column (most left) had some jitter effects
  //sclk <= (sclk_ena_dly[OUT_SIG_DELAY] /*|| oe_delayed[OUT_SIG_DELAY]*/) ? ~CLK : 1'b0; // debug 20170910
  //sclk <= sclk_ena_dly[OUT_SIG_DELAY] ? ~CLK : 1'b0;  // -commented 20170929- (inv and non-inv clk work same)

//------------------------------------------------------------------------------
// delay the LATCH and OE signals
always @ (posedge CLK)
 begin
  latch_delayed <= { latch_delayed[2:0], latch};
  oe_delayed    <= { oe_delayed[2:0],    oe };
 end

// delay ADDR bus
always @ (posedge CLK)
 begin
  row_number_delayed[3] <= row_number_delayed[2];
  row_number_delayed[2] <= row_number_delayed[1];
  row_number_delayed[1] <= row_number_delayed[0];
  row_number_delayed[0] <= row_number;
 end
  
//------------------------------------------------------------------------------
// column address counter
always @(posedge CLK or posedge RESET)
  if (RESET)                    column_addr <= 0;
  else
   if (column_addr_cnt_ena)     column_addr++;
     else                       column_addr <= 0;

//------------------------------------------------------------------------------
// adjustable LATCH signal
reg column_latch_start_pos, column_latch_end_pos;
//assign latch_start_pos = $unsigned( row_length_s + LATCH_START_POS );
//assign latch_end_pos   = $unsigned( row_length_s + LATCH_END_POS );
always @*
  if (LATCH_POS_VER)
   begin                      // latch position v1
	  column_latch_start_pos <= (column_addr == row_length + LATCH_START_POS_V1);
	  column_latch_end_pos   <= (column_addr == row_length + LATCH_END_POS_V1);
	end
	else                      // latch position for v2
	  begin
  	    column_latch_start_pos <= (column_addr == row_length + LATCH_START_POS_V2);
	    column_latch_end_pos   <= (column_addr == row_length + LATCH_END_POS_V2);
	  end

always @(posedge CLK or posedge RESET)
 if (RESET)                         latch <= 1'b0;
  else
   begin
     if (column_latch_start_pos)    latch <= 1'b1;
     else if (column_latch_end_pos) latch <= 1'b0;
   end

//------------------------------------------------------------------------------
// the complete memory address comprises of base address (1st pixel in the line) and column address
always @ (posedge CLK)
  mem_addr <= base_addr + column_addr_mem;
//  mem_addr <= base_addr + { {MEM_ADDR_WIDTH_M_COLUMN_ADDR_WIDTH{1'b0}}, column_addr };

// FSM's states change conditions
wire pwm_wait_done      = ( pwm_wait_counter == pwm_step );
wire pwm_last_bit       = ( pwm_bit_number == PIXEL_DEPTH - 1 );
wire column_last_addr   = ( column_addr == row_length - 1 );
wire latch_last_addr    = ( column_addr >= row_length + LATCH_END_POS_V2 ); // LATCH_END_POS_V2 > LATCH_END_POS_V1 //tbd >= -> ==
wire row_last_number    = ( row_number  == SCAN_RATIO - 1 );
//reg  row_last_number;
//always @(posedge CLK) row_last_number <= ( row_number  == SCAN_RATIO - 2 ); // subtract 2 due to the additional register delay

/******************************************************************************/ 
// main driver state machine

always @ (posedge CLK or posedge stop_fsm)
begin
 if (stop_fsm)       fsm_pwm <= FSM_PWM_IDLE;
  else
   case (fsm_pwm)

//------------------------------------------------------------------------------
// reset state before reading out a whole display memory
//------------------------------------------------------------------------------
	 FSM_PWM_IDLE:
	  begin
		oe          <= 0;
	  sclk_ena    <= 0;
		row_number  <= 0;
		base_addr   <= 0;
    column_addr_cnt_ena <= 0;
		
		                fsm_pwm <= FSM_PWM_START_ROW_FULL_COLOR;
	  end
 
//------------------------------------------------------------------------------
// 1. reset the column address
//------------------------------------------------------------------------------
	 FSM_PWM_START_ROW_FULL_COLOR:
	  begin
		pwm_bit_number      <= 0;
    pwm_quantum_counter <= 0;
    pwm_wait_counter    <= 0;
    
		                fsm_pwm <= FSM_PWM_READ_ROW_BIT;
	  end

//------------------------------------------------------------------------------
// 2. reading and clocking out a complete line. The mem_addr is incrementing at each CLK
//------------------------------------------------------------------------------
	 FSM_PWM_READ_ROW_BIT:
	  begin
		sclk_ena  <= 1;           // enable SCLK (inverted CLK at the output)
		oe        <= 0;           // OE is disable while shifting data (tbd)
    column_addr_cnt_ena <= 1; // increment the column address
    
		if (column_last_addr)
	                  fsm_pwm <= FSM_PWM_READ_ROW_BIT_DONE;
	  end

//------------------------------------------------------------------------------
// 3. stop the line readout but continue incrementing the column address while need to keep LATCH signal out
//------------------------------------------------------------------------------
    FSM_PWM_READ_ROW_BIT_DONE:
	  begin
		sclk_ena            <= 0;
    
		if (latch_last_addr)
		                fsm_pwm <= FSM_PWM_LATCH_DONE;
	  end

//------------------------------------------------------------------------------
// 4. put the LATCH signal out
//------------------------------------------------------------------------------
    FSM_PWM_LATCH_DONE:
	  begin
    column_addr_cnt_ena <= 0;

		tsk_pwm_wait_counters_reset(); // reset PWM wait (duty on) before PWM duty ON stage
		
		                fsm_pwm <= FSM_PWM_DUTY_ON;
	  end

//------------------------------------------------------------------------------
// 5. set OE signal and waiting [PWM_QUANTUMx(1 >> pwm_bit_number)] time
//------------------------------------------------------------------------------
	 FSM_PWM_DUTY_ON:
	  begin
	   oe        <= 1;
	   tsk_pwm_wait();   
		
		if (pwm_wait_done)
                    fsm_pwm <= FSM_PWM_NEXT_BIT;
	  end
	  
//------------------------------------------------------------------------------
// 6. increment the bit_counter for the next PWM step
//------------------------------------------------------------------------------
	 FSM_PWM_NEXT_BIT:
	  begin
	   pwm_bit_number++;
	   oe          <= 0;
		
		if (pwm_last_bit)
	                  fsm_pwm <= FSM_PWM_INC_NEXT_ROW;
		 else           fsm_pwm <= FSM_PWM_READ_ROW_BIT;
	  end

//------------------------------------------------------------------------------
// 7. switch to a next row
//------------------------------------------------------------------------------
	 FSM_PWM_INC_NEXT_ROW:
	  begin
		base_addr <= base_addr + row_length;
		pwm_bit_number <= 0;
		row_number++;
		
		if (row_last_number)
	                  fsm_pwm <= FSM_PWM_IDLE;
		 else           fsm_pwm <= FSM_PWM_START_ROW_FULL_COLOR;
	  end

//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// nothing to do here...
//------------------------------------------------------------------------------
	 default:
	  begin
	   fsm_pwm <= FSM_PWM_IDLE;
	  end

	 
   endcase

end
/******************************************************************************/ 


//------------------------------------------------------------------------------
task tsk_pwm_wait_counters_reset;
      pwm_quantum_counter <= 0;
		  pwm_wait_counter    <= 0;
endtask

//------------------------------------------------------------------------------
// increment 'pwm_quantum_counter' at the each 'PWM_QUANTUM' step
// ..PWM_QUANTUM (PWM_Q) must be set externally
task tsk_pwm_wait;
 begin
//		  if (pwm_quantum_counter == PWM_QUANTUM - 1)
  		  if (pwm_quantum_counter == PWM_Q - 1)
		   begin
		          pwm_quantum_counter <= 0;
					    pwm_wait_counter++;
		   end
		    else  pwm_quantum_counter++;
		
 end  
endtask


//------------------------------------------------------------------------------
// get the actual r/g/b bits from the memory word (we put the r/g/b words out bit by bit)
parameter BIT_R0 = MEM_DATA_WIDTH   -   PIXEL_DEPTH;
parameter BIT_G0 = MEM_DATA_WIDTH   - 2*PIXEL_DEPTH;
parameter BIT_B0 = MEM_DATA_WIDTH   - 3*PIXEL_DEPTH;

always @ (posedge CLK)
 begin
	   r[0] <= MEM0_DATA[BIT_R0 + pwm_bit_number];
	   g[0] <= MEM0_DATA[BIT_G0 + pwm_bit_number];
	   b[0] <= MEM0_DATA[BIT_B0 + pwm_bit_number];
		
	   r[1] <= MEM1_DATA[BIT_R0 + pwm_bit_number];
	   g[1] <= MEM1_DATA[BIT_G0 + pwm_bit_number];
	   b[1] <= MEM1_DATA[BIT_B0 + pwm_bit_number];
 end


initial
 begin
    $display("**********************************************************************");
	 $display("******* R Pos Bit[0] = %d *******", BIT_R0);
	 $display("******* G Pos Bit[0] = %d *******", BIT_G0);
	 $display("******* B Pos Bit[0] = %d *******", BIT_B0);
    $display("**********************************************************************");
 end


endmodule
