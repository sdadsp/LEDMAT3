rgb_delay_line	rgb_delay_line_inst (
	.data ( data_sig ),
	.rdclk ( rdclk_sig ),
	.rdreq ( rdreq_sig ),
	.wrclk ( wrclk_sig ),
	.wrreq ( wrreq_sig ),
	.q ( q_sig ),
	.rdempty ( rdempty_sig ),
	.rdfull ( rdfull_sig ),
	.wrempty ( wrempty_sig ),
	.wrfull ( wrfull_sig )
	);
