//******************************************************************************
// MBI5153 frame sending
// the module sends the data to the drivers's SRAM
// one request sends 1 frame:
// 1) base address <- 1st pixel (LSP) of the 1st line;
// 2) generate request to send the Line
//    externally:
//     RAM address = base address + offset (gotten from channel-send module, 'mbi5153_data')
// 3) increase the base address by 1 line
// 4) repeat (2, 3) until last line
// 5) geterate end of scan (FRAME_TX_DONE) strobe
// input wires:
// output wire: 
//
// Author:  Dim Su
// Initial date: 20171108
// Release History:
// 20171219 - ready for simulation
// 20171220 - 1st simulation run performed
// 20180301 - NUM_CH_IC*NUM_IC_CHAIN replaced with IMG_WIDTH
// 20180505 - IMG_WIDTH parameter replaced with bus that connected to image_width register on the top level
//******************************************************************************

// synopsys translate_off
`timescale 1 ns / 10 ps
// synopsys translate_on

`default_nettype none

// define the propagation delay (for simulation)
`define PD 0

module mbi5153_frame
#(
 parameter EXT_RAM_BASE_ADDR = 0,
// parameter NUM_CH_IC = 16,
// parameter NUM_IC_CHAIN = 4,
// parameter ADDR_WIDTH   = $clog2(NUM_IC_CHAIN*NUM_CH_IC*32), // 32 is a MAX Scan Ratio
 parameter IMG_WIDTH_MAX = 64,
 parameter IMG_WIDTH_MAX_LOG2 = $clog2(IMG_WIDTH_MAX + 1),
 parameter ADDR_WIDTH   = $clog2(IMG_WIDTH_MAX*32) // 32 is a MAX Scan Ratio
)
(
 input wire CLK,              // main clock, also will be used as the DCLK
 input wire RESET,
 input wire REQUEST,          // request to send a frame
 input wire [4:0] SCAN_RATIO, // scan ratio (number of the lines)
 input wire LINE_READY,       // Line Transmitter (mbi5153_data) is ready
 input wire LINE_TX_DONE,
 input wire [IMG_WIDTH_MAX_LOG2-1:0] IMG_WIDTH,
 
 output wire READY,           // the REQUEST may be applied when this signal is active
 output wire ACTIVE,          // shows that the cmd execution is running
 output wire FRAME_TX_DONE,   // this strobe shows that the frame is comletely sent
 
 output wire REQUEST_TO_SEND_LINE,
 
 output wire [ADDR_WIDTH-1:0] ADDR // current base address of the external memory -
                                   // - has to be added with the offset (from channel's tx module)
);

//******************************************************************************
reg [3:0] ch_cnt;
reg [4:0] line_cnt;

reg line_tx_start, frame_tx_start, frame_tx_run, frame_tx_done;

reg [2:0] fsm_tx_fr, fsm_tx_fr_next_state;

reg [ADDR_WIDTH-1:0]     base_addr;

//******************************************************************************
// display the data below during compilation:
initial
 begin
   $display("********************* MBI5153 Frame Module ***************************");
   $display("******* Maximum Image width           %d *******", IMG_WIDTH_MAX);
   $display("******* Bus Width for -Image Width-   %d *******", IMG_WIDTH_MAX_LOG2);
   $display("******* Memory Address Bus Width      %d *******", ADDR_WIDTH);
   $display("**********************************************************************");
 end

//******************************************************************************
// FSM for transmitting 1 frame
 localparam FSM_TX_FR_IDLE      = 0,
            FSM_TX_FR_START     = 1,
            FSM_TX_FR_WAIT_LINE = 2,
            FSM_TX_FR_NEXT_LINE = 3,
            FSM_TX_FR_DONE      = 4;

//******************************************************************************
assign READY = (fsm_tx_fr == FSM_TX_FR_IDLE);
assign ACTIVE = frame_tx_run;

assign ADDR = base_addr;
assign REQUEST_TO_SEND_LINE = line_tx_start;
assign FRAME_TX_DONE = frame_tx_done;

//******************************************************************************
// RAM base address
wire load_base_addr = frame_tx_start;
reg  inc_base_addr;

always @(posedge CLK or posedge RESET)
begin
 if(RESET)         base_addr <= EXT_RAM_BASE_ADDR;
 else
  begin
    if (load_base_addr)
      begin
                   base_addr <= EXT_RAM_BASE_ADDR;
						 line_cnt  <= SCAN_RATIO;
	  end
	
    else
      if (inc_base_addr)
	    begin
	                base_addr <= base_addr + IMG_WIDTH; //256; //(NUM_CH_IC * NUM_IC_CHAIN); // jump to the next line
						 line_cnt  <= line_cnt - 1;
	    end
  end
end

//******************************************************************************

//------------------------------------------------------------------------------
// FSM_TX_FR registered block
always @(posedge CLK or posedge RESET)
 if (RESET)             #`PD fsm_tx_fr <= FSM_TX_FR_IDLE;
 else if (1)            #`PD fsm_tx_fr <= fsm_tx_fr_next_state;

//------------------------------------------------------------------------------
// TX_FRAME FSM combinational block 
//always @(fsm_tx_fr or REQUEST or LINE_READY or LINE_TX_DONE or line_cnt)
always @(posedge CLK or posedge RESET)
if (RESET)             #`PD fsm_tx_fr_next_state <= FSM_TX_FR_IDLE;
else
begin: fsm_tx_fr_fsm
// case (fsm_tx_fr)
 case (fsm_tx_fr_next_state)
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
   FSM_TX_FR_IDLE:
    begin
                  line_tx_start <= 0; frame_tx_run <= 0;  frame_tx_done  <= 0;
                  inc_base_addr <= 0;
     if (REQUEST) 
	   begin 
	              frame_tx_start <= 1; // set "frame start" flag
   	              fsm_tx_fr_next_state <= FSM_TX_FR_START;
	   end 
	    else      frame_tx_start <= 0;
    end
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
   FSM_TX_FR_START:
    begin
                  frame_tx_start <= 0;    // reset "frame start" flag
				  if (LINE_READY)
				    begin
				      frame_tx_run  <= 1; // Set "run" flag
					  line_tx_start <= 1; // Set the request to send line
                      fsm_tx_fr_next_state <= FSM_TX_FR_WAIT_LINE;
					end
    end
//- - - - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - -  
   FSM_TX_FR_WAIT_LINE:
    begin
                  line_tx_start <= 0; // reset the request to send line
				                     
				  if (LINE_TX_DONE)  // ..waiting for the end of sending the line
                    begin
                      inc_base_addr <= 1;
                      fsm_tx_fr_next_state <= FSM_TX_FR_NEXT_LINE;
                    end					
    end
//- - - - - - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - -  
   FSM_TX_FR_NEXT_LINE:
    begin
                  inc_base_addr <= 0;
				  
                  if (line_cnt != 0) // if it is not the last line in the frame...
				       fsm_tx_fr_next_state <= FSM_TX_FR_START;
				  else fsm_tx_fr_next_state <= FSM_TX_FR_DONE;
    end
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
   FSM_TX_FR_DONE:
    begin
                  frame_tx_run   <= 0;
                  frame_tx_done  <= 1; // "done" strobe
                  fsm_tx_fr_next_state <= FSM_TX_FR_IDLE;
    end
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
   default:
    begin
      line_tx_start <= 0; frame_tx_run <= 0;  frame_tx_done  <= 0;
      inc_base_addr <= 0;
      fsm_tx_fr_next_state <= FSM_TX_FR_IDLE;
    end
    
 endcase
end //fsm_tx_fr_fsm

endmodule



