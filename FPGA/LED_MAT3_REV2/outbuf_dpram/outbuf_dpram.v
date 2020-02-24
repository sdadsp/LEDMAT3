
// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module outbuf_dpram 
#(
// parameter INIT_MIF = "../outbuf_dpram/image_top.mif",
 parameter DATA_WIDTH = 24,     // 24-bit RGB
 parameter ADDR_WIDTH = 6,      // 64 columns 
 parameter MEMORY_WIDTH  = 2048 // 64x32 
)

(
	data,
	rdaddress,
	rdclock,
	rdclocken,
	rden,
	wraddress,
	wrclock,
	wrclocken,
	wren,
	q);

	input	[DATA_WIDTH-1:0]  data;
	input	[ADDR_WIDTH-1:0]  rdaddress;
	input	  rdclock;
	input	  rdclocken;
	input	  rden;
	input	[ADDR_WIDTH-1:0]  wraddress;
	input	  wrclock;
	input	  wrclocken;
	input	  wren;
	output	[DATA_WIDTH-1:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  rdclocken;
	tri1	  rden;
	tri1	  wrclock;
	tri1	  wrclocken;
	tri0	  wren;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [DATA_WIDTH-1:0] sub_wire0;
	wire [DATA_WIDTH-1:0] q = sub_wire0[DATA_WIDTH-1:0];

	altsyncram	altsyncram_component (
				.address_a (wraddress),
				.address_b (rdaddress),
				.clock0 (wrclock),
				.clock1 (rdclock),
				.clocken0 (wrclocken),
				.clocken1 (rdclocken),
				.data_a (data),
				.rden_b (rden),
				.wren_a (wren),
				.q_b (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b ({DATA_WIDTH{1'b1}}),
				.eccstatus (),
				.q_a (),
				.rden_a (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.address_reg_b = "CLOCK1",
		altsyncram_component.clock_enable_input_a = "NORMAL",
		altsyncram_component.clock_enable_input_b = "NORMAL",
		altsyncram_component.clock_enable_output_b = "NORMAL",
//		altsyncram_component.init_file = INIT_MIF,
		altsyncram_component.intended_device_family = "MAX 10",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = MEMORY_WIDTH,
		altsyncram_component.numwords_b = MEMORY_WIDTH,
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_b = "CLOCK1",
//		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.rdcontrol_reg_b = "CLOCK1",
		altsyncram_component.widthad_a = ADDR_WIDTH,
		altsyncram_component.widthad_b = ADDR_WIDTH,
		altsyncram_component.width_a = DATA_WIDTH,
		altsyncram_component.width_b = DATA_WIDTH,
		altsyncram_component.width_byteena_a = 1;


endmodule
