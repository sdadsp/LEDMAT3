//******************************************************************************
// MBI5153 data sending
// The module sends the data to the drivers's SRAM
// Input: request signal
//  Note:one request sends 1 line !!!
// The module must be connected to the "1-line RAM" for fetching the pixels' data with a fixed delay (N CLKs)
// Output: RAM address (offset), HUB signals
//
// Author:  Dim Su
// Initial date: 20171123
//
// Release History:
// 20171218 - channel sending extended to the line sending; simulation done
// 20171220 - internal module structure is updated; simulation done
// 20180127 - inverted CLK for generating DCLK
// 20180130 - extended to 2 RGB lanes
// 20180505 - extended to 3 lanes
//******************************************************************************

// synopsys translate_off
`timescale 1 ns / 10 ps
// synopsys translate_on

`default_nettype none

// define the propagation delay (for simulation)
`define PD 0

module mbi5153_data
#(
 parameter NUM_IC_CHAIN = 4,    // number of the ICs in the chain
 parameter NUM_CH_IC  = 16,     // number of the channels (outputs) per one IC
 parameter IC_WORD_LENGTH = 16, //  Possible values: 8 (debug), 16 (real value)
 parameter NUMBER_OF_LANES = 3, //  max. 3 lanes per panel
 parameter ADDR_WIDTH   = $clog2(NUM_IC_CHAIN*NUM_CH_IC),
 parameter RGB_LSB = 8'h00      // this module uses 8-bits GS but 5153 IC suports 16-bits
)
(
 input wire CLK,                           // main clock, also will be used as the DCLK
 input wire RESET,
 input wire REQUEST,                       // request to send a line
 input wire [23:0] DATA0, DATA1, DATA2,    // RGB word
 
 output wire READY,                        // the REQUEST may be applied when this signal is active
 output wire ACTIVE,                       // shows that the cmd execution is running

 output wire DCLK, DCLK_ENA,               // serial data clock, derived from CLK
 output wire LATCH,                        // LATCH signal, determines a command
 output wire [NUMBER_OF_LANES-1:0] R, G, B,// output serialized data
 output wire [ADDR_WIDTH-1:0] ADDR,        // RGB-memory address
 output wire TX_DONE                       // this strobe shows that a command comletely done
);

//******************************************************************************
localparam DCLK_CNT_WIDTH = $clog2(NUM_IC_CHAIN*IC_WORD_LENGTH);
localparam IC_CNT_WIDTH   = $clog2(NUM_IC_CHAIN);
//******************************************************************************
reg [DCLK_CNT_WIDTH:0] dclk_cnt;   // counter for DCLKs (it clocks NUM_IC_CHAIN*NUM_CH_IC times)
reg [ADDR_WIDTH-1:0]   mem_addr;   // offset address for the external RAM
reg [4:0] ch_num_inv;              // channel (to send) number - actually it is inversed (reversed) state: 0 = ch 15, 1 = ch 14, and so on

wire [IC_CNT_WIDTH-1:0]   ic_cnt;

wire request_latch, ready;

reg [15:0] reg_r [NUMBER_OF_LANES-1:0];
reg [15:0] reg_g [NUMBER_OF_LANES-1:0];
reg [15:0] reg_b [NUMBER_OF_LANES-1:0];

reg [NUMBER_OF_LANES-1:0] r_dly, g_dly, b_dly; // delay regs at the outputs to align data and clock

wire dclk; reg dclk_ena;
reg  latch, latch_ena;

reg line_tx_start, line_tx_run, line_tx_done;
reg ch_tx_start, ch_tx_run, ch_tx_done;

reg mem_addr_inc;
wire data_load;

//******************************************************************************
assign READY  = ready;
assign ACTIVE = line_tx_run;
assign LATCH  = latch;
assign DCLK   = dclk, DCLK_ENA = dclk_ena;

assign TX_DONE = line_tx_done;
assign ADDR    = mem_addr;

//assign R = reg_r[15], G = reg_g[15], B = reg_b[15];
assign R = r_dly, G = g_dly, B = b_dly;

//******************************************************************************
// DCLK
// dclk_cnt sets a number of active DCLK clocks
reg dclk_ena_dly;       // delay register for DCLK enable, for aligning 1st DCLK and LATCH
always @(negedge CLK)   // !!! here the NEGedge CLK used to provide correct DCLK forming 
 begin
        dclk_ena_dly <= (dclk_cnt != 0);
   #`PD dclk_ena <= dclk_ena_dly;
 end

assign dclk   = dclk_ena ? ~CLK : 1'b0; // inverted CLK to align the rising edge to the middle of DATA
//------------------------------------------------------------------------------
// enable LATCH when latch_cnt == 0
// latch_cnt sets a number of clocks before switching LATCH to high level
always @(posedge CLK or posedge RESET) // pos-edge CLK 
 if (RESET)      #`PD latch <= 0;
 else
   if ((ch_tx_run) && (dclk_cnt == 1)) 
                 #`PD latch <= 1;
   else          #`PD latch <= 0;

//******************************************************************************
// counter for the ICs in the chain
generate if (IC_WORD_LENGTH == 16)
  begin  : gen_ic_cnt_16
         assign ic_cnt = dclk_cnt[DCLK_CNT_WIDTH:4];
  end
  else       // assume that IC_WORD_LENGTH == 8 here
   begin   : gen_ic_cnt_8
         assign ic_cnt = {1'b0, dclk_cnt[DCLK_CNT_WIDTH:3]};
   end
 endgenerate
 //******************************************************************************
// Channel Number
wire ch_num_inv_inc = mem_addr_inc && (ic_cnt == 1);
always @(posedge CLK or posedge RESET)
 if (RESET)                 ch_num_inv <= 0; //NUM_CH_IC;
   else
     if (line_tx_start)     ch_num_inv <= 0; //NUM_CH_IC;
	  else
	    if (ch_num_inv_inc) ch_num_inv <= ch_num_inv + 1;//- 1;

//------------------------------------------------------------------------------
// RAM address

reg mem_addr_inc_delayed;        
always @(posedge CLK )  mem_addr_inc_delayed <= mem_addr_inc;

// the greyscale data in the RAM are arragged as following:
// ICn_Ch15, IC(n)_Ch14, ... ICn_Ch1, ICn_Ch0; IC(n-1)_Ch15, IC(n-1)_Ch14, ... IC(n-1)_Ch1, IC(n-1)_Ch0; ...
wire mem_addr_load = ch_tx_start || (mem_addr_inc_delayed && (ic_cnt == 0));
reg ch_tx_done_delayed;

always @(posedge CLK or posedge request_latch)
begin
 if(request_latch)      mem_addr <= 0;
 else
  begin
    if (mem_addr_load)  mem_addr <= ch_num_inv; // set address pointer to the first in the line (this pixel's value will be written to the last IC/channel in the chain)
    else
      if (mem_addr_inc) mem_addr <= mem_addr + NUM_CH_IC;
  end
end

always @(posedge CLK)  ch_tx_done_delayed <= ch_tx_done;

//------------------------------------------------------------------------------
// RAM data, fetch strobe
 generate if (IC_WORD_LENGTH == 16)
  begin  : gen_data_load_strobe_ch_16
   assign data_load = ( ch_tx_start || (dclk_cnt[3:0] == 1) ); // a word length is 16 bit, reload it when a shift data out is completed
  end
  else       // assume that IC_WORD_LENGTH == 8 here
   begin   : gen_data_load_strobe_ch_8
    assign data_load = ( ch_tx_start || (dclk_cnt[2:0] == 1) ); // debug: a word length is 8 bit
   end
 endgenerate
 
// RAM data, dec address
always @(posedge CLK or posedge RESET)
 if(RESET)   mem_addr_inc  <= 0;
 else
   begin
             mem_addr_inc  <= data_load && (dclk_cnt != 1);
   end   

initial
  begin
      $display("** MBI5153_data (line) Simulation settings **");
      $display("* NUM_IC_CHAIN        %d  *", NUM_IC_CHAIN);
      $display("* NUM_CH_IC           %d  *", NUM_CH_IC);
      $display("* IC_WORD_LENGTH      %d  *", IC_WORD_LENGTH);
      $display("* ADDR_WIDTH          %d  *", ADDR_WIDTH);
      $display("*******                      *******");
  end

//------------------------------------------------------------------------------
// delay data output to align with the clock
always @(posedge CLK)
 begin // tbd generate
//   r_dly <= reg_r[15]; g_dly <= reg_g[15]; b_dly <= reg_b[15]; 
   r_dly[0] <= reg_r[0][15]; g_dly[0] <= reg_g[0][15]; b_dly[0] <= reg_b[0][15]; 
   r_dly[1] <= reg_r[1][15]; g_dly[1] <= reg_g[1][15]; b_dly[1] <= reg_b[1][15]; 
   r_dly[2] <= reg_r[2][15]; g_dly[2] <= reg_g[2][15]; b_dly[2] <= reg_b[2][15]; 
 end

// fetch and shift out the RGB DATA
always @(posedge CLK or posedge RESET)
begin
 if(RESET)
   begin
          reg_r[0] <= 0; reg_g[0] <= 0; reg_b[0] <= 0;
          reg_r[1] <= 0; reg_g[1] <= 0; reg_b[1] <= 0;
          reg_r[2] <= 0; reg_g[2] <= 0; reg_b[2] <= 0;
   end  
 else
  begin
    if (data_load)
      begin // tbd generate
          reg_r[0] <= {DATA0[23:16], RGB_LSB}; reg_g[0] <= {DATA0[15:8], RGB_LSB}; reg_b[0] <= {DATA0[7:0], RGB_LSB};
          reg_r[1] <= {DATA1[23:16], RGB_LSB}; reg_g[1] <= {DATA1[15:8], RGB_LSB}; reg_b[1] <= {DATA1[7:0], RGB_LSB};
          reg_r[2] <= {DATA2[23:16], RGB_LSB}; reg_g[2] <= {DATA2[15:8], RGB_LSB}; reg_b[2] <= {DATA2[7:0], RGB_LSB};
      end 
    else if (ch_tx_run)
      begin
          reg_r[0] <= {reg_r[0][14:0], 1'b0}; reg_g[0] <= {reg_g[0][14:0], 1'b0}; reg_b[0] <= {reg_b[0][14:0], 1'b0}; 
          reg_r[1] <= {reg_r[1][14:0], 1'b0}; reg_g[1] <= {reg_g[1][14:0], 1'b0}; reg_b[1] <= {reg_b[1][14:0], 1'b0}; 
          reg_r[2] <= {reg_r[2][14:0], 1'b0}; reg_g[2] <= {reg_g[2][14:0], 1'b0}; reg_b[2] <= {reg_b[2][14:0], 1'b0}; 
      end
  end
end

//******************************************************************************
always @(posedge CLK or posedge RESET)
 if (RESET)                 dclk_cnt <= 0;
 else
 begin          
  if (ch_tx_start)     #`PD dclk_cnt <= NUM_IC_CHAIN*IC_WORD_LENGTH; // IC_WORD_LENGTH - is the data (GS) word length
  else if (ch_tx_run)
    begin
     if (dclk_cnt)     #`PD dclk_cnt <= dclk_cnt - 1;
    end
 end

//******************************************************************************
//******************************************************************************
// FSM for transmitting 1 channel for 1 scan line
 localparam FSM_TX_LN_IDLE       = 0,
            FSM_TX_LN_LD_AD      = 1, 
            FSM_TX_LN_DATA_SETUP = 2,
            FSM_TX_LN_START      = 3, 
            FSM_TX_LN_RUN        = 4,
            FSM_TX_LN_NEXT_CH    = 5,
            FSM_TX_LN_DONE       = 6;
//------------------------------------------------------------------------------
// FSM_TX_CH registered block
reg [2:0] fsm_tx_ln, fsm_tx_ln_next_state;
always @(posedge CLK or posedge RESET)
 if (RESET)             #`PD fsm_tx_ln <= FSM_TX_LN_IDLE;
 else if (1)            #`PD fsm_tx_ln <= fsm_tx_ln_next_state;

//------------------------------------------------------------------------------
// TX_LN FSM combinational block 
//always @(fsm_tx_ln or request_latch or dclk_cnt or ch_num_inv)
always @(posedge CLK or posedge RESET)
if (RESET)             #`PD fsm_tx_ln_next_state <= FSM_TX_LN_IDLE;
else
begin: fsm_tx_ln_fsm
// case (fsm_tx_ln)
 case (fsm_tx_ln_next_state)
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
   FSM_TX_LN_IDLE:
    begin
                                     line_tx_run <= 0; line_tx_done <= 0;
				  ch_tx_start <= 0;   ch_tx_run <= 0;   ch_tx_done <= 0;   
     if (request_latch)
	   begin
				  line_tx_start <= 1;
                  fsm_tx_ln_next_state <= FSM_TX_LN_LD_AD;
	   end
	   else
	     begin
		          line_tx_start <= 0;
		 end
    end
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
   FSM_TX_LN_LD_AD:
    begin
				  ch_tx_done <= 0;
		          line_tx_start <= 0;
                  fsm_tx_ln_next_state <= FSM_TX_LN_DATA_SETUP;
    end
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
   FSM_TX_LN_DATA_SETUP:
    begin
				  ch_tx_start <= 1;
                  fsm_tx_ln_next_state <= FSM_TX_LN_START;
    end
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
   FSM_TX_LN_START:
    begin
				  ch_tx_start <= 0;
	              ch_tx_run <= 1;
                  fsm_tx_ln_next_state <= FSM_TX_LN_RUN;
    end
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
   FSM_TX_LN_RUN:
    begin
                  line_tx_start <= 0;
                  line_tx_run   <= 1;
    if (dclk_cnt == 0)
                  fsm_tx_ln_next_state <= FSM_TX_LN_NEXT_CH;
    end
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
   FSM_TX_LN_NEXT_CH:
    begin
				  ch_tx_run <= 0;
                  ch_tx_done <= 1;
                  if (ch_num_inv == NUM_CH_IC)
                      fsm_tx_ln_next_state <= FSM_TX_LN_DONE;
                  else
					  fsm_tx_ln_next_state <= FSM_TX_LN_LD_AD;
    end
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
   FSM_TX_LN_DONE:
    begin
                  line_tx_run   <= 0;
                  line_tx_done  <= 1;
                  fsm_tx_ln_next_state <= FSM_TX_LN_IDLE;
    end
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
   default:
    begin
//      line_tx_run <= 0; line_tx_done <= 0;
//      ch_tx_start <= 0; ch_tx_run <= 0;   ch_tx_done <= 0;   
      fsm_tx_ln_next_state <= FSM_TX_LN_IDLE;
    end
    
 endcase
end //fsm_tx_ln_fsm

//******************************************************************************
//******************************************************************************
// request-ready fsm
fsm_rq_rdy fsm_rq_rdy_inst (
 .CLK (CLK), .RESET (RESET),                       // inputs
 .REQ (REQUEST), .ACK (line_tx_start), .DONE (line_tx_done),
 .REQUEST_LATCH (request_latch), .READY (ready)    // outputs
);

//******************************************************************************

endmodule
