//==============================================================================
//  Purpose: UART 8N1 
//  Version: v1.0
//  Input:   Base Clock, Divider (clocks per bit)
//  Output:  16-bytes Rx FIFO
//  Author: Dim Su
//  History Release: 
//  20171009 - initial ver.
//  20171011 - minor correction to work
//==============================================================================

`default_nettype none

module uart
#(
 parameter BASIC_FREQ = 1152000,
 parameter BAUD_RATE  = 9600
)
(
 input CLK,
 input RESET,
 input FIFO_FLUSH,
 
 input  RXD,
 output TXD,
 
 output TX_FIFO_FULL,
 input  [7:0] TX_BYTE,
 input  TX_FIFO_WR_REQ,
 
 output [3:0] RX_FIFO_LEVEL,
 output [7:0] RX_FIFO_Q,
 input  RD_FIFO_RD_REQ
);

wire is_tx, is_rx, rx_err;
wire rx_byte_received_stb, rx_fifo_empty, rx_fifo_full;
wire [7:0] rx_byte, rx_fifo_q, tx_fifo_q;
wire [3:0] rx_fifo_level, tx_fifo_level;

reg  tx_fifo_rd_req, tx_request;
wire tx_fifo_full, tx_fifo_empty;

//------------------------------------------------------------------------------
// ports breaking out
assign TX_FIFO_FULL  = tx_fifo_full;
assign RX_FIFO_LEVEL = rx_fifo_level;
assign RX_FIFO_Q = rx_fifo_q;

//------------------------------------------------------------------------------
uart_rxtx
#(
 .BASIC_FREQ (BASIC_FREQ),
 .BAUD_RATE  (BAUD_RATE)
)
 uart_rxtx_core
(
  .clk (CLK),                       // The master clock for this module, 25MHz
  .rst (RESET),                     // Synchronous reset.
  .rx  (RXD),                       // Incoming serial line
  .tx  (TXD),                       // Outgoing serial line
  .transmit (tx_request),           // Signal to transmit (1 clock)
  .tx_byte  (tx_fifo_q),            // Byte to transmit
  .received (rx_byte_received_stb), // Indicated that a byte has been received.
  .rx_byte  (rx_byte),              // Byte received
  .is_receiving    (is_rx),         // Low when receive line is idle.
  .is_transmitting (is_tx),         // Low when transmit line is idle.
  .recv_error      (rx_err)         // Indicates error in receiving packet.
);
    
//------------------------------------------------------------------------------
// RX FIFO
uart_fifo uart_fifo_rx     
(
	.clock (CLK),
	.sclr  (FIFO_FLUSH),
	.empty (rx_fifo_empty),
	.data  (rx_byte),
	.wrreq (rx_byte_received_stb),
	.usedw (rx_fifo_level),
	.full  (rx_fifo_full),
	.rdreq (RD_FIFO_RD_REQ),
	.q     (rx_fifo_q)
);

//------------------------------------------------------------------------------
// TX FIFO
uart_fifo uart_fifo_tx      
(
	.clock (CLK),
	.sclr  (FIFO_FLUSH),
	.empty (tx_fifo_empty),
	.data  (TX_BYTE),
	.wrreq (TX_FIFO_WR_REQ),
	.usedw (tx_fifo_level),
	.full  (tx_fifo_full),
	.rdreq (tx_fifo_rd_req), 
	.q     (tx_fifo_q)
);

//------------------------------------------------------------------------------
reg [2:0]  fsm_tx_state;
localparam TX_STATE_IDLE  = 0,   // reset state
           TX_STATE_READY = 1,   // get here when there is no an active TX transfer
           TX_STATE_RD_FIFO = 2, // forming FIFO RD_ACK (and UART CORE TX_WR) signals
           TX_STATE_TRANSMIT_REQ = 3,
           TX_STATE_TRANSMIT_REQ_DONE = 4;

// TX FIFO FSM           
always @(posedge CLK or posedge RESET)
 if (RESET)
  begin
   tx_fifo_rd_req <= 0; tx_request <= 0;
                         fsm_tx_state <= TX_STATE_IDLE;
  end
  else
  case (fsm_tx_state)
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   TX_STATE_IDLE:
    if (!is_tx)          fsm_tx_state <= TX_STATE_READY;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   TX_STATE_READY:
    if (!tx_fifo_empty)  fsm_tx_state <= TX_STATE_RD_FIFO;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   TX_STATE_RD_FIFO:
    begin
     tx_fifo_rd_req <= 1;                 // read FIFO data
                         fsm_tx_state <= TX_STATE_TRANSMIT_REQ;
    end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   TX_STATE_TRANSMIT_REQ:
    begin
     tx_request <= 1; tx_fifo_rd_req <= 0; // the data from FIFO is ready now
                         fsm_tx_state <= TX_STATE_TRANSMIT_REQ_DONE;
    end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   TX_STATE_TRANSMIT_REQ_DONE:
    begin
     tx_request <= 0;
                         fsm_tx_state <= TX_STATE_IDLE;
    end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   default:              fsm_tx_state <= TX_STATE_IDLE;
   
  endcase
  
   


endmodule
