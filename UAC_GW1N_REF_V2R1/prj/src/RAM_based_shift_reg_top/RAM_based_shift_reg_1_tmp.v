//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.9 Beta3
//Part Number: GW1N-LV9LQ144C7/I6
//Device: GW1N-9
//Device Version: C
//Created Time: Sat Apr 01 17:52:21 2023

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	RAM_based_shift_reg_1 your_instance_name(
		.clk(clk_i), //input clk
		.Reset(Reset_i), //input Reset
		.Din(Din_i), //input [0:0] Din
		.Q(Q_o) //output [0:0] Q
	);

//--------Copy end-------------------
