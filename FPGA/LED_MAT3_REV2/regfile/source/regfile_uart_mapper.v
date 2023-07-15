//==============================================================================
//  Purpose: Registers' File UART Mapper
//  Version: v1.1
//  Input:   Control Buses 
//  Output:  Status registers
//  Author:  Dim Su
//  History Release: 
//  20171010 - initial ver.
//  20171011 - working version (rx)
//  20171012 - working version (rx, tx)
//  20171013 - add reset values for the registers' file
//  20180119 - register file address width extended
//  20180707 - UART speed is parametrizied 
//  20220902 - timeouts, auto-response
//  20230623 - REG8 added 
//==============================================================================

module regfile_uart_mapper
#(
 parameter UART_BASIC_FREQ = 1152000,
 parameter UART_BAUD_RATE  = 9600,
 parameter TIMEOUT_VAL  = 3,

 parameter REG_0_RST_VAL = 0, parameter REG_1_RST_VAL = 0,
 parameter REG_2_RST_VAL = 0, parameter REG_3_RST_VAL = 0,
 parameter REG_4_RST_VAL = 0, parameter REG_5_RST_VAL = 0,
 parameter REG_6_RST_VAL = 0, parameter REG_7_RST_VAL = 0,
 parameter REG_8_RST_VAL = 0,
 parameter REG_16_RST_VAL = 0, parameter REG_17_RST_VAL = 0,
 parameter REG_18_RST_VAL = 0, parameter REG_19_RST_VAL = 0,
 parameter REG_20_RST_VAL = 0, parameter REG_21_RST_VAL = 0,
 parameter REG_22_RST_VAL = 0, parameter REG_23_RST_VAL = 0,
 parameter REG_24_RST_VAL = 0
)
(
 input CLK, // UART_BASIC_FREQ 
 input RESET,
 
 output reg [15:0] REGFILE_OUT [31:0], // 32x 16-bits registers
 input      [15:0] REGFILE_IN  [31:0],
 
 input AUTO_RESP,                      // automatic response for every data packet
 
 input  RXD,
 output TXD
   
);

localparam SOP  = 8'h3C; // '<'
localparam EOP1 = 8'h2F; // '/'
localparam EOP2 = 8'h3E; // '>'
localparam REQ  = 8'h3F; // '?'

//------------------------------------------------------------------------------
// Convert a single ASCII HEX digit into a corresponding
// 4-bit binary number by subtracting 0x30 or 0x37
function [7:0] ascii2hex;
 input [7:0] a;
 begin
   if   (a > 8'h40) ascii2hex = a - 8'h37; // A..F
    else 
     if (a > 8'h39) ascii2hex = a;         // service symbols
      else          ascii2hex = a - 8'h30; // 0..9
 end
endfunction

//------------------------------------------------------------------------------
// Convert a 4-bit binary number to an ASCII HEX digit
function [7:0] hex2ascii;
 input [7:0] a;
 begin
   if   (a < 8'h0A)  hex2ascii = 8'h30 + a; // 0..9
    else
     if (a < 8'h10)  hex2ascii = 8'h37 + a; // A..F
      else           hex2ascii = a;         // no conversion
 end
endfunction

//------------------------------------------------------------------------------

reg  [20:0] clk_divider; // bit depth must be enough to fit UART_BASIC_FREQ value!
reg         stb_1s;

wire [3:0] rx_fifo_level;
wire [7:0] rx_byte;
reg  rx_fifo_rd_req;

// cmd format: <xx=0123/> (where xx - a Hex address: example <02=0123/> )
//             <xx=?/>
reg  [7:0] rx_packet [7:0];                                     // max 8 bytes for the incoming data packet
reg  [2:0] rx_packet_data_cnt;
wire       rx_packet_complete = (rx_packet_data_cnt == 3'b000); // the rx data counter is equal to 0 when complete packet is received
wire [7:0] rx_packet_data3 = rx_packet[3]; // here we expect a '?'

wire [4:0] regfile_addr      = { rx_packet[0][0], rx_packet[1][3:0] };

wire [15:0] regfile_data_out = { rx_packet[3][3:0], rx_packet[4][3:0], rx_packet[5][3:0], rx_packet[6][3:0] };

//  tx
wire tx_fifo_full;
reg [7:0] tx_byte;
reg  tx_fifo_wr_req;

reg regfile_read_req;

//------------------------------------------------------------------------------

// FSM for receiving a following packet (e.g. 0x12 <= 0x0123): <12=0123/>
reg [2:0]  fsm_rx_parser_state, fsm_rx_parser_next_state;
localparam RX_PARSER_STATE_IDLE = 0,
           RX_PARSER_STATE_SOP  = 1, // look for '<'
           RX_PARSER_STATE_FETCH_DATA = 2, 
           RX_PARSER_STATE_EOP2 = 3, // check for'>' 
           RX_PARSER_STATE_DONE = 4,
           RX_PARSER_STATE_REQ = 5,
           RX_PARSER_STATE_RD = 6,
           RX_PARSER_STATE_RD_DONE = 7;
           
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
always @(posedge CLK)
 begin
   if(clk_divider)
	 begin
	  stb_1s <= 0;
     clk_divider <= clk_divider - 1;
	 end
	else
    begin
	  stb_1s <= 1;
	  clk_divider <= UART_BASIC_FREQ;
	 end 
	
 end
 
//------------------------------------------------------------------------------
// Timeout generator
reg [7:0] timeout_reg;
reg timeout_set;
reg timeout_done;

always @(posedge CLK)
 if(timeout_set)                timeout_reg <= TIMEOUT_VAL;
 else
 if((stb_1s) && (timeout_reg))  timeout_reg <= timeout_reg - 1;

always @(posedge CLK or posedge RESET)
 if(RESET)                      timeout_done <= 0;
 else
  begin 
   if(timeout_set)              timeout_done <= 0;
   else if(timeout_reg == 0)    timeout_done <= 1;
  end

//------------------------------------------------------------------------------
// Rx FSM
always @(posedge CLK or posedge RESET)
begin
 if (RESET)
  begin
            fsm_rx_parser_state      <= RX_PARSER_STATE_IDLE;
            fsm_rx_parser_next_state <= RX_PARSER_STATE_IDLE;
            rx_fifo_rd_req           <= 0;
            regfile_read_req         <= 0;
				timeout_set              <= 0;
            // registers' reset values
            REGFILE_OUT[0] <= REG_0_RST_VAL; REGFILE_OUT[1] <= REG_1_RST_VAL; 
            REGFILE_OUT[2] <= REG_2_RST_VAL; REGFILE_OUT[3] <= REG_3_RST_VAL;
            REGFILE_OUT[4] <= REG_4_RST_VAL; REGFILE_OUT[5] <= REG_5_RST_VAL; 
            REGFILE_OUT[6] <= REG_6_RST_VAL; REGFILE_OUT[7] <= REG_7_RST_VAL;
				REGFILE_OUT[8] <= REG_8_RST_VAL;
            REGFILE_OUT[16] <= REG_16_RST_VAL; REGFILE_OUT[17] <= REG_17_RST_VAL; 
            REGFILE_OUT[18] <= REG_18_RST_VAL; REGFILE_OUT[19] <= REG_19_RST_VAL; 
            REGFILE_OUT[20] <= REG_20_RST_VAL; REGFILE_OUT[21] <= REG_21_RST_VAL; 
            REGFILE_OUT[22] <= REG_22_RST_VAL; REGFILE_OUT[23] <= REG_23_RST_VAL; 
            REGFILE_OUT[24] <= REG_24_RST_VAL;
  end
 else
 case(fsm_rx_parser_state)
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  RX_PARSER_STATE_IDLE:                                
   begin
    regfile_read_req <= 1'b0; 
    rx_fifo_rd_req   <= 1'b0;
    
    if (rx_fifo_level)                     // if there is some data in Rx FIFO..
     begin
	         timeout_set <= 1'b1;                             // set the cmd timeout
            fsm_rx_parser_next_state <= RX_PARSER_STATE_SOP; // will expect SOP
            fsm_rx_parser_state      <= RX_PARSER_STATE_RD;
     end
	 else
	  begin
	         timeout_set <= 1'b0;
	  end
	  
   end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  RX_PARSER_STATE_SOP:                      // expecting a SOP symbol here ('<')
   begin
     timeout_set <= 0;
     if (rx_byte == SOP)
       begin
             rx_packet_data_cnt <= 0;
             fsm_rx_parser_next_state <= RX_PARSER_STATE_FETCH_DATA;
       end
       else  fsm_rx_parser_next_state <= RX_PARSER_STATE_SOP; // will expect SOP 
       
     fsm_rx_parser_state      <= RX_PARSER_STATE_RD;
   end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  RX_PARSER_STATE_FETCH_DATA:
    begin
      rx_packet[rx_packet_data_cnt] <= ascii2hex(rx_byte);     // convert to BIN-HEX on fly

      if (    ((rx_packet_data_cnt == 7) && (rx_byte != EOP1))
           || ((rx_byte < 8'h2F) || (rx_byte > 8'h46)) )       // if an error condition
             fsm_rx_parser_next_state <= RX_PARSER_STATE_SOP;  // => search for SOP
      else
       if (rx_byte == EOP1)                                    // if EOP1 ('/') received...
             fsm_rx_parser_next_state <= RX_PARSER_STATE_EOP2;
        else
             fsm_rx_parser_next_state <= RX_PARSER_STATE_FETCH_DATA; // => read next byte 
      
      rx_packet_data_cnt++;
      fsm_rx_parser_state      <= RX_PARSER_STATE_RD;
    end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  RX_PARSER_STATE_EOP2:                                  // expecting EOP2 ('>')
    begin
     if (rx_byte == EOP2)
            fsm_rx_parser_state <= RX_PARSER_STATE_DONE;
     else   fsm_rx_parser_state <= RX_PARSER_STATE_SOP;  // look for SOP again
    end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  RX_PARSER_STATE_DONE:
   begin
     if (rx_packet_data3 == REQ) // if a request received... (question mark after '=')
       fsm_rx_parser_state         <= RX_PARSER_STATE_REQ;
     else
      begin
       if (rx_packet_complete)                          // if the full packet received...
         REGFILE_OUT[regfile_addr] <= regfile_data_out; // -> update the register
        
		 if(AUTO_RESP) 
         fsm_rx_parser_state       <= RX_PARSER_STATE_REQ;
		 else
         fsm_rx_parser_state       <= RX_PARSER_STATE_IDLE;
      end
   end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  RX_PARSER_STATE_REQ:
   begin
    regfile_read_req <= 1;        // send request to the TX FSM
    fsm_rx_parser_state       <= RX_PARSER_STATE_IDLE;
   end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  RX_PARSER_STATE_RD:
   begin
	 timeout_set <= 1'b0;
	 
    if(timeout_done)              // check for timeout
 	  begin
	   fsm_rx_parser_state      <= RX_PARSER_STATE_IDLE;
	  end
	  
	 else
	 
    if (rx_fifo_level)
     begin    
            rx_fifo_rd_req <= 1'b1;
            fsm_rx_parser_state <= RX_PARSER_STATE_RD_DONE;
     end
   end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  RX_PARSER_STATE_RD_DONE:
   begin
            rx_fifo_rd_req <= 1'b0;
            fsm_rx_parser_state <= fsm_rx_parser_next_state; // next state after reading byte from FIFO
   end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  default:
            fsm_rx_parser_state     <= RX_PARSER_STATE_IDLE;

 endcase
end

//------------------------------------------------------------------------------
// tx packet format: <10=0123/>
wire [7:0] tx_packet [9:0];
reg  [3:0] tx_packet_data_cnt;

assign tx_packet[9] = SOP;          // '<'
assign tx_packet[8] = rx_packet[0]; // reg. number Maj., or 8'h41; ('A')
assign tx_packet[7] = rx_packet[1]; // reg. number Min
assign tx_packet[6] = 8'h3D;        // '='
assign tx_packet[5] = { 4'h0, REGFILE_IN[regfile_addr][15:12] };
assign tx_packet[4] = { 4'h0, REGFILE_IN[regfile_addr][11:8]  };
assign tx_packet[3] = { 4'h0, REGFILE_IN[regfile_addr][7:4]   };
assign tx_packet[2] = { 4'h0, REGFILE_IN[regfile_addr][3:0]   };
assign tx_packet[1] = EOP1, tx_packet[0] = EOP2; // "/>"

// FSM for sending the TX packet (e.g.): <xy=0123/>
reg [1:0]  fsm_tx_state;
localparam TX_STATE_IDLE = 0,
           TX_STATE_SEND = 1, // send a data array
           TX_STATE_NEXT_BYTE = 2,
           TX_STATE_NOPE = 3;

//------------------------------------------------------------------------------
// Tx FSM
always @(posedge CLK or posedge RESET)
begin
 if (RESET)
  begin
            fsm_tx_state   <= TX_STATE_IDLE;
            tx_fifo_wr_req <= 1'b0;
  end
 else
 case(fsm_tx_state)
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  TX_STATE_IDLE:
   begin
    if (regfile_read_req)
     begin
             tx_packet_data_cnt <= 10;
             fsm_tx_state <= TX_STATE_NEXT_BYTE;
     end
   end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  TX_STATE_SEND:
   begin
             tx_fifo_wr_req <= 1'b1;
             tx_byte <= hex2ascii(tx_packet[tx_packet_data_cnt]); // on-fly hex to ascii conversion to save logic
             fsm_tx_state <= TX_STATE_NEXT_BYTE;
   end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  TX_STATE_NEXT_BYTE:
   begin
             tx_fifo_wr_req <= 1'b0;
             
    if (tx_packet_data_cnt == 4'b0000) 
            fsm_tx_state <= TX_STATE_IDLE;
    else
     if (!tx_fifo_full)  // tbd - timeout
      begin
             tx_packet_data_cnt--;
             fsm_tx_state <= TX_STATE_NOPE;
      end
   end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  TX_STATE_NOPE:       // an empty cycle 
             fsm_tx_state <= TX_STATE_SEND;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  default:   fsm_tx_state <= TX_STATE_IDLE;  
   
 endcase
end

//------------------------------------------------------------------------------
uart
#(
 .BASIC_FREQ (UART_BASIC_FREQ),
 .BAUD_RATE  (UART_BAUD_RATE)
)
 uart_inst1
(
 .CLK   (CLK),
 .RESET (RESET),
 .FIFO_FLUSH (RESET), // tbd
 
 .RXD (RXD), .TXD (TXD),
 
 .TX_FIFO_FULL (tx_fifo_full),
 .TX_BYTE (tx_byte),
 .TX_FIFO_WR_REQ (tx_fifo_wr_req),
 
 .RX_FIFO_LEVEL (rx_fifo_level),
 .RX_FIFO_Q (rx_byte),
 .RD_FIFO_RD_REQ (rx_fifo_rd_req)
);

//------------------------------------------------------------------------------

endmodule
