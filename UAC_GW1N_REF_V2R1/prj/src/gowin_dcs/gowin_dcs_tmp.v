//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.9 Beta2
//Part Number: GW1N-LV9LQ144C7/I6
//Device: GW1N-9
//Device Version: C
//Created Time: Tue Mar 14 15:10:49 2023

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_DCS your_instance_name(
        .clkout(clkout_o), //output clkout
        .clksel(clksel_i), //input [3:0] clksel
        .clk0(clk0_i), //input clk0
        .clk1(clk1_i), //input clk1
        .clk2(clk2_i), //input clk2
        .clk3(clk3_i) //input clk3
    );

//--------Copy end-------------------
