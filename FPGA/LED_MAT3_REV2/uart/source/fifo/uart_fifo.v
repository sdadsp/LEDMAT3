// parametrized FIFO
// generated by Altera Quartus Wizard
// altered/edited by Dim Su
// 20171011

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module uart_fifo (
	clock,
	data,
	rdreq,
	sclr,
	wrreq,
	empty,
	full,
	q,
	usedw);

	input	  clock;
	input	[7:0]  data;
	input	  rdreq;
	input	  sclr;
	input	  wrreq;
	output	  empty;
	output	  full;
	output	[7:0]  q;
	output	[3:0]  usedw;

	wire  sub_wire0;
	wire  sub_wire1;
	wire [7:0] sub_wire2;
	wire [3:0] sub_wire3;
	wire  empty = sub_wire0;
	wire  full = sub_wire1;
	wire [7:0] q = sub_wire2[7:0];
	wire [3:0] usedw = sub_wire3[3:0];

	scfifo	scfifo_component (
				.clock (clock),
				.data (data),
				.rdreq (rdreq),
				.sclr (sclr),
				.wrreq (wrreq),
				.empty (sub_wire0),
				.full (sub_wire1),
				.q (sub_wire2),
				.usedw (sub_wire3),
				.aclr (),
				.almost_empty (),
				.almost_full (),
				.eccstatus ());
	defparam
		scfifo_component.add_ram_output_register = "ON",
		scfifo_component.intended_device_family = "MAX 10",
		scfifo_component.lpm_numwords = 16,
		scfifo_component.lpm_showahead = "OFF",
		scfifo_component.lpm_type = "scfifo",
		scfifo_component.lpm_width = 8,
		scfifo_component.lpm_widthu = 4,
		scfifo_component.overflow_checking = "ON",
		scfifo_component.underflow_checking = "ON",
		scfifo_component.use_eab = "ON";


endmodule

