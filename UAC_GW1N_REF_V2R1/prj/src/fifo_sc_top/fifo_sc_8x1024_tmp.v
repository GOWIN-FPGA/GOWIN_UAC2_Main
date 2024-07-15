//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.9 Beta3
//Part Number: GW2AR-LV18QN88C8/I7
//Device: GW2AR-18
//Device Version: C
//Created Time: Tue Mar 28 11:41:31 2023

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	fifo_sc_8x1024 your_instance_name(
		.Data(Data_i), //input [7:0] Data
		.Clk(Clk_i), //input Clk
		.WrEn(WrEn_i), //input WrEn
		.RdEn(RdEn_i), //input RdEn
		.Reset(Reset_i), //input Reset
		.Wnum(Wnum_o), //output [10:0] Wnum
		.Q(Q_o), //output [7:0] Q
		.Empty(Empty_o), //output Empty
		.Full(Full_o) //output Full
	);

//--------Copy end-------------------
