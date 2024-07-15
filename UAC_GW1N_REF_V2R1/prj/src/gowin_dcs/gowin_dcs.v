//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//GOWIN Version: V1.9.9 Beta2
//Part Number: GW1N-LV9LQ144C7/I6
//Device: GW1N-9
//Device Version: C
//Created Time: Tue Mar 14 15:10:49 2023

module Gowin_DCS (clkout, clksel, clk0, clk1, clk2, clk3);

output clkout;
input [3:0] clksel;
input clk0;
input clk1;
input clk2;
input clk3;

wire gw_gnd;

assign gw_gnd = 1'b0;

DCS dcs_inst (
    .CLKOUT(clkout),
    .CLKSEL(clksel),
    .CLK0(clk0),
    .CLK1(clk1),
    .CLK2(clk2),
    .CLK3(clk3),
    .SELFORCE(gw_gnd)
);

defparam dcs_inst.DCS_MODE = "RISING";

endmodule //Gowin_DCS
