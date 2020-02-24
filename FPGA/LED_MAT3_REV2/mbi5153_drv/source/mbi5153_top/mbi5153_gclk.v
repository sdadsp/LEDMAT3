//******************************************************************************
// MBI5153 GCLK and line switching (scan) control
// - Natively, the module runs GCLK with the dead time intervals according to the 
// selected GS-depth (16x512 GCLKs or 32x512 GCLKs).
//
// obsolete:
//  - If the module receives the WAIT_STB signal, it waits for 50 GCLKs, then stops 
// GCLK, then waits for a number of clocks and rises 'VSYNC_ENA' up.
// - VSYNC resets the line scan counter.
// - After receiving VSYNC, waiting for GCLK_START_AFTER_VSYNC, then starting GCLK
//
// actual:
// GCLK_DISPLAY is switching internal/external control
// GCLK_ON_OFF turns on/off GCLK in the extarnal control mode
// In the Internal control mode the module generates the signals according the MBI5153 AppNote
//
// Author:  Dim Su
// Initial date: 20171227
// Release History:
// 20171228 - ready for simulation
// 20180103 - simulated with 'wait' request
// 20180104 - 2nd clock domain removed; all clk-domains' crossings must be done externally
// 20180104 - the module's functionality has been reduced. Simulation done.
// 20180116 - corrections
// 20180117 - global changes related to the module behaviour and FSM coding
// 20180122 - EOS position shifted left
// 20180123 - FSM re-coded in the safe way (latches eliminated)
//******************************************************************************

// synopsys translate_off
`timescale 1 ns / 10 ps
// synopsys translate_on

`default_nettype none

// define the propagation delay (for simulation)
`define PD_TRIG 0
`define PD_COMB 0

module mbi5153_gclk
#(
 parameter DEBUG_MODE = "NO",
                        // debug values:   // nominal values:
 parameter PWM13_CYCLE_NUM_SECTIONS   = 2,               // 16
 parameter PWM14_CYCLE_NUM_SECTIONS   = 4,               // 32
 parameter PWM_CYCLE_GCLK_CLOCKS      = 8,               // 512
 parameter GCLK_LINE_SWITCH_DEAD_TIME_H = 3,             // 6  @ 20MHz
 parameter GCLK_LINE_SWITCH_DEAD_TIME_L = 5              // 24 @ 20MHz
)
(
 input wire RESET,
 input wire CLK,              // PWM CLOCK (input)
 
 input wire GCLK_DISPLAY,     // 1 - "display" sequence, 0 - external on/off control
 input wire GCLK_ON_OFF,      // external control: 1 - ON, 0 - OFF
 
 input wire [4:0] SCAN_RATIO, // scan ratio (number of the lines)
 input wire PWM_DEPTH,        // 0 = 13-bit, 1 = 14-bit
 
 output wire EOS,             // End Of Scan (frame display) strobe
 output wire GCLK_OUT,
 output wire GCLK_ACTIVE,
 output wire [4:0] SCAN_LINE_ADDR,
 
 output wire TEST_PIN
);

//localparam PWM_CNT_WIDTH = $clog2(PWM14_CYCLE_NUM_SECTIONS*PWM_CYCLE_GCLK_CLOCKS) + 1;
localparam DTM_CNT_WIDTH = $clog2(GCLK_LINE_SWITCH_DEAD_TIME_H + GCLK_LINE_SWITCH_DEAD_TIME_L) + 1;
localparam EOS_PRE_POS = 7;

//------------------------------------------------------------------------------
initial
 begin
  $display("******* MBI5153 GCLK settings               ********");
  $display("* PWM13_CYCLE_NUM_SECTIONS    %d          *", PWM13_CYCLE_NUM_SECTIONS);
  $display("* PWM14_CYCLE_NUM_SECTIONS    %d          *", PWM14_CYCLE_NUM_SECTIONS);
  $display("* PWM_CYCLE_GCLK_CLOCKS       %d          *", PWM_CYCLE_GCLK_CLOCKS);
  $display("* PWM14_CNT_LOAD_VALUE        %d          *", (PWM14_CYCLE_NUM_SECTIONS * PWM_CYCLE_GCLK_CLOCKS)+1 );
  $display("* GCLK_LINE_SWITCH_DEAD_TIME  %d          *", GCLK_LINE_SWITCH_DEAD_TIME_H + GCLK_LINE_SWITCH_DEAD_TIME_L);
  $display("* DTM_CNT_WIDTH               %d          *", DTM_CNT_WIDTH);
  $display("*******                                     *******");
 end
 
//******************************************************************************
reg [DTM_CNT_WIDTH-1:0] dtime_cnt;

reg [4:0] pwm_scan_line_cnt;
reg [4:0] pwm_section_cnt;
reg [9:0] pwm_cycle_cnt;

reg pwm_scan_line_cnt_ena, pwm_scan_line_cnt_load;
reg pwm_cycle_cnt_ena, pwm_cycle_cnt_load;
reg pwm_section_cnt_load, pwm_section_cnt_ena;
reg dtime_cnt_load, dtime_cnt_ena;
reg gclk_pre_ena;

reg pwm_cycle_cnt_last_clock;

reg [2:0] fsm_gclk, next_state_fsm_gclk;
localparam FSM_GCLK_IDLE                 = 0,
           FSM_GCLK_LOAD_PWM_SECTION_CNT = 1,
           FSM_GCLK_LOAD_PWM_CYCLE_CNT   = 2,
           FSM_GCLK_PWM_CYCLE_LOOP       = 3,
           FSM_GCLK_DTIME                = 4,
           FSM_GCLK_NEXT_LINE            = 5,
           FSM_GCLK_NEXT_SECTION         = 6;

reg gclk_ena;
reg gclk_force_high;
reg gclk_on_off, gclk_display;

// end of (frame) scan
reg eos, early_eos;

wire GCLK_IN = CLK;
wire reset = RESET | ~GCLK_DISPLAY;

//******************************************************************************
assign GCLK_ACTIVE = gclk_ena;
                     
assign SCAN_LINE_ADDR = pwm_scan_line_cnt;
assign EOS = early_eos; //eos;
//assign EOS = eos; //eos;

assign TEST_PIN = gclk_pre_ena;

//******************************************************************************
// GCLK_OUT enable

always @(negedge GCLK_IN)    // negedge!
  begin              
    gclk_display <= GCLK_DISPLAY;
    gclk_on_off  <= GCLK_ON_OFF;
  end

always @(negedge GCLK_IN)    // negedge!
  if ((gclk_display == 1'b0) && (gclk_on_off == 1'b0))  gclk_ena <= 1'b0;     // this will force GCLK_OUT to '0'
    else                                                gclk_ena <= gclk_pre_ena;

// according to the GCLK dead time diagram (MBI5153 datasheet):
assign GCLK_OUT    = gclk_force_high ? 1'b1 : (  ((gclk_display == 1'b0) && (gclk_on_off == 1'b1)) ?  GCLK_IN : (gclk_ena ? GCLK_IN : 1'b0) );
//assign GCLK_OUT    = ( gclk_pre_ena ? GCLK_IN : 1'b0 );


//******************************************************************************
always @(posedge GCLK_IN or posedge RESET) // posedge! ...RESET (not "reset")
 if (RESET)                                         gclk_force_high <= 1'b0;
// else
//   if (~GCLK_DISPLAY)
//     begin
//       if (GCLK_ON_OFF)                             gclk_force_high <= 1'b1;
//       else                                         gclk_force_high <= 1'b0;
//     end
   else
     begin
       if (pwm_cycle_cnt_last_clock)                gclk_force_high <= 1'b1;     // GCLK must go high at the last (513th) clock
       else
         if (dtime_cnt == GCLK_LINE_SWITCH_DEAD_TIME_L) gclk_force_high <= 1'b0; // gclk_(pre_)ena is reset to '0' at this moment...
     end

//******************************************************************************
// PWM Scan Line
always @(posedge GCLK_IN or posedge reset)
 if (reset)                     pwm_scan_line_cnt <= 0;
 else 
   if (pwm_scan_line_cnt_load)  pwm_scan_line_cnt <= 0;
   else
    if (pwm_scan_line_cnt_ena)  pwm_scan_line_cnt++;
    
//******************************************************************************
// PWM Section counter
always @(posedge GCLK_IN or posedge reset)
 if (reset)                  pwm_section_cnt <= 0;
 else 
   if (pwm_section_cnt_load) pwm_section_cnt <= PWM_DEPTH ? PWM14_CYCLE_NUM_SECTIONS-1 : PWM13_CYCLE_NUM_SECTIONS-1;
   else
    if (pwm_section_cnt_ena) pwm_section_cnt--;
    
//******************************************************************************
// PWM Cycle counter
always @(posedge GCLK_IN or posedge reset)
 if (reset)                  pwm_cycle_cnt <= 0;
 else 
   if (pwm_cycle_cnt_load)   pwm_cycle_cnt <= 0;
   else
    if (pwm_cycle_cnt_ena)   pwm_cycle_cnt++;

//always @(posedge GCLK_IN)
//    pwm_cycle_cnt_last_clock <= pwm_cycle_cnt == PWM_CYCLE_GCLK_CLOCKS - 1;

always @* // make it combinational
    pwm_cycle_cnt_last_clock <= (pwm_cycle_cnt == PWM_CYCLE_GCLK_CLOCKS);
    
//******************************************************************************
// Dead Time counter
always @(posedge GCLK_IN or posedge reset)
 if (reset)             dtime_cnt <= 0;
 else 
   if (dtime_cnt_load)  dtime_cnt <= GCLK_LINE_SWITCH_DEAD_TIME_H + GCLK_LINE_SWITCH_DEAD_TIME_L;
   else
    if (dtime_cnt != 0) dtime_cnt--;

//******************************************************************************
always @(posedge GCLK_IN or posedge reset)
 if (reset)  fsm_gclk <= FSM_GCLK_IDLE;
 else        fsm_gclk <= next_state_fsm_gclk;

//------------------------------------------------------------------------------
always @(fsm_gclk or pwm_cycle_cnt_last_clock or dtime_cnt or pwm_scan_line_cnt or pwm_section_cnt or SCAN_RATIO)
 case (fsm_gclk)
//- - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - 
  FSM_GCLK_IDLE:
   begin
     next_state_fsm_gclk <= FSM_GCLK_LOAD_PWM_SECTION_CNT;
   end
//- - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - 
  FSM_GCLK_LOAD_PWM_SECTION_CNT:
   begin
     next_state_fsm_gclk <= FSM_GCLK_LOAD_PWM_CYCLE_CNT;
   end
//- - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - 
  FSM_GCLK_LOAD_PWM_CYCLE_CNT:
   begin
     next_state_fsm_gclk <= FSM_GCLK_PWM_CYCLE_LOOP;
   end
//- - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - 
  FSM_GCLK_PWM_CYCLE_LOOP:
   begin
     if (pwm_cycle_cnt_last_clock)
           next_state_fsm_gclk <= FSM_GCLK_DTIME;
     else  next_state_fsm_gclk <= FSM_GCLK_PWM_CYCLE_LOOP;
   end
//- - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - 
  FSM_GCLK_DTIME:
   begin
     if (dtime_cnt == 0)
           next_state_fsm_gclk <= FSM_GCLK_NEXT_LINE;
     else  next_state_fsm_gclk <= FSM_GCLK_DTIME;
   end
//- - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - 
  FSM_GCLK_NEXT_LINE:
   begin
     if (pwm_scan_line_cnt == SCAN_RATIO)
       next_state_fsm_gclk <= FSM_GCLK_NEXT_SECTION;
     else
       next_state_fsm_gclk <= FSM_GCLK_LOAD_PWM_CYCLE_CNT;
   end
//- - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - 
  FSM_GCLK_NEXT_SECTION:
   begin
     if (pwm_section_cnt == 0)
       next_state_fsm_gclk <= FSM_GCLK_LOAD_PWM_SECTION_CNT;
     else
       next_state_fsm_gclk <= FSM_GCLK_LOAD_PWM_CYCLE_CNT;
   end
//- - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  default:
     next_state_fsm_gclk <= FSM_GCLK_IDLE;
//- - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
 endcase
//------------------------------------------------------------------------------

//always @(fsm_gclk or pwm_cycle_cnt_last_clock or pwm_section_cnt or dtime_cnt or pwm_scan_line_cnt)
always_comb 
 case (fsm_gclk)
//- - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - 
  FSM_GCLK_IDLE:
   begin
     eos                  <= 0;
     early_eos            <= 0;
     pwm_section_cnt_load <= 0;
     pwm_section_cnt_ena  <= 0;
     pwm_cycle_cnt_load   <= 0;
     pwm_cycle_cnt_ena    <= 0;
     dtime_cnt_load       <= 0;
     gclk_pre_ena         <= 0;
     pwm_scan_line_cnt_load <= 1;
     pwm_scan_line_cnt_ena  <= 0;
   end
//- - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - 
  FSM_GCLK_LOAD_PWM_SECTION_CNT:
   begin
     eos                  <= 0;
     early_eos            <= 0;
     pwm_section_cnt_load <= 1;
     pwm_section_cnt_ena  <= 0;
     pwm_cycle_cnt_load   <= 0;
     pwm_cycle_cnt_ena    <= 0;
     dtime_cnt_load       <= 0;
     gclk_pre_ena         <= 0;
     pwm_scan_line_cnt_load <= 0;
     pwm_scan_line_cnt_ena  <= 0;
   end
//- - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  FSM_GCLK_LOAD_PWM_CYCLE_CNT:
   begin
     eos                  <= 0;
     early_eos            <= 0;
     pwm_section_cnt_load <= 0;
     pwm_section_cnt_ena  <= 0;
     pwm_cycle_cnt_load   <= 1;
     pwm_cycle_cnt_ena    <= 0;
     dtime_cnt_load       <= 0;
     gclk_pre_ena         <= 0;
     pwm_scan_line_cnt_load <= 0;
     pwm_scan_line_cnt_ena  <= 0;
   end
//- - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - 
  FSM_GCLK_PWM_CYCLE_LOOP:
   begin
     eos                  <= 0;
     early_eos            <= 0;
     pwm_section_cnt_load <= 0;
     pwm_section_cnt_ena  <= 0;
     pwm_cycle_cnt_load   <= 0;
     pwm_cycle_cnt_ena    <= 1;
     gclk_pre_ena         <= 1;
     pwm_scan_line_cnt_load <= 0;
     pwm_scan_line_cnt_ena  <= 0;
     if (pwm_cycle_cnt_last_clock)
           dtime_cnt_load <= 1;
     else  dtime_cnt_load <= 0;
   end
//- - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - 
  FSM_GCLK_DTIME:
   begin
     eos                  <= 0;
     // "early" EOS:
     if ((pwm_section_cnt == 0) && (dtime_cnt == EOS_PRE_POS) && (pwm_scan_line_cnt == SCAN_RATIO))
           early_eos      <= 1;
     else  early_eos      <= 0;
     pwm_section_cnt_load <= 0;
     pwm_section_cnt_ena  <= 0;
     pwm_cycle_cnt_load   <= 0;
     pwm_cycle_cnt_ena    <= 0;
     dtime_cnt_load       <= 0;
     gclk_pre_ena         <= 0;
     pwm_scan_line_cnt_load <= 0;
     pwm_scan_line_cnt_ena  <= 0;
   end
//- - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - 
  FSM_GCLK_NEXT_LINE:
   begin
     eos                  <= 0;
     early_eos            <= 0;
     pwm_section_cnt_load <= 0;
     pwm_section_cnt_ena  <= 0;
     pwm_cycle_cnt_load   <= 0;
     pwm_cycle_cnt_ena    <= 0;
     dtime_cnt_load       <= 0;
     gclk_pre_ena         <= 0;
     pwm_scan_line_cnt_load <= 0;
     pwm_scan_line_cnt_ena  <= 1;
   end
//- - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - 
  FSM_GCLK_NEXT_SECTION:
   begin
     pwm_section_cnt_load <= 0;
     pwm_section_cnt_ena  <= 1;
     pwm_cycle_cnt_load   <= 0;
     pwm_cycle_cnt_ena    <= 0;
     dtime_cnt_load       <= 0;
     gclk_pre_ena         <= 0;
     pwm_scan_line_cnt_load <= 1;
     pwm_scan_line_cnt_ena  <= 0;
     if (pwm_section_cnt == 0)
           eos            <= 1;
     else  eos            <= 0;
     early_eos <= 0;
   end
//- - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - 
  default:
   begin
     eos                  <= 0;
     early_eos <= 0;
     pwm_section_cnt_load <= 0;
     pwm_section_cnt_ena  <= 0;
     pwm_cycle_cnt_load   <= 0;
     pwm_cycle_cnt_ena    <= 0;
     dtime_cnt_load       <= 0;
     gclk_pre_ena         <= 0;
     pwm_scan_line_cnt_load <= 0;
     pwm_scan_line_cnt_ena  <= 0;
   end
//- - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
 endcase

//******************************************************************************

endmodule


