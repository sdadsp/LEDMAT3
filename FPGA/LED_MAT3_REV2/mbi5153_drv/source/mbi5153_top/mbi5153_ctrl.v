//******************************************************************************
// MBI5153 control, sync, and data(frame) sending
//                0) wait for VSYNC strobe and latch it (vsync_stb_latch)
//
//                1) GCLK -> frame-display
//                2) if (vsync_stb_latch)
//                     -> reset vsync_stb_latch (by Ack) 
//                     -> vsync_stb_cnt++
//                     -> if (vsync_stb_cnt == 0) -> (re-)config loop (20)
//                        else                    -> update GS (gray-scale) data (10) 
//                    else -> Goto (1)      
//                10) Send frame (send request)
//                11) Wait for sending frame done
//                12) Wait for EOS
//                13) GCLK -> free-running; Wait for 50 GCLK
//                14) Stop GCLK
//                15) Send VSYNC command
//                16) Wait 'dead-time' (1500 ns?)
//                17) goto (1)
//
//                20) Wait for EOS
//                21) Stop GCLK (? tbd)
//                21) Send reconfig request
//                21) Wait for reconfig done
//                23) Goto (1)
//
// Author:  Dim Su
// Initial date: 20180106
// Release History:
// 20180106 - 1st (draft) simulation done
// 20180115 - corrections 
// 20180125 - GCLK On/Off periods reviewed 
// 20180131 - GCLK Scan Pattern runs during GS Update ! Wait for the EOS after GSU, then put 50-60 GCLKS, then stop GCLK and put VSYNC
//******************************************************************************

// synopsys translate_off
`timescale 1 ns / 10 ps
// synopsys translate_on

`default_nettype none

// define the propagation delay (for simulation)
`define PD 0

module mbi5153_ctrl
#( 
 parameter DEBUG_MODE = "NO",
 parameter GCLK_DCLK_RATIO = 2,  // GCLK/DCLK ratio. The wait/gap timings are based on GCLK clocks, but the module is fed by DCLK..
 parameter GCLK_CLOCKS_BEFORE_VSYNC = 50,
 parameter GCLK_STOP_AFTER_VSYNC = 30,
 parameter RCFG_VSYNC_NUM = 150  // number of the VSYNC strobes before reconfig
)
(
 input wire CLK,              // main clock, same freq and phase as DCLK
 input wire RESET,
 
 input wire VSYNC_STB,        // vertical sync

 output wire RECONFIG_REQ,    // request for (re-)configuration
 output wire UPDATE_GS_REQ,   // update GS data request
 output wire VSYNC_CMD_REQ,   // Driver VSYNC command
 
 input wire FUNC_RCFG_ENA,    // debug input (normally must be 1'b1): reconfig ena
 input wire FUNC_UPGS_ENA,    // debug input (normally must be 1'b1): update gray-scale ena
 
 input wire  RECONFIG_DONE,
 input wire  UPDATE_GS_DONE,
 input wire  CMD_DONE,        // command proceeded
 
 input wire  EOS,             // end of scan strobe
 
 output wire GCLK_DISPLAY,    // 0 - "external" control, 1 - display frame
 output wire GCLK_ON_OFF      // GCLK state during "external" controlling
);

localparam DCLK_CLOCKS_BEFORE_VSYNC = GCLK_CLOCKS_BEFORE_VSYNC/GCLK_DCLK_RATIO,
           DCLK_STOP_AFTER_VSYNC    = GCLK_STOP_AFTER_VSYNC/GCLK_DCLK_RATIO;
           
//localparam DCLK_CNT_WIDTH = $clog2(DCLK_STOP_AFTER_VSYNC);
localparam DCLK_CNT_WIDTH = 7;
localparam DCLK_STOP_BEFORE_VSYNC = 2;
           
//******************************************************************************
reg reconfig_req, update_gs_req, vsync_cmd_req;
reg [DCLK_CNT_WIDTH-1:0] dclk_cnt;

reg vsync_stb_latch, vsync_stb_ack;
reg dclk_cnt_dcbv_load; // load DCLK_CLOCKS_BEFORE_VSYNC value
reg dclk_cnt_dsav_load; // load DCLK_STOP_AFTER_VSYNC value
 
reg gclk_display, gclk_on_off;

reg [7:0] vsync_stb_cnt; // tbd width
reg vsync_stb_cnt_load;

//******************************************************************************
assign GCLK_DISPLAY = gclk_display,
       GCLK_ON_OFF = gclk_on_off,
       UPDATE_GS_REQ = update_gs_req,
       RECONFIG_REQ = reconfig_req,
       VSYNC_CMD_REQ = vsync_cmd_req;

//******************************************************************************
// latch the VSYNC_STB
always @(posedge CLK or posedge RESET)
  if (RESET)                 vsync_stb_latch <= 1; // after reset we want to re-configure the drivers...
  else
    if (vsync_stb_ack)       vsync_stb_latch <= 0;
    else if (VSYNC_STB)      vsync_stb_latch <= 1;

//******************************************************************************
// STOP/PAUSE GCLK counter
// normally, GCLK is [N%] faster than DCLK, thus we may use DCLK for waiting >50 GCLKs
always @(posedge CLK or posedge RESET)
if (RESET)                      dclk_cnt <= 0;
else
 if      (dclk_cnt_dcbv_load)   dclk_cnt <= DCLK_CLOCKS_BEFORE_VSYNC + DCLK_STOP_BEFORE_VSYNC;
 else
   if    (dclk_cnt_dsav_load)   dclk_cnt <= DCLK_STOP_AFTER_VSYNC;
   else
     if  (dclk_cnt)             dclk_cnt--;
 
//******************************************************************************
// VSYNC strobes' counter
always @(posedge CLK or posedge RESET)
 if (RESET)                                       vsync_stb_cnt <= 0;
   else
          begin
            if (vsync_stb_cnt_load)               vsync_stb_cnt <= RCFG_VSYNC_NUM;
            else
             if ((VSYNC_STB) && (vsync_stb_cnt))  vsync_stb_cnt--;
          end          

//******************************************************************************
// FSM for MBI5153 control
reg [3:0] fsm_led_drv, fsm_led_drv_next_state;

 localparam FSM_LED_DRV_IDLE                 = 0,
            FSM_LED_DRV_DISPLAY              = 1,
            FSM_LED_DRV_CHECK_VSYNC          = 2,
            FSM_LED_DRV_UPDATE_GS_REQ        = 3,
            FSM_LED_DRV_WAIT_UPDATE_DONE     = 4,
            FSM_LED_DRV_WAIT_EOS_AFTER_UPDATE= 5,
            FSM_LED_DRV_WAIT_BEFORE_VSYNC    = 6,
            FSM_LED_DRV_WAIT_CMD_DONE        = 7,
			FSM_LED_DRV_WAIT_BEFORE_DISPLAY  = 8,
			FSM_LED_DRV_RECONFIG_REQ         = 9,
			FSM_LED_DRV_WAIT_RECONFIG_DONE   = 10;
            
//------------------------------------------------------------------------------
// LED_DRV FSM registered block
always @(posedge CLK or posedge RESET)
 if (RESET)             #`PD fsm_led_drv <= FSM_LED_DRV_IDLE;
 else if (1)            #`PD fsm_led_drv <= fsm_led_drv_next_state;

//------------------------------------------------------------------------------
// LED_DRV FSM combinational block 
//always @(fsm_led_drv or vsync_stb_latch or dclk_cnt or vsync_stb_cnt
//                     or EOS or RECONFIG_DONE or UPDATE_GS_DONE or CMD_DONE)
always @(posedge CLK or posedge RESET)
 if (RESET)             #`PD fsm_led_drv_next_state <= FSM_LED_DRV_IDLE;
 else
 begin: fsm_led_drv_fsm
//  case (fsm_led_drv)
  case (fsm_led_drv_next_state)
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   FSM_LED_DRV_IDLE:
    begin
      gclk_display  <= 1'b0; gclk_on_off <= 1'b0;
      reconfig_req  <= 1'b0; update_gs_req <= 1'b0; vsync_cmd_req <= 1'b0;
      vsync_stb_ack <= 1'b0; vsync_stb_cnt_load <= 1'b0;
      
                fsm_led_drv_next_state <= FSM_LED_DRV_DISPLAY;
	end
// - - - Displaying the GS data, waiting for End Of Scan signal as well- - - - -
   FSM_LED_DRV_DISPLAY:
    begin
      gclk_display  <= 1'b1;
      vsync_stb_ack <= 1'b0;
      vsync_stb_cnt_load <= 1'b0;
//20180131      if (EOS)  fsm_led_drv_next_state <= FSM_LED_DRV_CHECK_VSYNC;
      if (vsync_stb_latch)
                fsm_led_drv_next_state <= FSM_LED_DRV_CHECK_VSYNC;

	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   FSM_LED_DRV_CHECK_VSYNC:       // check if VSYNC came
    begin
//20180131      if (!vsync_stb_latch)
//20180131                fsm_led_drv_next_state <= FSM_LED_DRV_DISPLAY;
//20180131      else
        begin
          vsync_stb_ack <= 1'b1;
          
          if (vsync_stb_cnt == 0) // periodically we have to re-configure drivers
            begin
             vsync_stb_cnt_load <= 1'b1;
             
             if(FUNC_RCFG_ENA == 1'b1)
                  fsm_led_drv_next_state <= FSM_LED_DRV_RECONFIG_REQ;
             else fsm_led_drv_next_state <= FSM_LED_DRV_DISPLAY;
            end
          else
            begin
             if(FUNC_UPGS_ENA == 1'b1)
                  fsm_led_drv_next_state <= FSM_LED_DRV_UPDATE_GS_REQ;
             else fsm_led_drv_next_state <= FSM_LED_DRV_DISPLAY;
            end
        end
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   FSM_LED_DRV_UPDATE_GS_REQ:     // send Update Gray Scale request
    begin
//20180131      gclk_display  <= 1'b0; gclk_on_off <= 1'b1; // free-running GCLK
      update_gs_req <= 1'b1;
      fsm_led_drv_next_state <= FSM_LED_DRV_WAIT_UPDATE_DONE;
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   FSM_LED_DRV_WAIT_UPDATE_DONE:  // wait until update done
    begin
      update_gs_req <= 1'b0;
      if (UPDATE_GS_DONE)
        fsm_led_drv_next_state <= FSM_LED_DRV_WAIT_EOS_AFTER_UPDATE; //20180131
//20180131         begin
//20180131           dclk_cnt_dcbv_load <= 1'b1;
//20180131           fsm_led_drv_next_state <= FSM_LED_DRV_WAIT_BEFORE_VSYNC;
//20180131        end
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   FSM_LED_DRV_WAIT_EOS_AFTER_UPDATE: //20180131   
    begin
      if (EOS)
        begin
          gclk_display  <= 1'b0; gclk_on_off <= 1'b1; // free-running GCLK //20180131  
          dclk_cnt_dcbv_load <= 1'b1;
          fsm_led_drv_next_state <= FSM_LED_DRV_WAIT_BEFORE_VSYNC;
        end
    end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   FSM_LED_DRV_WAIT_BEFORE_VSYNC:
    begin
      dclk_cnt_dcbv_load <= 1'b0;
      if (dclk_cnt == DCLK_STOP_BEFORE_VSYNC) gclk_on_off <= 1'b0;  // stop GCLK before sending VSYNC cmd
      
      if (dclk_cnt == 1)                                            // wait at least 50 GCLKs before stopping GCLK
        begin
          vsync_cmd_req <= 1'b1;       
	      fsm_led_drv_next_state <= FSM_LED_DRV_WAIT_CMD_DONE;
        end
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   FSM_LED_DRV_WAIT_CMD_DONE:
    begin
      vsync_cmd_req <= 1'b0;
      dclk_cnt_dsav_load <= 1'b1; // load  counter for keeping a pause before beginning displaing data
      if (CMD_DONE)
        begin
          fsm_led_drv_next_state <= FSM_LED_DRV_WAIT_BEFORE_DISPLAY;
        end
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   FSM_LED_DRV_WAIT_BEFORE_DISPLAY:
    begin
      dclk_cnt_dsav_load <= 1'b0;
      if (dclk_cnt == 0)
        begin
	      fsm_led_drv_next_state <= FSM_LED_DRV_DISPLAY;
        end
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   FSM_LED_DRV_RECONFIG_REQ:
    begin
     if (EOS) //20180131
      begin
       vsync_stb_cnt_load <= 1'b0;
       gclk_display <= 1'b0; gclk_on_off <= 1'b0; // no GCLK during re-config
       reconfig_req <= 1'b1;
       fsm_led_drv_next_state <= FSM_LED_DRV_WAIT_RECONFIG_DONE;
      end
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   FSM_LED_DRV_WAIT_RECONFIG_DONE:  // wait until reconfig done
    begin
      reconfig_req <= 1'b0;
      if (RECONFIG_DONE)
        begin
            fsm_led_drv_next_state <= FSM_LED_DRV_IDLE;
        end
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   default:
    begin
//      gclk_display  <= 1'b0; gclk_on_off <= 1'b0;
//      reconfig_req  <= 1'b0; update_gs_req <= 1'b0; vsync_cmd_req <= 1'b0;
//      vsync_stb_ack <= 1'b0; vsync_stb_cnt_dec <= 1'b0;
      fsm_led_drv_next_state <= FSM_LED_DRV_IDLE;
    end
    
  endcase
 end // fsm_led_drv_fsm
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

//******************************************************************************
  
endmodule









