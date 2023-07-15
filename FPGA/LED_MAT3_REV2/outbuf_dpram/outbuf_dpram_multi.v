// Image DPM  - 3 blocks
// inferred dual-port memory is used
// Author: Dim Su
// Date:   20180609

module outbuf_dpram_multi
#(
 parameter DATA_WIDTH = 24,     // 24-bit RGB
 parameter ADDR_WIDTH = 6,      // 64 columns 
 parameter MEMORY_WIDTH  = 2048, // 64x32
 parameter NUMBER_OF_BLOCKS = 3
)
(
 input RESET,  // async reset
 input IN_CLK, OUT_CLK,
 
 input  [NUMBER_OF_BLOCKS-1:0] WR_ENA,
 
 input  [OUTBUF_ADDR_WIDTH-1:0] OUTBUF_IN_ADDR [NUMBER_OF_BLOCKS-1:0],
 
 input  [DATA_WIDTH-1:0] OUTBUF_IN_DATA,
 output [DATA_WIDTH-1:0] OUTBUF_OUT_DATA [NUMBER_OF_BLOCKS-1:0],
 
 input  [OUTBUF_ADDR_WIDTH-1:0] OUTBUF_OUT_ADDR
);


// Top	
outbuf_dpram
# ( //.INIT_MIF ("../outbuf_dpram/image3_top.mif"),
    .MEMORY_WIDTH (MEMORY_WIDTH),
    .DATA_WIDTH (OUTBUF_DATA_WIDTH), .ADDR_WIDTH (OUTBUF_ADDR_WIDTH) )
outbuf_dpram_inst1 (
 .data ( OUTBUF_IN_DATA ),
 .rdaddress ( OUTBUF_OUT_ADDR ),
 .rdclock ( OUT_CLK ),
 .rdclocken ( 1'b1 ),
 .rden ( 1'b1 ),
 .wraddress ( OUTBUF_IN_ADDR[0] ),
 .wrclock ( IN_CLK ),
 .wrclocken ( 1'b1 ),
 .wren ( WR_ENA[0] ), 
 .q ( OUTBUF_OUT_DATA[0] )
);

// Mid
outbuf_dpram
# ( //.INIT_MIF ("../outbuf_dpram/image3_mid.mif"),
    .MEMORY_WIDTH (MEMORY_WIDTH),
    .DATA_WIDTH (OUTBUF_DATA_WIDTH), .ADDR_WIDTH (OUTBUF_ADDR_WIDTH) )
outbuf_dpram_inst2 (
 .data ( OUTBUF_IN_DATA ),
 .rdaddress ( OUTBUF_OUT_ADDR ),
 .rdclock ( OUT_CLK ),
 .rdclocken ( 1'b1 ),
 .rden ( 1'b1 ),
 .wraddress ( OUTBUF_IN_ADDR[1] ),
 .wrclock ( IN_CLK ),
 .wrclocken ( 1'b1 ),
 .wren ( WR_ENA[1] ), 
 .q ( OUTBUF_OUT_DATA[1] )
);
/*
// Bot
outbuf_dpram
# ( //.INIT_MIF ("../outbuf_dpram/image3_bot.mif"),
    .MEMORY_WIDTH (MEMORY_WIDTH),
    .DATA_WIDTH (OUTBUF_DATA_WIDTH), .ADDR_WIDTH (OUTBUF_ADDR_WIDTH) )
outbuf_dpram_inst3 (
 .data ( OUTBUF_IN_DATA ),
 .rdaddress ( OUTBUF_OUT_ADDR ),
 .rdclock ( OUT_CLK ),
 .rdclocken ( 1'b1 ),
 .rden ( 1'b1 ),
 .wraddress ( OUTBUF_IN_ADDR[2] ),
 .wrclock ( IN_CLK ),
 .wrclocken ( 1'b1 ),
 .wren ( WR_ENA[2] ), 
 .q ( OUTBUF_OUT_DATA[2] )
);
*/
endmodule
