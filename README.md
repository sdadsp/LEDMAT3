# LEDMAT3
HDMI - LED Display Controller (FPGA)
This is a simple FPGA project (and PCB as well) for driving the common LED RGB-matrixes based on the popular drivers. MBI5124, MBI5153, and ICN2038 chips.
The input data is derived from:
1) TPG (test pattern generator),
2) or pre-compiled image,
3) or HDMI input.

The USB-VCP port allows to control the basic LED display parameters without recompiling the project.

Compatible driver ICs:
1) MBI5124, TC5020, and similar
2) ICN2038
3) MBI5153

The fillowing LED panels are supported: 
1) up to 3 lanes, each up to 32 rows
2) up to 384 columns in the each lane
3) Non-cascaded panels (like Longrunled 120x90) are supported using a virtual internal chaining

Other basic panels' configurations may be set via the project defines.
