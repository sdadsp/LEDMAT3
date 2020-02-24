// strobe extender (to transfer a strobe from a fast to the slow clock domain)
// Author: Dim Su
// Initial: 201707xx
// Updated: 20171013
// Reset added: 20180122
// usage:
// stb_extender stb_ext_inst1 ( clk_10M, clk_1k, stb_01s_domain_10M, stb_01s_domain_1k);


module stb_extender (

input reset,

// fast clock domain
input clk_in,
input stb_in,

// slow clock domain
input clk_out,
output stb_out 
);

reg reg_stb_in, reg_stb_out;

assign stb_out = reg_stb_out;

always @ (posedge clk_in or posedge reset)
 if (reset)        reg_stb_in <= 0;
  else
    begin
      if (stb_in)  reg_stb_in <= 1;
      if (stb_out) reg_stb_in <= 0;
    end

always @ (posedge clk_out or posedge reset)
 if (reset) reg_stb_out <= 0;
  else      reg_stb_out <= reg_stb_in;
 
 
endmodule
