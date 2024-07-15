//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.9 Beta3
//Part Number: GW2AR-LV18QN88C8/I7
//Device: GW2AR-18
//Device Version: C
//Created Time: Sat Apr 01 16:54:58 2023

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	shift_reg_8x100 your_instance_name(
		.clk(clk_i), //input clk
		.Reset(Reset_i), //input Reset
		.Din(Din_i), //input [7:0] Din
		.Q(Q_o) //output [7:0] Q
	);

//--------Copy end-------------------
