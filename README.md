# LEDMAT3
HDMI - LED Display Controller (FPGA)
This is a simple FPGA project (and PCB as well) for driving the common LED panels based on MBI5124, MBI5153, and ICN2038 chips.
The input data is derived from TPG, or pre-compiled image, or HDMI input.
The USB-VCP port allows to control the basic LED display parameters.

Two types of LED panels are supported: 
1) 64x64 panels (2 lanes, each 1/32 scan ratio). That are "normal" cascadable panels
2) 120x90 panels (3 lanes, each 1/32 scan ratio). These panels are non-cascadable. A "virtual" cascading is used for driving more than 1 panel in a common way.
