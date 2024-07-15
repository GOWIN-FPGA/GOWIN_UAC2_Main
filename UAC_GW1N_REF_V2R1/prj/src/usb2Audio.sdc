//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.9 Beta2
//Created Time: 2023-02-10 11:06:58

// 120MHz
create_clock -name USB_CLKDIV -period 8.333 -waveform {0 4.165} [get_nets {u_USB_SoftPHY_Top/usb2_0_softphy/u_usb_20_phy_utmi/u_usb2_0_softphy/u_usb_phy_hs/sclk}]

// 60.0MHz
create_clock -name PHY_CLKOUT -period 16.666 -waveform {0 8.333} [get_pins {u_pll/rpll_inst/CLKOUTD}]

// 49.152MHz
create_clock -name I2S_MCLK -period 20.345 -waveform {0 10.17} [get_nets {xmclk}]

// 480.0MHz
create_clock -name USB_FCLK -period 2.083 -waveform {0 1.041} [get_pins {u_pll/rpll_inst/CLKOUT}]

// 12.0MHz
create_clock -name CLK_IN -period 83.333 -waveform {0 41.66} [get_ports {CLK_IN}]

// 98.304MHz
create_clock -name I2S_FCLK  -period 10.173 -waveform {0 5.086} [get_pins {u_iis_rPLL/rpll_inst/CLKOUT}]

// 49.152MHz
//create_clock -name I2S_CLKIN -period 20.345 -waveform {0 10.17} [get_pins {u_iis_rPLL/rpll_inst/CLKIN}]

//set_false_path -from [get_clocks {PHY_CLKOUT}] -to [get_clocks {USB_CLKDIV}] 
//set_false_path -from [get_clocks {USB_CLKDIV}] -to [get_clocks {PHY_CLKOUT}] 
//set_false_path -from [get_clocks {I2S_FCLK}] -to [get_clocks {PHY_CLKOUT}] 
//set_false_path -from [get_clocks {PHY_CLKOUT}] -to [get_clocks {I2S_FCLK}] 
//set_false_path -from [get_clocks {PHY_CLKOUT}] -to [get_clocks {USB_FCLK}] 
//set_false_path -from [get_clocks {I2S_MCLK}] -to [get_clocks {PHY_CLKOUT}] 
//set_false_path -from [get_clocks {PHY_CLKOUT}] -to [get_clocks {I2S_MCLK}] 

set_clock_groups -asynchronous -group [get_clocks {PHY_CLKOUT}] -group [get_clocks {USB_CLKDIV}]  -group [get_clocks {I2S_FCLK}] -group [get_clocks {USB_FCLK}] -group [get_clocks {I2S_MCLK}]

set_operating_conditions -grade c -model slow -speed 7