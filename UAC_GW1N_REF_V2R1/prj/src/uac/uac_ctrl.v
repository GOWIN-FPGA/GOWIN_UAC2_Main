// ===========Oooo==========================================Oooo========
// =  Copyright (C) 2014-2018 GuangDong Gowin Semiconductor Technology Co.,Ltd.
// =                     All rights reserved.
// =====================================================================
// __      __      __ File name          :uac_ctrl.v
// \ \    /  \    / / Module name        :uac_ctrl.v
//  \ \  / /\ \  / /  Created by         :Gowin Semiconductor
//   \ \/ /  \ \/ /   Author             :wuxingyu
//    \  /    \  /    Created On         :2022-04-15 15:08 GuangZhou
//     \/      \/     Description        :Verilog file for the uac_ctrl.v
// ---------------------------------------------------------------------
// Code Revision History :
// ---------------------------------------------------------------------
// Ver: | Author  |Changes Made:    |Mod. Date
// V0.0 | winson  |Initial version  |2022-04-15 15:08
// ===========Oooo==========================================Oooo========

`define SUPPORT_768_RATE
//===========================================
module uac_ctrl #(
    parameter CLOCK_SOURCE_ID       = 8'h05,//Clock Source
    parameter AUDIO_CONTROL_UNIT_ID = 8'h03,//Audio Control Feature Unit
    parameter CLOCK_SELECTOR_ID     = 8'h28,//Clock Selector
    parameter AUDIO_IT_FB_ENDPOINT  = 8'h01,
    parameter DOP_PACKET_CODE0      = 8'h05,//0x00 XX XX 0x05 0x00 XX XX 0x05
    parameter DOP_PACKET_CODE1      = 8'hFA //0x00 XX XX 0xFA 0x00 XX XX 0xFA
)
(
    input             PHY_CLKOUT         ,//clock
    input             RESET              ,//reset
    input             XMCLK              ,
    //USB Interface
    input             I_USB_HIGHSPEED    ,
    input             I_USB_SETUP        ,
    input  [3:0]      I_USB_ENDPT_SEL    ,
    input             I_USB_RXPKTVAL     ,
    input             I_USB_SOF          ,
    input             I_USB_RXACT        ,
    input             I_USB_RXVAL        ,
    input  [7:0]      I_USB_RXDAT        ,
    input             I_USB_TXACT        ,
    input             I_USB_TXPOP        ,
    output            O_USB_TXVAL        ,
    output [7:0]      O_USB_TXDAT        ,
    output [11:0]     O_USB_TXDAT_LEN    ,
    output            O_USB_TXCORK       ,
    input  [7:0]      I_INTERFACE_ALTER  ,
    output [7:0]      O_INTERFACE_ALTER  ,
    input  [7:0]      I_INTERFACE_SEL    ,
    input             I_INTERFACE_UPDATE ,
    input             I_FIFO_ALEMPTY     ,
    input             I_FIFO_ALFULL      ,
    //Audio Control
    output            O_DOP_EN           ,
    output            O_DSD_EN           ,
    output            O_MUTE             ,
    output [15:0]     O_CH0_VOLUME       ,
    output [15:0]     O_CH1_VOLUME       ,
    output [15:0]     O_CH2_VOLUME       ,
    output [31:0]     O_SAMPLE_RATE      ,
    output [ 7:0]     O_TX_DATA_BITS     ,
    output [ 7:0]     O_RX_DATA_BITS
    //Audio Interface
);

localparam  SET_REQ                  = 8'h21;
localparam  GET_REQ                  = 8'hA1;
localparam  CUR                      = 8'h01;
localparam  RANGE                    = 8'h02;
localparam  CS_SAM_FREQ_CONTROL      = 8'h01;
localparam  CS_CLOCK_VALID_CONTROL   = 8'h02;
localparam  FU_MUTE_CONTROL          = 8'h01;
localparam  FU_VOLUME_CONTROL        = 8'h02;
localparam  CX_CLOCK_SELECTOR_CONTROL= 8'h01;
localparam  AS_VAL_ALT_SETTINGS_CONTROL = 8'h02 ;
localparam  CN0                      = 8'h00;
localparam  CN1                      = 8'h01;
localparam  CN2                      = 8'h02;
localparam  SAMPLE_RATE_32           = 32'h00007D00;
localparam  SAMPLE_RATE_44_1         = 32'h0000AC44;
localparam  SAMPLE_RATE_48           = 32'h0000BB80;
localparam  SAMPLE_RATE_64           = 32'h0000FA00;
localparam  SAMPLE_RATE_88_2         = 32'h00015888;
localparam  SAMPLE_RATE_96           = 32'h00017700;
localparam  SAMPLE_RATE_128          = 32'h0001F400;
localparam  SAMPLE_RATE_176_4        = 32'h0002B110;
localparam  SAMPLE_RATE_192          = 32'h0002EE00;
localparam  SAMPLE_RATE_352_8        = 32'h00056220;
localparam  SAMPLE_RATE_384          = 32'h0005DC00;
localparam  SAMPLE_RATE_705_6        = 32'h000AC440;
localparam  SAMPLE_RATE_768          = 32'h000BB800;
localparam  VOLUME_NUM               = 16'h0001;
localparam  VOLUME_FS_MIN            = 16'hD200;
localparam  VOLUME_FS_MAX            = 16'h0000;
localparam  VOLUME_FS_RES            = 16'h0300;
localparam  VOLUME_HS_MAX            = 16'h0000;
localparam  VOLUME_HS_MIN            = 16'hC080;
localparam  VOLUME_HS_RES            = 16'h0080;
//==============================================================
//======USB Signals
wire        usb_sof;
wire        setup_active;
wire [ 3:0] endpt_sel;
wire        usb_rxact;
wire        usb_rxval;
wire [ 7:0] usb_rxdat;
wire        usb_txact;
wire        usb_txpop;
wire        usb_txcork;
wire [11:0] usb_txdat_len;
wire        usb_highspeed;
reg  [7:0]  interface0_alter;
reg  [7:0]  interface1_alter;
reg  [7:0]  interface2_alter;
//==============================================================
//======USB Setup
reg  [ 7:0] stage;
reg  [ 7:0] sub_stage;
reg  [ 7:0] req_type;
reg  [ 7:0] req_code;
reg  [15:0] wValue;
reg  [15:0] wIndex;
reg  [15:0] wLength;
reg         endpt0_send;
reg  [ 7:0] endpt0_dat;
//==============================================================
//======USB Audio Control Parameters
reg         set_sample_rate;
reg         set_clk_sel;
reg         set_cur_mute;
reg         get_ch0_volume_range;
reg         get_ch1_volume_range;
reg         get_ch2_volume_range;
reg         get_ch0_volume_cur;
reg         get_ch1_volume_cur;
reg         get_ch2_volume_cur;
reg         get_mute_cur;
reg         get_sample_rate_range;
reg         get_sample_rate_cur;
reg         get_clk_sel;
reg         get_clk_valid;
reg         get_cur_mute;
reg         get_cur_volume;
reg         get_min_volume;
reg         get_max_volume;
reg         get_res_volume;
reg         set_ch0_volume;
reg         set_ch1_volume;
reg         set_ch2_volume;
reg 		get_val_alt_se;
reg  [ 7:0] sample_rate_data [0:157];
reg  [ 7:0] clk_sel_cur;
reg  [16:0] sample_rate_addr;
reg  [31:0] sample_rate_cur;
reg  [ 7:0] sample_clk_valid;
reg  [31:0] pre_sample_rate_cur;
reg  [15:0] ch0_volume_cur;
reg  [15:0] ch1_volume_cur;
reg  [15:0] ch2_volume_cur;
reg         mute_cur;
reg         audio_rx_reset;
reg         audio_tx_reset;
//==============================================================
//======Feedback Endpoint
wire [ 7:0] ff_period;
wire [ 3:0] ff_frac_width;
reg  [31:0] ff_value;
reg  [31:0] feedback;
reg  [31:0] ff_cnt;
reg  [ 3:0] div3_cnt;
reg         sof_d0;
reg         sof_d1;
wire        sof_rise;
reg  [ 7:0] sof_cnt;
reg         uac_en;
wire        fifo_r_alempty;
wire        fifo_r_alfull;
reg         dop_pkt;
reg         dop_en;
reg         dop_dect;
reg  [ 3:0] byte_cnt;
reg  [ 3:0] dop_mute_cnt;
reg  [ 3:0] dsd_mute_cnt;
reg         dop_mute;
reg         dsd_mute;
reg  [ 7:0] dop_code;
reg  [31:0] mute_code;
reg         dsd_en;
reg  [ 7:0] tx_data_bits;
reg  [ 7:0] rx_data_bits;
//==============================================================
//======Input Signals
//==============================================================
assign setup_active     = I_USB_SETUP;
assign endpt_sel        = I_USB_ENDPT_SEL;
assign usb_sof          = I_USB_SOF;
assign usb_rxact        = I_USB_RXACT;
assign usb_rxval        = I_USB_RXVAL;
assign usb_rxdat        = I_USB_RXDAT;
assign usb_txact        = I_USB_TXACT;
assign usb_txpop        = I_USB_TXPOP;
assign usb_highspeed    = I_USB_HIGHSPEED;
//==============================================================
//======Interface Setting
assign O_INTERFACE_ALTER = (I_INTERFACE_SEL == 0) ? interface0_alter :
                           (I_INTERFACE_SEL == 1) ? interface1_alter :
                           (I_INTERFACE_SEL == 2) ? interface2_alter : 8'd0;
always@(posedge PHY_CLKOUT, posedge RESET) begin
    if (RESET) begin
        interface0_alter <= 'd0;
        interface1_alter <= 'd0;
    end
    else begin
        if (I_INTERFACE_UPDATE) begin
            if (I_INTERFACE_SEL == 0) begin
                interface0_alter <= I_INTERFACE_ALTER;
            end
            else if (I_INTERFACE_SEL == 1) begin
                interface1_alter <= I_INTERFACE_ALTER;
            end
            else if (I_INTERFACE_SEL == 2) begin
                interface2_alter <= I_INTERFACE_ALTER;
            end
        end
    end
end

always@(posedge PHY_CLKOUT, posedge RESET) begin
    if (RESET) begin
        audio_rx_reset <= 1'b0;
        audio_tx_reset <= 1'b0;
    end
    else begin
        if (I_INTERFACE_UPDATE) begin
            if (I_INTERFACE_SEL == 1) begin
                if (O_INTERFACE_ALTER == 8'd0) begin
                    audio_tx_reset <= 1'b1;
                end
                else begin
                    audio_tx_reset <= 1'b0;
                end
            end
            else if (I_INTERFACE_SEL == 2) begin
                if (O_INTERFACE_ALTER == 8'd0) begin
                    audio_rx_reset <= 1'b1;
                end
                else begin
                    audio_rx_reset <= 1'b0;
                end
            end
        end
        else begin
            audio_rx_reset <= 1'b0;
            audio_tx_reset <= 1'b0;
        end
    end
end
//-------------------------------------------------------------
//Comment:Audio Data FIFO
//-------------------------------------------------------------
//assign fs_data_endpt  = (!usb_highspeed)&(endpt_sel==4'd3);//Full Speed Using endpoint 03
//-----------------------------------------------------
//DOP Detection
//-----------------------------------------------------
wire      hs_data_endpt;
reg       usb_rxact_d0;
reg       usb_rxval_d0;
reg [7:0] usb_rxdat_d0;


assign hs_data_endpt  = (I_USB_ENDPT_SEL==4'd1);//High Speed Using endpoint 01
always @(posedge PHY_CLKOUT or posedge RESET) begin
    if (RESET) begin
        usb_rxact_d0 <= 1'b0;
        usb_rxval_d0 <= 1'b0;
        usb_rxdat_d0 <= 8'd0;
    end
    else begin
        usb_rxact_d0 <= usb_rxact;
        usb_rxval_d0 <= usb_rxval&hs_data_endpt;
        usb_rxdat_d0 <= usb_rxdat;
    end
end
always @(posedge PHY_CLKOUT or posedge RESET) begin
    if (RESET) begin
        dop_pkt  <= 1'b1;
        dop_en   <= 1'b0;
        dop_dect <= 1'b0;
        byte_cnt <= 4'd0;
        dop_mute_cnt <= 4'd0;
        dsd_mute_cnt <= 4'd0;
        dop_mute <= 1'b0;
        dsd_mute <= 1'b0;
        dop_code <= 8'd0;
        mute_code <= 32'd0;
    end
    else begin
        if (usb_rxact_d0) begin
            if (usb_rxval_d0) begin
                byte_cnt <= byte_cnt + 1'd1;
                mute_code <= {mute_code[23:0],usb_rxdat_d0};
                if (byte_cnt[1:0] == 2'd0) begin
                    if (mute_code == 32'h00969600) begin
                        dop_mute_cnt <= dop_mute_cnt + 1'b1;
                    end
                    else begin
                        dop_mute_cnt <= 4'd0;
                    end
                    if (mute_code == 32'h96969696) begin
                        dsd_mute_cnt <= dsd_mute_cnt + 1'b1;
                    end
                    else begin
                        dsd_mute_cnt <= 4'd0;
                    end
                end
                if (dop_pkt) begin
                    if (byte_cnt[1:0] == 2'd0) begin
                        if (usb_rxdat_d0 != 8'h00) begin
                            dop_pkt <= 1'b0;
                        end
                    end
                    else if (byte_cnt == 4'd3) begin
                        if (dop_dect) begin
                            if ((dop_code == DOP_PACKET_CODE0)&&(usb_rxdat_d0 != DOP_PACKET_CODE1)) begin
                                dop_pkt <= 1'b0;
                            end
                            else if ((dop_code == DOP_PACKET_CODE1)&&(usb_rxdat_d0 != DOP_PACKET_CODE0)) begin
                                dop_pkt <= 1'b0;
                            end
                            else begin
                                dop_code <= usb_rxdat_d0;
                            end
                        end
                        else begin
                            dop_dect <= 1'b1;
                            dop_code <= usb_rxdat_d0;
                            if ((usb_rxdat_d0 != DOP_PACKET_CODE0)&&(usb_rxdat_d0 != DOP_PACKET_CODE1)) begin
                                dop_pkt <= 1'b0;
                            end
                        end
                    end
                    else if (byte_cnt == 4'd7) begin
                        if (usb_rxdat_d0 != dop_code) begin
                            dop_pkt <= 1'b0;
                        end
                    end
                    else if (byte_cnt == 4'd11) begin
                        if ((dop_code == DOP_PACKET_CODE0)&&(usb_rxdat_d0 != DOP_PACKET_CODE1)) begin
                            dop_pkt <= 1'b0;
                        end
                        else if ((dop_code == DOP_PACKET_CODE1)&&(usb_rxdat_d0 != DOP_PACKET_CODE0)) begin
                            dop_pkt <= 1'b0;
                        end
                        else begin
                            dop_code <= usb_rxdat_d0;
                        end
                    end
                    else if (byte_cnt == 4'd15) begin
                        if (usb_rxdat_d0 != dop_code) begin
                            dop_pkt <= 1'b0;
                        end
                    end
                end
            end
        end
        else begin
             mute_code <= 32'd0;
             if (dop_mute_cnt >= 4) begin
                 dop_mute <= 1'b1;
             end
             else begin
                 dop_mute <= 1'b0;
             end
             if (dsd_mute_cnt >= 4) begin
                 dsd_mute <= 1'b1;
             end
             else begin
                 dsd_mute <= 1'b0;
             end
             byte_cnt <= 4'd0;
             if (dop_dect) begin
                 dop_dect <= 1'b0;
                 if (dop_pkt) begin
                     dop_en <= 1'b1;
                 end
                 else begin
                     dop_en <= 1'b0;
                 end
             end
             else begin
                 dop_pkt <= 1'b1;
             end
        end
    end
end
//-------------------------------------------------------------
//Comment:USB UAC Control Endpoint0
//-------------------------------------------------------------
always @(posedge PHY_CLKOUT,posedge RESET) begin
    if (RESET) begin
        stage <= 8'd0;
        sub_stage <= 8'd0;
        req_type <= 8'd0;
        req_code <= 8'd0;
        wValue <= 16'd0;
        wIndex <= 16'd0;
        wLength <= 16'd0;
        set_sample_rate <= 1'b0;
        set_clk_sel <= 1'b0;
        endpt0_send <= 1'd0;
        endpt0_dat  <= 8'd0;
        sample_rate_addr <= 16'd0;
        sample_rate_cur <= SAMPLE_RATE_44_1;
        ch0_volume_cur  <= VOLUME_HS_MAX;
        ch1_volume_cur  <= VOLUME_HS_MAX;
        ch2_volume_cur  <= VOLUME_HS_MAX;
        sample_clk_valid<= 8'h01;
        get_ch0_volume_range <= 1'b0;
        get_ch1_volume_range <= 1'b0;
        get_ch2_volume_range <= 1'b0;
        get_ch0_volume_cur <= 1'b0;
        get_ch1_volume_cur <= 1'b0;
        get_ch2_volume_cur <= 1'b0;
        get_sample_rate_cur <= 1'b0;
        clk_sel_cur     <= 8'h01;
        get_mute_cur <= 1'b0;
        get_sample_rate_range <= 1'b0;
        get_clk_sel     <= 1'b0;
        get_clk_valid   <= 1'b0;
        set_ch1_volume <= 1'b0;
        set_ch2_volume <= 1'b0;
        set_cur_mute   <= 1'b0;
        get_cur_mute   <= 1'b0;
        get_cur_volume <= 1'b0;
        get_min_volume <= 1'b0;
        get_max_volume <= 1'b0;
        get_res_volume <= 1'b0;
        mute_cur       <= 1'b0;
		get_val_alt_se <= 1'b0;
    end
    else begin
        if (setup_active) begin
            if (usb_rxval) begin
                case (stage)
                    8'd0 : begin
                        req_type <= usb_rxdat;//request type set (D7:0set 1get, D6D5: 01 class-specific, D4-D0:00001 control function or 00010 iso endpoint)
                                              //0x21 set class-spec control function
                                              //0xA1 get class-spec control function
                        stage <= stage + 8'd1;
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch0_volume_range <= 1'b0;
                        get_ch1_volume_range <= 1'b0;
                        get_ch2_volume_range <= 1'b0;
                        get_ch0_volume_cur <= 1'b0;
                        get_ch1_volume_cur <= 1'b0;
                        get_ch2_volume_cur <= 1'b0;
                        get_mute_cur <= 1'b0;
                        get_sample_rate_range <= 1'b0;
                        get_sample_rate_cur <= 1'b0;
                        sample_rate_addr <= 16'd0;
                        set_sample_rate <= 1'b0;
                        set_clk_sel <= 1'b0;
                    end
                    8'd1 : begin
                        req_code <= usb_rxdat;//0x01:CUR 
                                              //0x02:RANGE
                                              //0x00:undefined
                        stage <= stage + 8'd1;
                    end
                    8'd2 : begin
                        //wValue LSB CN channel number
                        //0x00 channle 0
                        //0x00 channle 1
                        //0x00 channle 2
                        wValue[7:0] <= usb_rxdat;
                        stage <= stage + 8'd1;
                    end
                    8'd3 : begin
                        //wValue MSB CS control selector
                        //0x01 CS_SAM_FREQ_CONTROL
                        //0x02 FU_VOLUME_CONTROL in feature unit control selector
                        wValue[15:8] <= usb_rxdat;
                        stage <= stage + 8'd1;
                    end
                    8'd4 : begin
                        //wIndex LSB interface or Entity ID
                        //0x05 Clock Entity ID
                        //0x03 Audio Feature Control ID
                        wIndex[7:0] <= usb_rxdat;
                        stage <= stage + 8'd1;
                    end
                    8'd5 : begin
                        //wIndex MSB
                        //0x00
                        wIndex[15:8] <= usb_rxdat;
                        stage <= stage + 8'd1;
                    end
                    8'd6 : begin
                        if ((req_type == SET_REQ)&&(req_code == CUR)&&(wValue[15:8] == CS_SAM_FREQ_CONTROL)&&(wIndex[15:8]==CLOCK_SOURCE_ID)) begin
                            set_sample_rate <= 1'b1;
                        end
                        else if ((req_type == GET_REQ)&&(req_code == RANGE)&&(wValue[15:8] == CS_SAM_FREQ_CONTROL)&&(wIndex[15:8]==CLOCK_SOURCE_ID)) begin
                            get_sample_rate_range <= 1'b1;
                            sample_rate_addr <= 8'd1;
                            endpt0_dat  <= sample_rate_data[0];
                            endpt0_send <= 1'd1;
                        end
						else if ((req_type == GET_REQ )&&(req_code == CUR)&&(wValue[15:8] == AS_VAL_ALT_SETTINGS_CONTROL)&&(wValue[7:0] == 1'b0)&&(wIndex[15:8] == 1'b0)  ) begin
							get_val_alt_se <= 1'b1 ;
							endpt0_send <= 1'b1 ;
							endpt0_dat <= 8'h01 ;
						end
                        else if ((req_type == GET_REQ)&&(req_code == CUR)&&(wValue[15:8] == CS_SAM_FREQ_CONTROL)&&(wIndex[15:8]==CLOCK_SOURCE_ID)) begin
                            get_sample_rate_cur <= 1'b1;
                            endpt0_dat  <= sample_rate_cur[7:0];
                            endpt0_send <= 1'd1;
                        end
                        else if ((req_type == GET_REQ)&&(req_code == CUR)&&(wValue[15:8] == CS_CLOCK_VALID_CONTROL)&&(wIndex[15:8]==CLOCK_SOURCE_ID)) begin
                            get_clk_valid <= 1'b1;
                            endpt0_dat  <= sample_clk_valid[7:0];
                            endpt0_send <= 1'd1;
                        end
                        else if ((req_type == GET_REQ)&&(req_code == RANGE)&&(wValue[15:8] == FU_VOLUME_CONTROL)&&(wValue[7:0] == CN0)&&(wIndex[15:8]==AUDIO_CONTROL_UNIT_ID)) begin
                            get_ch0_volume_range <= 1'b1;
                            endpt0_dat  <= VOLUME_NUM[7:0];
                            endpt0_send <= 1'd1;
                        end
                        else if ((req_type == GET_REQ)&&(req_code == RANGE)&&(wValue[15:8] == FU_VOLUME_CONTROL)&&(wValue[7:0] == CN1)&&(wIndex[15:8]==AUDIO_CONTROL_UNIT_ID)) begin
                            get_ch1_volume_range <= 1'b1;
                            endpt0_dat  <= VOLUME_NUM[7:0];
                            endpt0_send <= 1'd1;
                        end
                        else if ((req_type == GET_REQ)&&(req_code == RANGE)&&(wValue[15:8] == FU_VOLUME_CONTROL)&&(wValue[7:0] == CN2)&&(wIndex[15:8]==AUDIO_CONTROL_UNIT_ID)) begin
                            get_ch2_volume_range <= 1'b1;
                            endpt0_dat  <= VOLUME_NUM[7:0];
                            endpt0_send <= 1'd1;
                        end
                        else if ((req_type == GET_REQ)&&(req_code == CUR)&&(wValue[15:8] == FU_VOLUME_CONTROL)&&(wValue[7:0] == CN0)&&(wIndex[15:8]==AUDIO_CONTROL_UNIT_ID)) begin
                            get_ch0_volume_cur <= 1'b1;
                            endpt0_dat  <= ch0_volume_cur[7:0];
                            endpt0_send <= 1'd1;
                        end
                        else if ((req_type == GET_REQ)&&(req_code == CUR)&&(wValue[15:8] == FU_VOLUME_CONTROL)&&(wValue[7:0] == CN1)&&(wIndex[15:8]==AUDIO_CONTROL_UNIT_ID)) begin
                            get_ch1_volume_cur <= 1'b1;
                            endpt0_dat  <= ch1_volume_cur[7:0];
                            endpt0_send <= 1'd1;
                        end
                        else if ((req_type == GET_REQ)&&(req_code == CUR)&&(wValue[15:8] == FU_VOLUME_CONTROL)&&(wValue[7:0] == CN2)&&(wIndex[15:8]==AUDIO_CONTROL_UNIT_ID)) begin
                            get_ch2_volume_cur <= 1'b1;
                            endpt0_dat  <= ch2_volume_cur[7:0];
                            endpt0_send <= 1'd1;
                        end
                        else if ((req_type == SET_REQ)&&(req_code == CUR)&&(wValue[15:8] == FU_VOLUME_CONTROL)&&(wValue[7:0] == CN0)&&(wIndex[15:8]==AUDIO_CONTROL_UNIT_ID)) begin
                            set_ch0_volume <= 1'b1;
                        end
                        else if ((req_type == SET_REQ)&&(req_code == CUR)&&(wValue[15:8] == FU_VOLUME_CONTROL)&&(wValue[7:0] == CN1)&&(wIndex[15:8]==AUDIO_CONTROL_UNIT_ID)) begin
                            set_ch1_volume <= 1'b1;
                        end
                        else if ((req_type == SET_REQ)&&(req_code == CUR)&&(wValue[15:8] == FU_VOLUME_CONTROL)&&(wValue[7:0] == CN2)&&(wIndex[15:8]==AUDIO_CONTROL_UNIT_ID)) begin
                            set_ch2_volume <= 1'b1;
                        end
                        else if ((req_type == GET_REQ)&&(req_code == CUR)&&(wValue[15:8] == FU_MUTE_CONTROL)&&(wIndex[15:8]==AUDIO_CONTROL_UNIT_ID)) begin
                            get_mute_cur <= 1'b1;
                            endpt0_dat  <= 8'd0;
                            endpt0_send <= 1'd1;
                        end
                        else if ((req_type == SET_REQ)&&(req_code == CUR)&&(wValue[15:8] == FU_MUTE_CONTROL)&&(wIndex[15:8]==AUDIO_CONTROL_UNIT_ID)) begin
                            set_cur_mute <= 1'b1;
                        end
                        else if ((req_type == GET_REQ)&&(req_code == CUR)&&(wValue[15:8] == CX_CLOCK_SELECTOR_CONTROL)&&(wIndex[15:8]==CLOCK_SELECTOR_ID)) begin
                            get_clk_sel <= 1'b1;
                            endpt0_dat  <= clk_sel_cur;
                            endpt0_send <= 1'd1;
                        end
                        else if ((req_type == SET_REQ)&&(req_code == CUR)&&(wValue[15:8] == CX_CLOCK_SELECTOR_CONTROL)&&(wIndex[15:8]==CLOCK_SELECTOR_ID)) begin
                            set_clk_sel <= 1'b1;
                        end
                        wLength[7:0] <= usb_rxdat;
                        stage <= stage + 8'd1;
                    end
                    8'd7 : begin
                        wLength[15:8] <= usb_rxdat;
                        stage <= stage + 8'd1;
                        sub_stage <= 8'd0;
                    end
                    8'd8 : ;
                endcase
            end
        end
        else if (set_clk_sel) begin
            if ((usb_rxact)&&(endpt_sel == 4'd0)) begin
                if (usb_rxval) begin
                    clk_sel_cur <= usb_rxdat;
                    set_clk_sel <= 1'b0;
                end
            end
        end
        else if (set_ch0_volume) begin
            if ((usb_rxact)&&(endpt_sel == 4'd0)) begin
                if (usb_rxval) begin
                    sub_stage <= sub_stage + 8'd1;
                    if (sub_stage == 0) begin
                        ch1_volume_cur[7:0] <= usb_rxdat;
                        ch2_volume_cur[7:0] <= usb_rxdat;
                    end
                    else if (sub_stage == 1) begin
                        ch1_volume_cur[15:8] <= usb_rxdat;
                        ch2_volume_cur[15:8] <= usb_rxdat;
                        sub_stage <= 8'd0;
                        set_ch0_volume <= 1'b0;
                    end
                end
            end
        end
        else if (set_ch1_volume) begin
            if ((usb_rxact)&&(endpt_sel == 4'd0)) begin
                if (usb_rxval) begin
                    sub_stage <= sub_stage + 8'd1;
                    if (sub_stage == 0) begin
                        ch1_volume_cur[7:0] <= usb_rxdat;
                    end
                    else if (sub_stage == 1) begin
                        ch1_volume_cur[15:8] <= usb_rxdat;
                        sub_stage <= 8'd0;
                        set_ch1_volume <= 1'b0;
                    end
                end
            end
        end
        else if (set_ch2_volume) begin
            if ((usb_rxact)&&(endpt_sel == 4'd0)) begin
                if (usb_rxval) begin
                    sub_stage <= sub_stage + 8'd1;
                    if (sub_stage == 0) begin
                        ch2_volume_cur[7:0] <= usb_rxdat;
                    end
                    else if (sub_stage == 1) begin
                        ch2_volume_cur[15:8] <= usb_rxdat;
                        sub_stage <= 8'd0;
                        set_ch2_volume <= 1'b0;
                    end
                end
            end
        end
        else if (set_cur_mute) begin
            if ((usb_rxact)&&(endpt_sel == 4'd0)) begin
                if (usb_rxval) begin
                    if (sub_stage == 0) begin
                        mute_cur <= usb_rxdat[0];
                        sub_stage <= 8'd0;
                        set_cur_mute <= 1'd0;
                    end
                end
            end
        end
        else if (set_sample_rate) begin
            stage <= 8'd0;
            if ((usb_rxact)&&(endpt_sel == 4'd0)) begin
                if (usb_rxval) begin
                    sub_stage <= sub_stage + 8'd1;
                    if (sub_stage == 0) begin
                        sample_rate_cur[7:0] <= usb_rxdat;
                    end
                    else if (sub_stage == 1) begin
                        sample_rate_cur[15:8] <= usb_rxdat;
                    end
                    else if (sub_stage == 2) begin
                        sample_rate_cur[23:16] <= usb_rxdat;
                    end
                    else if (sub_stage == 3) begin
                        sample_rate_cur[31:24] <= usb_rxdat;
                        sub_stage <= 8'd0;
                        set_sample_rate <= 1'b0;
                    end
                end
            end
        end
        else if (get_ch0_volume_range) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    if (sub_stage + 1 >= wLength) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch0_volume_range <= 1'd0;
                    end
                    else if (sub_stage <= 0) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_NUM[15:8];
                    end
                    else if (sub_stage == 1) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_HS_MIN[7:0];
                    end
                    else if (sub_stage == 2) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_HS_MIN[15:8];
                    end
                    else if (sub_stage == 3) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_HS_MAX[7:0];
                    end
                    else if (sub_stage == 4) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_HS_MAX[15:8];
                    end
                    else if (sub_stage == 5) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_HS_RES[7:0];
                    end
                    else if (sub_stage == 6) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_HS_RES[15:8];
                    end
                    else if (sub_stage == 7) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch0_volume_range <= 1'd0;
                    end
                end
            end
        end
        else if (get_ch1_volume_range) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    if (sub_stage + 1 >= wLength) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch1_volume_range <= 1'd0;
                    end
                    else if (sub_stage <= 0) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_NUM[15:8];
                    end
                    else if (sub_stage == 1) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_HS_MIN[7:0];
                    end
                    else if (sub_stage == 2) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_HS_MIN[15:8];
                    end
                    else if (sub_stage == 3) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_HS_MAX[7:0];
                    end
                    else if (sub_stage == 4) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_HS_MAX[15:8];
                    end
                    else if (sub_stage == 5) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_HS_RES[7:0];
                    end
                    else if (sub_stage == 6) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_HS_RES[15:8];
                    end
                    else if (sub_stage == 7) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch0_volume_range <= 1'd0;
                    end
                end
            end
        end
        else if (get_ch2_volume_range) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    if (sub_stage + 1 >= wLength) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch2_volume_range <= 1'd0;
                    end
                    else if (sub_stage <= 0) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_NUM[15:8];
                    end
                    else if (sub_stage == 1) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_HS_MIN[7:0];
                    end
                    else if (sub_stage == 2) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_HS_MIN[15:8];
                    end
                    else if (sub_stage == 3) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_HS_MAX[7:0];
                    end
                    else if (sub_stage == 4) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_HS_MAX[15:8];
                    end
                    else if (sub_stage == 5) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_HS_RES[7:0];
                    end
                    else if (sub_stage == 6) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_HS_RES[15:8];
                    end
                    else if (sub_stage == 7) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch2_volume_range <= 1'd0;
                    end
                end
            end
        end
        else if (get_ch0_volume_cur) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    if (sub_stage + 1 >= wLength) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch0_volume_cur <= 1'd0;
                    end
                    else if (sub_stage <= 0) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= ch0_volume_cur[15:8];
                    end
                    else if (sub_stage == 1) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch0_volume_cur <= 1'd0;
                    end
                end
            end
        end
        else if (get_ch1_volume_cur) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    if (sub_stage + 1 >= wLength) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch1_volume_cur <= 1'd0;
                    end
                    else if (sub_stage <= 0) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= ch1_volume_cur[15:8];
                    end
                    else if (sub_stage == 1) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch1_volume_cur <= 1'd0;
                    end
                end
            end
        end
        else if (get_ch2_volume_cur) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    if (sub_stage + 1 >= wLength) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch2_volume_cur <= 1'd0;
                    end
                    else if (sub_stage <= 0) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= ch2_volume_cur[15:8];
                    end
                    else if (sub_stage == 1) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_ch2_volume_cur <= 1'd0;
                    end
                end
            end
        end
        else if (get_mute_cur) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    sub_stage <= 8'd0;
                    endpt0_send <= 1'd0;
                    get_mute_cur <= 1'd0;
                end
            end
        end
        else if (get_clk_valid) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    sub_stage <= 8'd0;
                    endpt0_send <= 1'd0;
                    get_clk_valid <= 1'd0;
                end
            end
        end
        else if (get_sample_rate_cur) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    if (sub_stage + 1 >= wLength) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_sample_rate_cur <= 1'd0;
                    end
                    else if (sub_stage <= 0) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= sample_rate_cur[15:8];
                    end
                    else if (sub_stage == 1) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= sample_rate_cur[23:16];
                    end
                    else if (sub_stage == 2) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= sample_rate_cur[31:24];
                    end
                    else if (sub_stage == 3) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_sample_rate_cur <= 1'd0;
                    end
                end
            end
        end
        else if (get_cur_mute) begin
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    sub_stage <= 8'd0;
                    endpt0_send <= 1'd0;
                    get_cur_mute <= 1'd0;
                end
            end
        end
        else if (get_cur_volume) begin
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    if (sub_stage + 1 >= wLength) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_cur_volume <= 1'd0;
                    end
                    else if (sub_stage <= 0) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= ch1_volume_cur[15:8];
                    end
                    else if (sub_stage == 1) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_cur_volume <= 1'd0;
                    end
                end
            end
        end
        else if (get_min_volume) begin
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    if (sub_stage + 1 >= wLength) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_min_volume <= 1'd0;
                    end
                    else if (sub_stage <= 0) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_FS_MIN[15:8];
                    end
                    else if (sub_stage == 1) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_min_volume <= 1'd0;
                    end
                end
            end
        end
        else if (get_max_volume) begin
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    if (sub_stage + 1 >= wLength) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_max_volume <= 1'd0;
                    end
                    else if (sub_stage <= 0) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_FS_MAX[15:8];
                    end
                    else if (sub_stage == 1) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_max_volume <= 1'd0;
                    end
                end
            end
        end
        else if (get_res_volume) begin
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    if (sub_stage + 1 >= wLength) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_res_volume <= 1'd0;
                    end
                    else if (sub_stage <= 0) begin
                        sub_stage <= sub_stage + 1'b1;
                        endpt0_dat <= VOLUME_FS_RES[15:8];
                    end
                    else if (sub_stage == 1) begin
                        sub_stage <= 8'd0;
                        endpt0_send <= 1'd0;
                        get_res_volume <= 1'd0;
                    end
                end
            end
        end
        else if (get_sample_rate_range) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    if (sample_rate_addr  >= wLength) begin
                        endpt0_dat <= 8'h00;
                        endpt0_send <= 1'd0;
                        sample_rate_addr <= 8'd0;
                        sub_stage <= 0;
                        get_sample_rate_range<=1'b0;
                    end
                    else if (sub_stage == 0) begin
                        if (sample_rate_addr >= 64) begin
                            endpt0_dat <= sample_rate_data[sample_rate_addr];
                            sample_rate_addr <= sample_rate_addr + 8'd1;
                            endpt0_send <= 1'd0;
                            sub_stage <= 1;
                        end
                        else begin
                            sample_rate_addr <= sample_rate_addr + 8'd1;
                            endpt0_dat <= sample_rate_data[sample_rate_addr];
                        end
                    end
                    else if (sub_stage == 1) begin
                        if (sample_rate_addr >= 128) begin
                            endpt0_dat <= 8'h00;
                            endpt0_send <= 1'd0;
                            sample_rate_addr <= sample_rate_addr + 8'd1;
                            sub_stage <= 2;
                        end
                        else begin
                            sample_rate_addr <= sample_rate_addr + 8'd1;
                            endpt0_dat <= sample_rate_data[sample_rate_addr];
                        end
                    end
                    else if (sub_stage == 2) begin
                        if (sample_rate_addr >= 158) begin
                            endpt0_dat <= 8'h00;
                            endpt0_send <= 1'd0;
                            sample_rate_addr <= 8'd0;
                            sub_stage <= 0;
                        end
                        else begin
                            sample_rate_addr <= sample_rate_addr + 8'd1;
                            endpt0_dat <= sample_rate_data[sample_rate_addr];
                        end
                    end
                end
            end
            else begin
                if (sub_stage == 0) begin
                    endpt0_send <= 1'd1;
                end
                else if (sub_stage == 1) begin
                    endpt0_send <= 1'd1;
                end
                else if (sub_stage == 2) begin
                    endpt0_send <= 1'd1;
                end
                else if (sub_stage == 3) begin
                    endpt0_send <= 1'd1;
                end
            end
        end
        else if (get_clk_sel) begin
            stage <= 8'd0;
            if ((usb_txact)&&(endpt_sel == 4'd0)) begin
                if (usb_txpop) begin
                    endpt0_send <= 1'd0;
                    get_clk_sel <= 1'b0;
                end
            end
        end
		else if ( get_val_alt_se ) begin
			stage <= 1'b0 ;
			if ((usb_txact)&&(endpt_sel == 4'd0 ))begin
				if(usb_txpop) begin
					if ( sub_stage == 1'b1 ) begin						
						sub_stage <= 1'b0 ;
						endpt0_send <= 1'b0;
						get_val_alt_se <= 1'b0 ;
					end
					else begin
						sub_stage <= sub_stage + 1'b1 ;
						case( wIndex[7:0] )
						10'd0: endpt0_dat <= 8'b0000_0001;
						10'd1: endpt0_dat <= 8'b0000_1111;
						10'd2: endpt0_dat <= 8'b0000_1111;
						default : endpt0_dat <= 8'b0000_0000;
						endcase
					end	
				end
			end
		end
        else begin
            stage <= 8'd0;
            sub_stage <= 8'd0;
        end
    end
end

always @(posedge PHY_CLKOUT,posedge RESET) begin
    if (RESET) begin
        sample_rate_data[0]      <= 8'h0D;
        sample_rate_data[1]      <= 8'h00;
        sample_rate_data[2 +  0] <= SAMPLE_RATE_32[7:0];
        sample_rate_data[2 +  1] <= SAMPLE_RATE_32[15:8];
        sample_rate_data[2 +  2] <= SAMPLE_RATE_32[23:16];
        sample_rate_data[2 +  3] <= SAMPLE_RATE_32[31:24];
        sample_rate_data[2 +  4] <= SAMPLE_RATE_32[7:0];
        sample_rate_data[2 +  5] <= SAMPLE_RATE_32[15:8];
        sample_rate_data[2 +  6] <= SAMPLE_RATE_32[23:16];
        sample_rate_data[2 +  7] <= SAMPLE_RATE_32[31:24];
        sample_rate_data[2 +  8] <= 0;
        sample_rate_data[2 +  9] <= 0;
        sample_rate_data[2 + 10] <= 0;
        sample_rate_data[2 + 11] <= 0;
        sample_rate_data[14 +  0] <= SAMPLE_RATE_44_1[7:0];
        sample_rate_data[14 +  1] <= SAMPLE_RATE_44_1[15:8];
        sample_rate_data[14 +  2] <= SAMPLE_RATE_44_1[23:16];
        sample_rate_data[14 +  3] <= SAMPLE_RATE_44_1[31:24];
        sample_rate_data[14 +  4] <= SAMPLE_RATE_44_1[7:0];
        sample_rate_data[14 +  5] <= SAMPLE_RATE_44_1[15:8];
        sample_rate_data[14 +  6] <= SAMPLE_RATE_44_1[23:16];
        sample_rate_data[14 +  7] <= SAMPLE_RATE_44_1[31:24];
        sample_rate_data[14 +  8] <= 0;
        sample_rate_data[14 +  9] <= 0;
        sample_rate_data[14 + 10] <= 0;
        sample_rate_data[14 + 11] <= 0;
        sample_rate_data[26 +  0] <= SAMPLE_RATE_48[7:0];
        sample_rate_data[26 +  1] <= SAMPLE_RATE_48[15:8];
        sample_rate_data[26 +  2] <= SAMPLE_RATE_48[23:16];
        sample_rate_data[26 +  3] <= SAMPLE_RATE_48[31:24];
        sample_rate_data[26 +  4] <= SAMPLE_RATE_48[7:0];
        sample_rate_data[26 +  5] <= SAMPLE_RATE_48[15:8];
        sample_rate_data[26 +  6] <= SAMPLE_RATE_48[23:16];
        sample_rate_data[26 +  7] <= SAMPLE_RATE_48[31:24];
        sample_rate_data[26 +  8] <= 0;
        sample_rate_data[26 +  9] <= 0;
        sample_rate_data[26 + 10] <= 0;
        sample_rate_data[26 + 11] <= 0;
        sample_rate_data[38 +  0] <= SAMPLE_RATE_64[7:0];
        sample_rate_data[38 +  1] <= SAMPLE_RATE_64[15:8];
        sample_rate_data[38 +  2] <= SAMPLE_RATE_64[23:16];
        sample_rate_data[38 +  3] <= SAMPLE_RATE_64[31:24];
        sample_rate_data[38 +  4] <= SAMPLE_RATE_64[7:0];
        sample_rate_data[38 +  5] <= SAMPLE_RATE_64[15:8];
        sample_rate_data[38 +  6] <= SAMPLE_RATE_64[23:16];
        sample_rate_data[38 +  7] <= SAMPLE_RATE_64[31:24];
        sample_rate_data[38 +  8] <= 0;
        sample_rate_data[38 +  9] <= 0;
        sample_rate_data[38 + 10] <= 0;
        sample_rate_data[38 + 11] <= 0;
        sample_rate_data[50 +  0] <= SAMPLE_RATE_88_2[7:0];
        sample_rate_data[50 +  1] <= SAMPLE_RATE_88_2[15:8];
        sample_rate_data[50 +  2] <= SAMPLE_RATE_88_2[23:16];
        sample_rate_data[50 +  3] <= SAMPLE_RATE_88_2[31:24];
        sample_rate_data[50 +  4] <= SAMPLE_RATE_88_2[7:0];
        sample_rate_data[50 +  5] <= SAMPLE_RATE_88_2[15:8];
        sample_rate_data[50 +  6] <= SAMPLE_RATE_88_2[23:16];
        sample_rate_data[50 +  7] <= SAMPLE_RATE_88_2[31:24];
        sample_rate_data[50 +  8] <= 0;
        sample_rate_data[50 +  9] <= 0;
        sample_rate_data[50 + 10] <= 0;
        sample_rate_data[50 + 11] <= 0;
        sample_rate_data[62 +  0] <= SAMPLE_RATE_96[7:0];
        sample_rate_data[62 +  1] <= SAMPLE_RATE_96[15:8];
        sample_rate_data[62 +  2] <= SAMPLE_RATE_96[23:16];
        sample_rate_data[62 +  3] <= SAMPLE_RATE_96[31:24];
        sample_rate_data[62 +  4] <= SAMPLE_RATE_96[7:0];
        sample_rate_data[62 +  5] <= SAMPLE_RATE_96[15:8];
        sample_rate_data[62 +  6] <= SAMPLE_RATE_96[23:16];
        sample_rate_data[62 +  7] <= SAMPLE_RATE_96[31:24];
        sample_rate_data[62 +  8] <= 0;
        sample_rate_data[62 +  9] <= 0;
        sample_rate_data[62 + 10] <= 0;
        sample_rate_data[62 + 11] <= 0;
        sample_rate_data[74 +  0]<= SAMPLE_RATE_128[7:0];
        sample_rate_data[74 +  1]<= SAMPLE_RATE_128[15:8];
        sample_rate_data[74 +  2]<= SAMPLE_RATE_128[23:16];
        sample_rate_data[74 +  3]<= SAMPLE_RATE_128[31:24];
        sample_rate_data[74 +  4]<= SAMPLE_RATE_128[7:0];
        sample_rate_data[74 +  5]<= SAMPLE_RATE_128[15:8];
        sample_rate_data[74 +  6]<= SAMPLE_RATE_128[23:16];
        sample_rate_data[74 +  7]<= SAMPLE_RATE_128[31:24];
        sample_rate_data[74 +  8] <= 0;
        sample_rate_data[74 +  9] <= 0;
        sample_rate_data[74 + 10] <= 0;
        sample_rate_data[74 + 11] <= 0;
        sample_rate_data[86 +  0] <= SAMPLE_RATE_176_4[7:0];
        sample_rate_data[86 +  1] <= SAMPLE_RATE_176_4[15:8];
        sample_rate_data[86 +  2] <= SAMPLE_RATE_176_4[23:16];
        sample_rate_data[86 +  3] <= SAMPLE_RATE_176_4[31:24];
        sample_rate_data[86 +  4] <= SAMPLE_RATE_176_4[7:0];
        sample_rate_data[86 +  5] <= SAMPLE_RATE_176_4[15:8];
        sample_rate_data[86 +  6] <= SAMPLE_RATE_176_4[23:16];
        sample_rate_data[86 +  7] <= SAMPLE_RATE_176_4[31:24];
        sample_rate_data[86 +  8] <= 0;
        sample_rate_data[86 +  9] <= 0;
        sample_rate_data[86 + 10] <= 0;
        sample_rate_data[86 + 11] <= 0;
        sample_rate_data[98 +  0] <= SAMPLE_RATE_192[7:0];
        sample_rate_data[98 +  1] <= SAMPLE_RATE_192[15:8];
        sample_rate_data[98 +  2] <= SAMPLE_RATE_192[23:16];
        sample_rate_data[98 +  3] <= SAMPLE_RATE_192[31:24];
        sample_rate_data[98 +  4] <= SAMPLE_RATE_192[7:0];
        sample_rate_data[98 +  5] <= SAMPLE_RATE_192[15:8];
        sample_rate_data[98 +  6] <= SAMPLE_RATE_192[23:16];
        sample_rate_data[98 +  7] <= SAMPLE_RATE_192[31:24];
        sample_rate_data[98 +  8] <= 0;
        sample_rate_data[98 +  9] <= 0;
        sample_rate_data[98 + 10] <= 0;
        sample_rate_data[98 + 11] <= 0;
        sample_rate_data[110 +  0] <= SAMPLE_RATE_352_8[7:0];
        sample_rate_data[110 +  1] <= SAMPLE_RATE_352_8[15:8];
        sample_rate_data[110 +  2] <= SAMPLE_RATE_352_8[23:16];
        sample_rate_data[110 +  3] <= SAMPLE_RATE_352_8[31:24];
        sample_rate_data[110 +  4] <= SAMPLE_RATE_352_8[7:0];
        sample_rate_data[110 +  5] <= SAMPLE_RATE_352_8[15:8];
        sample_rate_data[110 +  6] <= SAMPLE_RATE_352_8[23:16];
        sample_rate_data[110 +  7] <= SAMPLE_RATE_352_8[31:24];
        sample_rate_data[110 +  8] <= 0;
        sample_rate_data[110 +  9] <= 0;
        sample_rate_data[110 + 10] <= 0;
        sample_rate_data[110 + 11] <= 0;
        sample_rate_data[122 +  0] <= SAMPLE_RATE_384[7:0];
        sample_rate_data[122 +  1] <= SAMPLE_RATE_384[15:8];
        sample_rate_data[122 +  2] <= SAMPLE_RATE_384[23:16];
        sample_rate_data[122 +  3] <= SAMPLE_RATE_384[31:24];
        sample_rate_data[122 +  4] <= SAMPLE_RATE_384[7:0];
        sample_rate_data[122 +  5] <= SAMPLE_RATE_384[15:8];
        sample_rate_data[122 +  6] <= SAMPLE_RATE_384[23:16];
        sample_rate_data[122 +  7] <= SAMPLE_RATE_384[31:24];
        sample_rate_data[122 +  8] <= 0;
        sample_rate_data[122 +  9] <= 0;
        sample_rate_data[122 + 10] <= 0;
        sample_rate_data[122 + 11] <= 0;
        sample_rate_data[134 +  0] <= SAMPLE_RATE_705_6[7:0];
        sample_rate_data[134 +  1] <= SAMPLE_RATE_705_6[15:8];
        sample_rate_data[134 +  2] <= SAMPLE_RATE_705_6[23:16];
        sample_rate_data[134 +  3] <= SAMPLE_RATE_705_6[31:24];
        sample_rate_data[134 +  4] <= SAMPLE_RATE_705_6[7:0];
        sample_rate_data[134 +  5] <= SAMPLE_RATE_705_6[15:8];
        sample_rate_data[134 +  6] <= SAMPLE_RATE_705_6[23:16];
        sample_rate_data[134 +  7] <= SAMPLE_RATE_705_6[31:24];
        sample_rate_data[134 +  8] <= 0;
        sample_rate_data[134 +  9] <= 0;
        sample_rate_data[134 + 10] <= 0;
        sample_rate_data[134 + 11] <= 0;
        sample_rate_data[146 +  0] <= SAMPLE_RATE_768[7:0];
        sample_rate_data[146 +  1] <= SAMPLE_RATE_768[15:8];
        sample_rate_data[146 +  2] <= SAMPLE_RATE_768[23:16];
        sample_rate_data[146 +  3] <= SAMPLE_RATE_768[31:24];
        sample_rate_data[146 +  4] <= SAMPLE_RATE_768[7:0];
        sample_rate_data[146 +  5] <= SAMPLE_RATE_768[15:8];
        sample_rate_data[146 +  6] <= SAMPLE_RATE_768[23:16];
        sample_rate_data[146 +  7] <= SAMPLE_RATE_768[31:24];
        sample_rate_data[146 +  8] <= 0;
        sample_rate_data[146 +  9] <= 0;
        sample_rate_data[146 + 10] <= 0;
        sample_rate_data[146 + 11] <= 0;
    end
    //else if (usb_highspeed) begin
    else begin
        sample_rate_data[0]     <= 8'h0D;
        sample_rate_data[1]     <= 8'h00;
        sample_rate_data[2 +  0]<= SAMPLE_RATE_32[7:0];
        sample_rate_data[2 +  1]<= SAMPLE_RATE_32[15:8];
        sample_rate_data[2 +  2]<= SAMPLE_RATE_32[23:16];
        sample_rate_data[2 +  3]<= SAMPLE_RATE_32[31:24];
        sample_rate_data[2 +  4]<= SAMPLE_RATE_32[7:0];
        sample_rate_data[2 +  5]<= SAMPLE_RATE_32[15:8];
        sample_rate_data[2 +  6]<= SAMPLE_RATE_32[23:16];
        sample_rate_data[2 +  7]<= SAMPLE_RATE_32[31:24];
        sample_rate_data[2 +  8] <= 0;
        sample_rate_data[2 +  9] <= 0;
        sample_rate_data[2 + 10] <= 0;
        sample_rate_data[2 + 11] <= 0;
        sample_rate_data[14 +  0] <= SAMPLE_RATE_44_1[7:0];
        sample_rate_data[14 +  1] <= SAMPLE_RATE_44_1[15:8];
        sample_rate_data[14 +  2] <= SAMPLE_RATE_44_1[23:16];
        sample_rate_data[14 +  3] <= SAMPLE_RATE_44_1[31:24];
        sample_rate_data[14 +  4] <= SAMPLE_RATE_44_1[7:0];
        sample_rate_data[14 +  5] <= SAMPLE_RATE_44_1[15:8];
        sample_rate_data[14 +  6] <= SAMPLE_RATE_44_1[23:16];
        sample_rate_data[14 +  7] <= SAMPLE_RATE_44_1[31:24];
        sample_rate_data[14 +  8] <= 0;
        sample_rate_data[14 +  9] <= 0;
        sample_rate_data[14 + 10] <= 0;
        sample_rate_data[14 + 11] <= 0;
        sample_rate_data[26 +  0] <= SAMPLE_RATE_48[7:0];
        sample_rate_data[26 +  1] <= SAMPLE_RATE_48[15:8];
        sample_rate_data[26 +  2] <= SAMPLE_RATE_48[23:16];
        sample_rate_data[26 +  3] <= SAMPLE_RATE_48[31:24];
        sample_rate_data[26 +  4] <= SAMPLE_RATE_48[7:0];
        sample_rate_data[26 +  5] <= SAMPLE_RATE_48[15:8];
        sample_rate_data[26 +  6] <= SAMPLE_RATE_48[23:16];
        sample_rate_data[26 +  7] <= SAMPLE_RATE_48[31:24];
        sample_rate_data[26 +  8] <= 0;
        sample_rate_data[26 +  9] <= 0;
        sample_rate_data[26 + 10] <= 0;
        sample_rate_data[26 + 11] <= 0;
        sample_rate_data[38 +  0] <= SAMPLE_RATE_64[7:0];
        sample_rate_data[38 +  1] <= SAMPLE_RATE_64[15:8];
        sample_rate_data[38 +  2] <= SAMPLE_RATE_64[23:16];
        sample_rate_data[38 +  3] <= SAMPLE_RATE_64[31:24];
        sample_rate_data[38 +  4] <= SAMPLE_RATE_64[7:0];
        sample_rate_data[38 +  5] <= SAMPLE_RATE_64[15:8];
        sample_rate_data[38 +  6] <= SAMPLE_RATE_64[23:16];
        sample_rate_data[38 +  7] <= SAMPLE_RATE_64[31:24];
        sample_rate_data[38 +  8] <= 0;
        sample_rate_data[38 +  9] <= 0;
        sample_rate_data[38 + 10] <= 0;
        sample_rate_data[38 + 11] <= 0;
        sample_rate_data[50 +  0] <= SAMPLE_RATE_88_2[7:0];
        sample_rate_data[50 +  1] <= SAMPLE_RATE_88_2[15:8];
        sample_rate_data[50 +  2] <= SAMPLE_RATE_88_2[23:16];
        sample_rate_data[50 +  3] <= SAMPLE_RATE_88_2[31:24];
        sample_rate_data[50 +  4] <= SAMPLE_RATE_88_2[7:0];
        sample_rate_data[50 +  5] <= SAMPLE_RATE_88_2[15:8];
        sample_rate_data[50 +  6] <= SAMPLE_RATE_88_2[23:16];
        sample_rate_data[50 +  7] <= SAMPLE_RATE_88_2[31:24];
        sample_rate_data[50 +  8] <= 0;
        sample_rate_data[50 +  9] <= 0;
        sample_rate_data[50 + 10] <= 0;
        sample_rate_data[50 + 11] <= 0;
        sample_rate_data[62 +  0] <= SAMPLE_RATE_96[7:0];
        sample_rate_data[62 +  1] <= SAMPLE_RATE_96[15:8];
        sample_rate_data[62 +  2] <= SAMPLE_RATE_96[23:16];
        sample_rate_data[62 +  3] <= SAMPLE_RATE_96[31:24];
        sample_rate_data[62 +  4] <= SAMPLE_RATE_96[7:0];
        sample_rate_data[62 +  5] <= SAMPLE_RATE_96[15:8];
        sample_rate_data[62 +  6] <= SAMPLE_RATE_96[23:16];
        sample_rate_data[62 +  7] <= SAMPLE_RATE_96[31:24];
        sample_rate_data[62 +  8] <= 0;
        sample_rate_data[62 +  9] <= 0;
        sample_rate_data[62 + 10] <= 0;
        sample_rate_data[62 + 11] <= 0;
        sample_rate_data[74 +  0]<= SAMPLE_RATE_128[7:0];
        sample_rate_data[74 +  1]<= SAMPLE_RATE_128[15:8];
        sample_rate_data[74 +  2]<= SAMPLE_RATE_128[23:16];
        sample_rate_data[74 +  3]<= SAMPLE_RATE_128[31:24];
        sample_rate_data[74 +  4]<= SAMPLE_RATE_128[7:0];
        sample_rate_data[74 +  5]<= SAMPLE_RATE_128[15:8];
        sample_rate_data[74 +  6]<= SAMPLE_RATE_128[23:16];
        sample_rate_data[74 +  7]<= SAMPLE_RATE_128[31:24];
        sample_rate_data[74 +  8] <= 0;
        sample_rate_data[74 +  9] <= 0;
        sample_rate_data[74 + 10] <= 0;
        sample_rate_data[74 + 11] <= 0;
        sample_rate_data[86 +  0] <= SAMPLE_RATE_176_4[7:0];
        sample_rate_data[86 +  1] <= SAMPLE_RATE_176_4[15:8];
        sample_rate_data[86 +  2] <= SAMPLE_RATE_176_4[23:16];
        sample_rate_data[86 +  3] <= SAMPLE_RATE_176_4[31:24];
        sample_rate_data[86 +  4] <= SAMPLE_RATE_176_4[7:0];
        sample_rate_data[86 +  5] <= SAMPLE_RATE_176_4[15:8];
        sample_rate_data[86 +  6] <= SAMPLE_RATE_176_4[23:16];
        sample_rate_data[86 +  7] <= SAMPLE_RATE_176_4[31:24];
        sample_rate_data[86 +  8] <= 0;
        sample_rate_data[86 +  9] <= 0;
        sample_rate_data[86 + 10] <= 0;
        sample_rate_data[86 + 11] <= 0;
        sample_rate_data[98 +  0] <= SAMPLE_RATE_192[7:0];
        sample_rate_data[98 +  1] <= SAMPLE_RATE_192[15:8];
        sample_rate_data[98 +  2] <= SAMPLE_RATE_192[23:16];
        sample_rate_data[98 +  3] <= SAMPLE_RATE_192[31:24];
        sample_rate_data[98 +  4] <= SAMPLE_RATE_192[7:0];
        sample_rate_data[98 +  5] <= SAMPLE_RATE_192[15:8];
        sample_rate_data[98 +  6] <= SAMPLE_RATE_192[23:16];
        sample_rate_data[98 +  7] <= SAMPLE_RATE_192[31:24];
        sample_rate_data[98 +  8] <= 0;
        sample_rate_data[98 +  9] <= 0;
        sample_rate_data[98 + 10] <= 0;
        sample_rate_data[98 + 11] <= 0;
        sample_rate_data[110 +  0] <= SAMPLE_RATE_352_8[7:0];
        sample_rate_data[110 +  1] <= SAMPLE_RATE_352_8[15:8];
        sample_rate_data[110 +  2] <= SAMPLE_RATE_352_8[23:16];
        sample_rate_data[110 +  3] <= SAMPLE_RATE_352_8[31:24];
        sample_rate_data[110 +  4] <= SAMPLE_RATE_352_8[7:0];
        sample_rate_data[110 +  5] <= SAMPLE_RATE_352_8[15:8];
        sample_rate_data[110 +  6] <= SAMPLE_RATE_352_8[23:16];
        sample_rate_data[110 +  7] <= SAMPLE_RATE_352_8[31:24];
        sample_rate_data[110 +  8] <= 0;
        sample_rate_data[110 +  9] <= 0;
        sample_rate_data[110 + 10] <= 0;
        sample_rate_data[110 + 11] <= 0;
        sample_rate_data[122 +  0] <= SAMPLE_RATE_384[7:0];
        sample_rate_data[122 +  1] <= SAMPLE_RATE_384[15:8];
        sample_rate_data[122 +  2] <= SAMPLE_RATE_384[23:16];
        sample_rate_data[122 +  3] <= SAMPLE_RATE_384[31:24];
        sample_rate_data[122 +  4] <= SAMPLE_RATE_384[7:0];
        sample_rate_data[122 +  5] <= SAMPLE_RATE_384[15:8];
        sample_rate_data[122 +  6] <= SAMPLE_RATE_384[23:16];
        sample_rate_data[122 +  7] <= SAMPLE_RATE_384[31:24];
        sample_rate_data[122 +  8] <= 0;
        sample_rate_data[122 +  9] <= 0;
        sample_rate_data[122 + 10] <= 0;
        sample_rate_data[122 + 11] <= 0;
        sample_rate_data[134 +  0] <= SAMPLE_RATE_705_6[7:0];
        sample_rate_data[134 +  1] <= SAMPLE_RATE_705_6[15:8];
        sample_rate_data[134 +  2] <= SAMPLE_RATE_705_6[23:16];
        sample_rate_data[134 +  3] <= SAMPLE_RATE_705_6[31:24];
        sample_rate_data[134 +  4] <= SAMPLE_RATE_705_6[7:0];
        sample_rate_data[134 +  5] <= SAMPLE_RATE_705_6[15:8];
        sample_rate_data[134 +  6] <= SAMPLE_RATE_705_6[23:16];
        sample_rate_data[134 +  7] <= SAMPLE_RATE_705_6[31:24];
        sample_rate_data[134 +  8] <= 0;
        sample_rate_data[134 +  9] <= 0;
        sample_rate_data[134 + 10] <= 0;
        sample_rate_data[134 + 11] <= 0;
        sample_rate_data[146 +  0] <= SAMPLE_RATE_768[7:0];
        sample_rate_data[146 +  1] <= SAMPLE_RATE_768[15:8];
        sample_rate_data[146 +  2] <= SAMPLE_RATE_768[23:16];
        sample_rate_data[146 +  3] <= SAMPLE_RATE_768[31:24];
        sample_rate_data[146 +  4] <= SAMPLE_RATE_768[7:0];
        sample_rate_data[146 +  5] <= SAMPLE_RATE_768[15:8];
        sample_rate_data[146 +  6] <= SAMPLE_RATE_768[23:16];
        sample_rate_data[146 +  7] <= SAMPLE_RATE_768[31:24];
        sample_rate_data[146 +  8] <= 0;
        sample_rate_data[146 +  9] <= 0;
        sample_rate_data[146 + 10] <= 0;
        sample_rate_data[146 + 11] <= 0;
    end
    //else begin
    //    sample_rate_data[0]     <= 8'h02;
    //    sample_rate_data[1]     <= 8'h00;
    //    sample_rate_data[2 +  0] <= SAMPLE_RATE_44_1[7:0];
    //    sample_rate_data[2 +  1] <= SAMPLE_RATE_44_1[15:8];
    //    sample_rate_data[2 +  2] <= SAMPLE_RATE_44_1[23:16];
    //    sample_rate_data[2 +  3] <= SAMPLE_RATE_44_1[31:24];
    //    sample_rate_data[2 +  4] <= SAMPLE_RATE_44_1[7:0];
    //    sample_rate_data[2 +  5] <= SAMPLE_RATE_44_1[15:8];
    //    sample_rate_data[2 +  6] <= SAMPLE_RATE_44_1[23:16];
    //    sample_rate_data[2 +  7] <= SAMPLE_RATE_44_1[31:24];
    //    sample_rate_data[2 +  8] <= 0;
    //    sample_rate_data[2 +  9] <= 0;
    //    sample_rate_data[2 + 10] <= 0;
    //    sample_rate_data[2 + 11] <= 0;
    //    sample_rate_data[14 +  0] <= SAMPLE_RATE_48[7:0];
    //    sample_rate_data[14 +  1] <= SAMPLE_RATE_48[15:8];
    //    sample_rate_data[14 +  2] <= SAMPLE_RATE_48[23:16];
    //    sample_rate_data[14 +  3] <= SAMPLE_RATE_48[31:24];
    //    sample_rate_data[14 +  4] <= SAMPLE_RATE_48[7:0];
    //    sample_rate_data[14 +  5] <= SAMPLE_RATE_48[15:8];
    //    sample_rate_data[14 +  6] <= SAMPLE_RATE_48[23:16];
    //    sample_rate_data[14 +  7] <= SAMPLE_RATE_48[31:24];
    //    sample_rate_data[14 +  8] <= 0;
    //    sample_rate_data[14 +  9] <= 0;
    //    sample_rate_data[14 + 10] <= 0;
    //    sample_rate_data[14 + 11] <= 0;
    //end
end



//==============================================================
//======Tx Cork
assign usb_txdat_len = (endpt_sel == AUDIO_IT_FB_ENDPOINT[3:0]) ? 12'd4 : 12'd8;
//-------------------------------------------------------------
//Comment:Audio Feedback Endpoint
//-------------------------------------------------------------
//98.304M/2 = 49.152
//Sample Rate 48  96  192 384 768
//K           13  13  13  13  13
//P           11  10  9   8   7
//P-1         10  9   8   7   6
//K-P         2   3   4   5   6
//K-P+1       3   4   5   6   7
//2^(K-P)     8   16  32  60  128
//98.304M/3 = 32.768
//Sample Rate 32  64  128
//K           13  13  13
//P           10  9   8
//K-P         3   4   5
//2^(K-P)     8   16  32
//90.3168M/2 = 45.1584
//Sample Rate 44.1 88.2 178.4 352.8 705.6
//K           13   13   13    13    13
//P           10   9    8     7     6
//K-P         3    4    5     6     7
//2^(K-P)     8    16   32    60    128
//==============================================================
//======
assign  ff_period = (sample_rate_cur == SAMPLE_RATE_768   ) ? 8'd128 :
                    (sample_rate_cur == SAMPLE_RATE_705_6 ) ? 8'd128 :
                    (sample_rate_cur == SAMPLE_RATE_384   ) ? 8'd64  :
                    (sample_rate_cur == SAMPLE_RATE_352_8 ) ? 8'd64  :
                    (sample_rate_cur == SAMPLE_RATE_192   ) ? 8'd32  :
                    (sample_rate_cur == SAMPLE_RATE_176_4 ) ? 8'd32  :
                    (sample_rate_cur == SAMPLE_RATE_96    ) ? 8'd16  :
                    (sample_rate_cur == SAMPLE_RATE_88_2  ) ? 8'd16  :
                    (sample_rate_cur == SAMPLE_RATE_128   ) ? 8'd32  :
                    (sample_rate_cur == SAMPLE_RATE_64    ) ? 8'd16  :
                    (sample_rate_cur == SAMPLE_RATE_32    ) ? 8'd8   :
                    (sample_rate_cur == SAMPLE_RATE_48    ) ? 8'd8   :
                    (sample_rate_cur == SAMPLE_RATE_44_1  ) ? 8'd8   : 8'd8;
assign  ff_frac_width = (sample_rate_cur == SAMPLE_RATE_768  ) ? 4'd6 :
                        (sample_rate_cur == SAMPLE_RATE_705_6) ? 4'd6 :
                        (sample_rate_cur == SAMPLE_RATE_384  ) ? 4'd7 :
                        (sample_rate_cur == SAMPLE_RATE_352_8) ? 4'd7 :
                        (sample_rate_cur == SAMPLE_RATE_192  ) ? 4'd8 :
                        (sample_rate_cur == SAMPLE_RATE_176_4) ? 4'd8 :
                        (sample_rate_cur == SAMPLE_RATE_96   ) ? 4'd9 :
                        (sample_rate_cur == SAMPLE_RATE_88_2 ) ? 4'd9 :
                        (sample_rate_cur == SAMPLE_RATE_128  ) ? 4'd8 :
                        (sample_rate_cur == SAMPLE_RATE_64   ) ? 4'd9 :
                        (sample_rate_cur == SAMPLE_RATE_32   ) ? 4'd10 :
                        (sample_rate_cur == SAMPLE_RATE_48   ) ? 4'd10 :
                        (sample_rate_cur == SAMPLE_RATE_44_1 ) ? 4'd10 : 4'd10;
reg [11:0] usb_sof_dly;
reg        uac_sof;
always@(posedge PHY_CLKOUT or posedge RESET) begin
    if (RESET) begin
        usb_sof_dly <= 12'd0;
        uac_sof <= 4'd0;
    end
    else begin
        if (usb_sof) begin
            usb_sof_dly <= 12'hFFF;
            uac_sof <= 4'd1;
        end
        else if (usb_sof_dly <= 12'd100)begin
            uac_sof <= 4'd0;
        end
        else begin
            usb_sof_dly <= usb_sof_dly - 1'b1;
        end
    end
end
assign sof_rise = sof_d0&(~sof_d1);
always@(posedge XMCLK or posedge RESET) begin
    if (RESET) begin
        sof_d0 <= 1'b0;
        sof_d1 <= 1'b0;
    end
    else begin
        sof_d0 <= uac_sof;
        sof_d1 <= sof_d0;
    end
end
always@(posedge XMCLK or posedge RESET) begin
    if (RESET) begin
        ff_cnt <= 32'd0;
        sof_cnt <= 8'd0;
        div3_cnt <= 4'd0;
        ff_value <= 32'd0;
        uac_en <= 1'b0;
    end
    else begin
        if (sof_rise) begin
            if (uac_en) begin
                if (sof_cnt >= ff_period - 1'b1) begin
                    sof_cnt <= 8'd0;
                end
                else begin
                    sof_cnt <= sof_cnt + 1'b1;
                end
                if (sof_cnt == ff_period - 1'b1) begin
                    if (fifo_r_alempty) begin
                        ff_value <= ff_cnt + 12'h800;
                    end
                    else begin
                        ff_value <= ff_cnt + 12'h000;
                    end
                    if (sample_rate_cur == SAMPLE_RATE_128) begin
                        ff_cnt <= 32'd1;//{25'd0,ff_cnt[6:0]};
                    end
                    else if (sample_rate_cur == SAMPLE_RATE_64) begin
                        ff_cnt <= 32'd1;//{25'd0,ff_cnt[6:0]};
                    end
                    else if (sample_rate_cur == SAMPLE_RATE_32) begin
                        ff_cnt <= 32'd1;//{25'd0,ff_cnt[6:0]};
                    end
                    else if (ff_frac_width == 4'd6) begin
                        ff_cnt <= 32'd1;//{25'd0,ff_cnt[6:0]};
                    end
                    else if (ff_frac_width == 4'd7) begin
                        ff_cnt <= 32'd1;//{25'd0,ff_cnt[6:0]};
                    end
                    else if (ff_frac_width == 4'd8) begin
                        ff_cnt <= 32'd1;//{24'd0,ff_cnt[7:0]};
                    end
                    else if (ff_frac_width == 4'd9) begin
                        ff_cnt <= 32'd1;//{23'd0,ff_cnt[8:0]};
                    end
                    else if (ff_frac_width == 4'd10) begin
                        ff_cnt <= 32'd1;//{22'd0,ff_cnt[9:0]};
                    end
                    else if (ff_frac_width == 4'd11) begin
                        ff_cnt <= 32'd1;//{21'd0,ff_cnt[10:0]};
                    end
                    else begin
                        ff_cnt <= 32'd1;//{21'd0,ff_cnt[10:0]};
                    end
                end
            end
            else begin
                uac_en <= 1'b1;
            end
        end
        else begin
            if (uac_en) begin
                if ((sample_rate_cur == SAMPLE_RATE_128)||(sample_rate_cur == SAMPLE_RATE_64)||(sample_rate_cur == SAMPLE_RATE_32)) begin
                    if (div3_cnt == 4'd2) begin
                        div3_cnt <= 4'd0;
                        ff_cnt <= ff_cnt + 32'd2;
                    end
                    else begin
                        div3_cnt <= div3_cnt + 4'd1;
                    end
                end
                else begin
                    ff_cnt <= ff_cnt + 32'd1;
                    if (div3_cnt == 4'd1) begin
                        div3_cnt <= 4'd0;
                    end
                    else begin
                        div3_cnt <= div3_cnt + 4'd1;
                    end
                end
            end
        end
    end
end
always@(posedge PHY_CLKOUT, posedge RESET) begin
    if (RESET) begin
        feedback <= 32'd0;
    end
    else begin
        if (usb_txact&(endpt_sel == AUDIO_IT_FB_ENDPOINT[3:0])) begin
            if (usb_txpop) begin
                feedback <= {8'd0,feedback[31:8]};
            end
        end
        else begin
            feedback <= {4'b0000,ff_value[24:0],3'b000};
        end
    end
end
//==============================================================
//======Interface Select
always@(posedge PHY_CLKOUT, posedge RESET) begin
    if (RESET) begin
        tx_data_bits <= 8'd32;
        rx_data_bits <= 8'd32;
        dsd_en      <= 1'b0;
    end
    else begin
        if (interface1_alter == 8'h04) begin
            dsd_en      <= 1'b1;
        end
        else if (interface1_alter == 8'h00) begin
            dsd_en      <= dsd_en;
        end
        else begin
            dsd_en      <= 1'b0;
        end
        //if (usb_highspeed) begin
            if (interface1_alter == 8'h01) begin
                tx_data_bits <= 8'd16;
            end
            else if (interface1_alter == 8'h02) begin
                tx_data_bits <= 8'd24;
            end
            else if (interface1_alter == 8'h03) begin
                tx_data_bits <= 8'd32;
            end
            else if (interface1_alter == 8'h04) begin
                tx_data_bits <= 8'd32;
            end
            if (interface2_alter == 8'h01) begin
                rx_data_bits <= 8'd16;
            end
            else if (interface2_alter == 8'h02) begin
                rx_data_bits <= 8'd24;
            end
            else if (interface2_alter == 8'h03) begin
                rx_data_bits <= 8'd32;
            end
            else if (interface2_alter == 8'h04) begin
                rx_data_bits <= 8'd32;
            end
        //end
        //else begin
        //    data_bits <= 8'd16;
        //end
    end
end

//==============================================================
//======Mute Control
reg        sw_mute;
reg [31:0] sw_mute_dly;
always@(posedge PHY_CLKOUT, posedge RESET) begin
    if (RESET) begin
        sw_mute <= 1'b1;
        sw_mute_dly <= 32'd0;
    end
    else begin
        if (audio_tx_reset) begin
            sw_mute <= 1'b1;
            sw_mute_dly <= 32'd0;
        end
        else if (pre_sample_rate_cur != sample_rate_cur) begin
            sw_mute <= 1'b1;
            sw_mute_dly <= 32'd0;
        end
        else if (sw_mute_dly>=18000000) begin
            sw_mute <= 1'b0;
        end
        else begin
            sw_mute_dly <= sw_mute_dly + 32'd1;
        end
    end
end
always@(posedge PHY_CLKOUT, posedge RESET) begin
    if (RESET) begin
        pre_sample_rate_cur <= SAMPLE_RATE_44_1;
    end
    else begin
        pre_sample_rate_cur <= sample_rate_cur;
    end
end
//-------------------------------------------------------------
//Comment:In/Out Interface
//-------------------------------------------------------------
assign fifo_r_alempty  = I_FIFO_ALEMPTY;
assign fifo_r_alfull   = I_FIFO_ALFULL;
assign O_USB_TXVAL     = (endpt_sel == 4'd0) ? endpt0_send : 1'b0;
assign O_USB_TXDAT     = (endpt_sel == 4'd0) ? endpt0_dat : (endpt_sel == AUDIO_IT_FB_ENDPOINT[3:0]) ? feedback[7:0] : 8'd0;
assign O_USB_TXDAT_LEN = usb_txdat_len;
assign O_USB_TXCORK    = 1'b0;
assign O_DSD_EN        = dsd_en;
assign O_DOP_EN        = dop_en;
assign O_MUTE          = mute_cur|sw_mute|dop_mute|dsd_mute;
assign O_CH0_VOLUME    = ch0_volume_cur;
assign O_CH1_VOLUME    = ch1_volume_cur;
assign O_CH2_VOLUME    = ch2_volume_cur;
assign O_SAMPLE_RATE   = sample_rate_cur;
assign O_TX_DATA_BITS  = tx_data_bits;
assign O_RX_DATA_BITS  = rx_data_bits;

endmodule
//===========================================

