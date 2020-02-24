// Frequency Measurerement
// counts the actual periods of 'FREQ_TO_MEASURE' signal
// Depending on COUNT_MODE parameter, counts the clocks:
// - "STB_1K": at the interval between STB_1K pulses (1kHz period, the duty level must be 2x or more times longer than input freq.)
// - "DE":     in the DE window
// Author: Dim Su
// Date:    20171012
// Updated: 20171014

module freq_measure
#(
 parameter FREQ_CNT_WIDTH = 16,
 parameter COUNT_MODE = "STB_1K"
)
(
 input RESET,  // async reset
 
 input STB_1K, // low_freq_domain strobe
 input DE,     // count window
 
 input FREQ_TO_MEASURE,
 
 output [FREQ_CNT_WIDTH-1:0] RESULT_MEASURED
);

 reg [FREQ_CNT_WIDTH-1:0] frequency_measured;
 reg [FREQ_CNT_WIDTH-1:0] in_freq_cnt;
 reg [FREQ_CNT_WIDTH-1:0] in_freq_cnt_filter [3:0];
 
 reg [1:0] filter_cnt;

 wire [FREQ_CNT_WIDTH-1+4:0] in_freq_cnt_result_filtered;
 
 assign RESULT_MEASURED = frequency_measured;

 // averaging result
 assign in_freq_cnt_result_filtered = {4'b00, in_freq_cnt_filter[0]} + {4'b00, in_freq_cnt_filter[1]}
                                    + {4'b00, in_freq_cnt_filter[2]} + {4'b00, in_freq_cnt_filter[3]};
 
 // generate 'FREQ_TO_MEASURE' domain strobe
 reg [2:0] stb_delay;
 reg stb_cnt_done_clkin_domain;
 
 wire stb_count_done;
 wire count_ena;
 wire [FREQ_CNT_WIDTH-1:0] result_correction;

//------------------------------------------------------------------------------
 generate if (COUNT_MODE == "STB_1K")
  begin  : gen_stb_1k
   assign stb_count_done = STB_1K;
   assign count_ena = 1'b1;
   assign result_correction = 0;
  end
  else
   begin   : gen_de
    assign stb_count_done = DE;
    assign count_ena = DE;
    assign result_correction = 1;
   end
 endgenerate
 
//------------------------------------------------------------------------------
 always @(posedge FREQ_TO_MEASURE)
  begin
   stb_delay                 <= { stb_delay[1:0], stb_count_done };
   stb_cnt_done_clkin_domain <= ( stb_delay[2:1] == 2'b01 );
  end
 
//------------------------------------------------------------------------------
 // input freq. counter and filter
 always @(posedge FREQ_TO_MEASURE)
  if (stb_cnt_done_clkin_domain) // end of strobe
   begin
    in_freq_cnt_filter[0] <= in_freq_cnt;// filter
    in_freq_cnt_filter[1] <= in_freq_cnt_filter[0];
    in_freq_cnt_filter[2] <= in_freq_cnt_filter[1];
    in_freq_cnt_filter[3] <= in_freq_cnt_filter[2];
    
    in_freq_cnt <= 0;
   end
   else                          // strobe is active
    if (count_ena)  in_freq_cnt++;
   
//------------------------------------------------------------------------------
 // latch result 
 always @(posedge FREQ_TO_MEASURE or posedge RESET)
  if (RESET)
    frequency_measured <= 0;
  else
  if (stb_cnt_done_clkin_domain) // end of strobe
   begin
    frequency_measured <= in_freq_cnt + result_correction; //[debug, no filtering] in_freq_cnt_result_filtered[FREQ_CNT_WIDTH-1+4:4];
   end

   
endmodule
