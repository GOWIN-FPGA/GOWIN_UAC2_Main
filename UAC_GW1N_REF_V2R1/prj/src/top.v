/******************************************************************************
Copyright 2022 GOWIN SEMICONDUCTOR CORPORATION
  
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

The Software is used with products manufacturered by GOWIN Semconductor only
unless otherwise authorized by GOWIN Semiconductor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. 
******************************************************************************/
module top
#(
  parameter P_LOOPBACK     = 0 , // 0: (disabled) Mic input | 1: = Received I2S from USB host is transmitted back to USB host
			GAIN_SLOT	   = 0 , // Audio Amplifier gain : 0: 12db |  1: 6db
			MIC_IIS_2_IO   = 1   // 0: USB IIS to external Mic Amplifier | 1: USB IIS to GPIO Header Mic IO
)( 
//interconnection
input          CLK_IN         ,//12MHZ
input          CLK_IIS_49_152_I,//49.152MHz
input 		   CLK_IIS_45_158_I,//45.158Mhz

//I2S Microphone Input
output 	wire		MIC_IIS_BCLK_O ,
output 	wire		MIC_IIS_LRCK_O ,
input  	wire		MIC_IIS_DATA_I ,
//I2S Amplifier Output
output    wire     IIS_LRCK_O     ,
output    wire     IIS_BCLK_O     ,
output    wire     IIS_DATA_O     ,
inout          USB_DXP_IO     ,
inout          USB_DXN_IO     ,
input          USB_RXDP_I     ,
input          USB_RXDN_I     ,
output         USB_PULLUP_EN_O,
inout          USB_TERM_DP_IO ,
inout          USB_TERM_DN_IO ,

output    reg     APM_IIS_LRCK_O     ,
output    reg     APM_IIS_BCLK_O     ,
output    reg     APM_IIS_DATA_O     ,

output 		reg	MIC_IIS_2_IO_BCLK_O,
output 		reg	MIC_IIS_2_IO_LRCK_O,
input		wire	MIC_IIS_2_IO_DATA_I,


//MAX98357A control
output HORN_GAIN_SLOT_O ,
output HORN_SD_MODE_O	

);




localparam  CLOCK_SOURCE_ID          = 8'h05;
localparam  AUDIO_CONTROL_UNIT_ID    = 8'h03;
localparam  CLOCK_SELECTOR_ID        = 8'h28;
localparam  AUDIO_IT_ENDPOINT        = 8'h82;
localparam  AUDIO_OT_ENDPOINT        = 8'h01;
localparam  AUDIO_IT_FB_ENDPOINT     = 8'h81;
localparam  DOP_PACKET_CODE0         = 8'h05;
localparam  DOP_PACKET_CODE1         = 8'hFA;
localparam  SAMPLE_RATE_32    = 32'h00007D00;
localparam  SAMPLE_RATE_44_1  = 32'h0000AC44;
localparam  SAMPLE_RATE_48    = 32'h0000BB80;
localparam  SAMPLE_RATE_64    = 32'h0000FA00;
localparam  SAMPLE_RATE_88_2  = 32'h00015888;
localparam  SAMPLE_RATE_96    = 32'h00017700;
localparam  SAMPLE_RATE_128   = 32'h0001F400;
localparam  SAMPLE_RATE_176_4 = 32'h0002B110;
localparam  SAMPLE_RATE_192   = 32'h0002EE00;
localparam  SAMPLE_RATE_352_8 = 32'h00056220;
localparam  SAMPLE_RATE_384   = 32'h0005DC00;
localparam  SAMPLE_RATE_705_6 = 32'h000AC440;
localparam  SAMPLE_RATE_768   = 32'h000BB800;
wire        mute;
wire [15:0] ch0_volume;
wire [15:0] ch1_volume;
wire [15:0] ch2_volume;
wire [31:0] sample_rate;
wire [7:0]  tx_data_bits;
wire [7:0]  rx_data_bits;
wire [1:0]  phy_xcvrselect;
wire        phy_termselect;
wire [1:0]  phy_opmode;
wire [1:0]  phy_linestate;
wire        phy_txvalid;
wire        phy_txready;
wire        phy_rxvalid;
wire        phy_rxactive;
wire        phy_rxerror;
wire [7:0]  phy_datain;
wire [7:0]  phy_dataout;
wire        phy_clkout;
wire        phy_reset;
wire [15:0] descrom_raddr;
wire [7:0]  desc_index;
wire [7:0]  desc_type;
wire [7:0]  descrom_rdat;
wire [15:0] desc_dev_addr;
wire [15:0] desc_dev_len;
wire [15:0] desc_qual_addr;
wire [15:0] desc_qual_len;
wire [15:0] desc_fscfg_addr;
wire [15:0] desc_fscfg_len;
wire [15:0] desc_hscfg_addr;
wire [15:0] desc_hscfg_len;
wire [15:0] desc_oscfg_addr;
wire [15:0] desc_hidrpt_addr;
wire [15:0] desc_hidrpt_len;
wire [15:0] desc_strlang_addr;
wire [15:0] desc_strvendor_addr;
wire [15:0] desc_strvendor_len;
wire [15:0] desc_strproduct_addr;
wire [15:0] desc_strproduct_len;
wire [15:0] desc_strserial_addr;
wire [15:0] desc_strserial_len;
wire        descrom_have_strings;
wire        usb_busreset;
wire        usb_highspeed;
wire        usb_suspend;
wire        usb_online;
wire        usb_txval;
wire [ 7:0] usb_txdat;
wire [ 7:0] uac_txdat;
wire [11:0] usb_txdat_len;
wire [11:0] uac_txdat_len;
wire        uac_txcork;
wire        usb_txcork;
wire        usb_txpop;
wire        usb_txact;
wire        usb_txpktfin;
wire [ 7:0] usb_rxdat;
wire        usb_rxval;
wire        usb_rxact;
wire        usb_rxpktval;
wire        usb_setup;
wire [ 3:0] usb_endpt_sel;
wire        usb_sof;
wire [ 7:0] interface_alter_i;
wire [ 7:0] interface_alter_o;
wire [ 7:0] interface_sel;
wire        interface_update;
wire [10:0] audio_rx_num;
wire        w_lrck_source;
wire        w_data_source;
wire        w_bclk_source;
wire [11:0] audio_pkt_max;
wire [11:0] audio_pkt_nor;
wire [11:0] audio_pkt_min;
wire        audio_rx_dval;
wire [7:0]  audio_rx_data;
wire        audio_tx_dval;
wire [7:0]  audio_tx_data;
wire        dsd_clk; 
wire        dsd_data1;
wire        dsd_data2;
wire        pcm_lrck;
wire        pcm_bclk;
wire        pcm_data;
wire        iis_lrck;
wire        iis_bclk;
wire        iis_data;
wire        dsd_en;
wire        dop_en;
wire        fifo_alempty;
wire        fifo_alfull;
wire CLK_IIS ;
wire set_sample_rate ;

assign w_lrck_source = P_LOOPBACK ? ~IIS_LRCK_O : ~MIC_IIS_LRCK_O ;//loopback mode takes I2S data from USB and sends it back out USB.Otherwise use I2S microphone input
assign w_data_source = P_LOOPBACK ? IIS_DATA_O : MIC_IIS_2_IO ? MIC_IIS_2_IO_DATA_I :MIC_IIS_DATA_I ;
assign w_bclk_source = P_LOOPBACK ? IIS_BCLK_O : MIC_IIS_BCLK_O ;
assign HORN_GAIN_SLOT_O	 =  GAIN_SLOT ;
assign HORN_SD_MODE_O	 =  1'b1 ;




//==============================================================
//======PLL 
wire fclk_480m;
wire pll_locked;
wire fclk;
wire reset;
Gowin_rPLL u_pll(
    .clkout (fclk_480m ), //output clkout
    .clkoutd(phy_clkout), //output clkout
    .lock   (pll_locked),
    .clkin  (CLK_IN    )  //input clkin
);

iis_rPLL u_iis_rPLL(
    .clkin  (CLK_IIS),//input 49.152MHz
    .clkoutd(xmclk      ),//output 49.152MHz
    .clkout (fclk       ) //output 98.304MHZ
);

reg [3:0] clksel ;



always @ ( * ) begin
	//if ( reset )
	//	clksel <= 4'b0001 ;
	//else
		case ( sample_rate )
		SAMPLE_RATE_32    : clksel <= 4'b0001;
		SAMPLE_RATE_44_1  : clksel <= 4'b0010;
		SAMPLE_RATE_48    : clksel <= 4'b0001;
		SAMPLE_RATE_64    : clksel <= 4'b0001;
		SAMPLE_RATE_88_2  : clksel <= 4'b0010;
		SAMPLE_RATE_96    : clksel <= 4'b0001;
		SAMPLE_RATE_128   : clksel <= 4'b0001;
		SAMPLE_RATE_176_4 : clksel <= 4'b0010;
		SAMPLE_RATE_192   : clksel <= 4'b0001;
		SAMPLE_RATE_352_8 : clksel <= 4'b0010;
		SAMPLE_RATE_384   : clksel <= 4'b0001;
		SAMPLE_RATE_705_6 : clksel <= 4'b0010;
		SAMPLE_RATE_768   : clksel <= 4'b0001;
		default :           clksel <= 4'b0000;
		endcase
end
 


Gowin_DCS Gowin_DCS_inst(
    .clkout(CLK_IIS), //output clkout
    .clksel(clksel), //input [3:0] clksel
    .clk0(CLK_IIS_49_152_I), //input clk0
    .clk1(CLK_IIS_45_158_I), //input clk1
    .clk2(1'b0), //input clk2
    .clk3(1'b0) //input clk3
);


//==============================================================
//======Reset
assign reset = !(pll_locked);
//==============================================================
//======USB Device Controller
USB_Device_Controller_Top u_usb_device_controller_top (
         .clk_i                 (phy_clkout          )
        ,.reset_i               (reset               )
        ,.usbrst_o              (usb_busreset        )
        ,.highspeed_o           (usb_highspeed       )
        ,.suspend_o             (usb_suspend         )
        ,.online_o              (usb_online          )
        ,.txdat_i               (usb_txdat           )
        ,.txval_i               (usb_txval           )
        ,.txdat_len_i           (usb_txdat_len       )
        ,.txcork_i              (usb_txcork          )
        ,.txiso_pid_i           (4'b0011             )
        ,.txpop_o               (usb_txpop           )
        ,.txact_o               (usb_txact           )
        ,.txpktfin_o            (usb_txpktfin        )
        ,.rxdat_o               (usb_rxdat           )
        ,.rxval_o               (usb_rxval           )
        ,.rxact_o               (usb_rxact           )
        ,.rxrdy_i               (1'b1                )
        ,.rxpktval_o            (usb_rxpktval        )
        ,.setup_o               (usb_setup           )
        ,.endpt_o               (usb_endpt_sel       )
        ,.sof_o                 (usb_sof             )
        ,.inf_alter_i           (interface_alter_i   )
        ,.inf_alter_o           (interface_alter_o   )
        ,.inf_sel_o             (interface_sel       )
        ,.inf_set_o             (interface_update    )
        ,.descrom_rdata_i       (descrom_rdat        )
        ,.descrom_raddr_o       (descrom_raddr       )
        ,.desc_index_o          (desc_index          )
        ,.desc_type_o           (desc_type           )
        ,.desc_dev_addr_i       (desc_dev_addr       )
        ,.desc_dev_len_i        (desc_dev_len        )
        ,.desc_qual_addr_i      (desc_qual_addr      )
        ,.desc_qual_len_i       (desc_qual_len       )
        ,.desc_fscfg_addr_i     (desc_fscfg_addr     )
        ,.desc_fscfg_len_i      (desc_fscfg_len      )
        ,.desc_hscfg_addr_i     (desc_hscfg_addr     )
        ,.desc_hscfg_len_i      (desc_hscfg_len      )
        ,.desc_oscfg_addr_i     (desc_oscfg_addr     )
        ,.desc_hidrpt_addr_i    (desc_hidrpt_addr    )
        ,.desc_hidrpt_len_i     (desc_hidrpt_len     )
        ,.desc_strlang_addr_i   (desc_strlang_addr   )
        ,.desc_strvendor_addr_i (desc_strvendor_addr )
        ,.desc_strvendor_len_i  (desc_strvendor_len  )
        ,.desc_strproduct_addr_i(desc_strproduct_addr)
        ,.desc_strproduct_len_i (desc_strproduct_len )
        ,.desc_strserial_addr_i (desc_strserial_addr )
        ,.desc_strserial_len_i  (desc_strserial_len  )
        ,.desc_bos_addr_i       (16'd0                   )
        ,.desc_bos_len_i        (16'd0                   )
        ,.desc_have_strings_i   (descrom_have_strings)
        ,.utmi_dataout_o        (phy_dataout         )
        ,.utmi_txvalid_o        (phy_txvalid         )
        ,.utmi_txready_i        (phy_txready         )
        ,.utmi_datain_i         (phy_datain          )
        ,.utmi_rxactive_i       (phy_rxactive        )
        ,.utmi_rxvalid_i        (phy_rxvalid         )
        ,.utmi_rxerror_i        (phy_rxerror         )
        ,.utmi_linestate_i      (phy_linestate       )
        ,.utmi_opmode_o         (phy_opmode          )
        ,.utmi_xcvrselect_o     (phy_xcvrselect      )
        ,.utmi_termselect_o     (phy_termselect      )
        ,.utmi_reset_o          (phy_reset           )
);

//reg [11:0] rx_cnt ;
//reg [11:0] tx_cnt ;		
//always @ ( posedge phy_clkout or posedge reset )begin
//	if(reset) begin
//		rx_cnt <= 0; 
//		tx_cnt <= 0; 
//	end
//	else if ( async_fifo_rst ) begin
//		rx_cnt <= 0; 
//		tx_cnt <= 0; 
//	end	
//	else if (  usb_endpt_sel == 1 && usb_rxval == 1 ) 
//		rx_cnt <= rx_cnt + 1;
//	else if ( usb_endpt_sel == 2 && usb_txpop == 1 )
//		tx_cnt <= tx_cnt + 1 ;
//		
//end




//==============================================================
//======USB Device Descriptor
usb_desc
#(
     .VENDORID               (16'h33AB)
    ,.PRODUCTID              (16'h0202)
    ,.VERSIONBCD             (16'h0201)
    ,.HSSUPPORT              (1       )
    ,.SELFPOWERED            (0       )
    ,.CLOCK_SOURCE_ID        (CLOCK_SOURCE_ID      )
    ,.AUDIO_CONTROL_UNIT_ID  (AUDIO_CONTROL_UNIT_ID)
    ,.CLOCK_SELECTOR_ID      (CLOCK_SELECTOR_ID    )
    ,.AUDIO_IT_ENDPOINT      (AUDIO_IT_ENDPOINT    )
    ,.AUDIO_OT_ENDPOINT      (AUDIO_OT_ENDPOINT    )
    ,.AUDIO_IT_FB_ENDPOINT   (AUDIO_IT_FB_ENDPOINT )
)
u_usb_desc (
     .CLK                    (phy_clkout          )
    ,.RESET                  (reset               )
    ,.i_descrom_raddr        (descrom_raddr       )
    ,.o_descrom_rdat         (descrom_rdat        )
    ,.i_desc_index_o         (desc_index          )
    ,.i_desc_type_o          (desc_type           )
    ,.o_desc_dev_addr        (desc_dev_addr       )
    ,.o_desc_dev_len         (desc_dev_len        )
    ,.o_desc_qual_addr       (desc_qual_addr      )
    ,.o_desc_qual_len        (desc_qual_len       )
    ,.o_desc_fscfg_addr      (desc_fscfg_addr     )
    ,.o_desc_fscfg_len       (desc_fscfg_len      )
    ,.o_desc_hscfg_addr      (desc_hscfg_addr     )
    ,.o_desc_hscfg_len       (desc_hscfg_len      )
    ,.o_desc_oscfg_addr      (desc_oscfg_addr     )
    ,.o_desc_hidrpt_addr     (desc_hidrpt_addr    )
    ,.o_desc_hidrpt_len      (desc_hidrpt_len     )
    ,.o_desc_strlang_addr    (desc_strlang_addr   )
    ,.o_desc_strvendor_addr  (desc_strvendor_addr )
    ,.o_desc_strvendor_len   (desc_strvendor_len  )
    ,.o_desc_strproduct_addr (desc_strproduct_addr)
    ,.o_desc_strproduct_len  (desc_strproduct_len )
    ,.o_desc_strserial_addr  (desc_strserial_addr )
    ,.o_desc_strserial_len   (desc_strserial_len  )
    ,.o_descrom_have_strings (descrom_have_strings)
);
//==============================================================
//======USB SoftPHY 
USB2_0_SoftPHY_Top u_USB_SoftPHY_Top
(
     .clk_i             (phy_clkout     )
    ,.rst_i             (phy_reset      )
    ,.fclk_i            (fclk_480m      )
    ,.pll_locked_i      (pll_locked     )
    ,.utmi_data_out_i   (phy_dataout    )
    ,.utmi_txvalid_i    (phy_txvalid    )
    ,.utmi_op_mode_i    (phy_opmode     )
    ,.utmi_xcvrselect_i (phy_xcvrselect )
    ,.utmi_termselect_i (phy_termselect )
    ,.utmi_data_in_o    (phy_datain     )
    ,.utmi_txready_o    (phy_txready    )
    ,.utmi_rxvalid_o    (phy_rxvalid    )
    ,.utmi_rxactive_o   (phy_rxactive   )
    ,.utmi_rxerror_o    (phy_rxerror    )
    ,.utmi_linestate_o  (phy_linestate  )
    ,.usb_dxp_io        (USB_DXP_IO     )
    ,.usb_dxn_io        (USB_DXN_IO     )
    ,.usb_rxdp_i        (USB_RXDP_I     )
    ,.usb_rxdn_i        (USB_RXDN_I     )
    ,.usb_pullup_en_o   (USB_PULLUP_EN_O)
    ,.usb_term_dp_io    (USB_TERM_DP_IO )
    ,.usb_term_dn_io    (USB_TERM_DN_IO )
);

//==============================================================
//======USB FIFO
wire        ep_usb_txcork;
wire        ep_usb_rxrdy;
wire [11:0] ep_usb_txlen;
wire [ 7:0] ep_usb_txdat;
wire usb_tx_fifo_full ;
wire audio_tx_dval_d ;
wire [7:0] audio_tx_data_d ;


usb_fifo #
(
	.P_LOOPBACK(P_LOOPBACK)
)usb_fifo
(
     .i_clk         (phy_clkout        )//clock
    ,.i_reset       (usb_busreset      )//reset
    ,.i_usb_endpt   (usb_endpt_sel     )//
    ,.i_usb_rxact   (usb_rxact         )//
    ,.i_usb_rxval   (usb_rxval         )//
    ,.i_usb_rxpktval(usb_rxpktval      )//
    ,.i_usb_rxdat   (usb_rxdat         )//
    ,.o_usb_rxrdy   (ep_usb_rxrdy      )//
    ,.i_usb_txact   (usb_txact         )//
    ,.i_usb_txpop   (usb_txpop         )//
    ,.i_usb_txpktfin(usb_txpktfin      )//
    ,.o_usb_txcork  (ep_usb_txcork     )//
    ,.o_usb_txlen   (ep_usb_txlen      )//
    ,.o_usb_txdat   (ep_usb_txdat      )//
	,.i_interface_sel (interface_sel)
	,.i_interface_alter(interface_alter_o)
	,.usb_tx_fifo_full ( usb_tx_fifo_full )
	,.tx_data_bits (tx_data_bits)
	
    //Audio Input Endpoint2
    ,.i_ep2_tx_clk  (phy_clkout        )//
    ,.i_ep2_tx_max  (audio_pkt_max     )//
    ,.i_ep2_tx_nor  (audio_pkt_nor     )//
    ,.i_ep2_tx_min  (audio_pkt_min     )//
    ,.i_ep2_tx_dval (  audio_rx_dval   )//audio_rx_dval
    ,.i_ep2_tx_data (  audio_rx_data	)//audio_rx_data
    //Audio Output Endpoint1	
    ,.i_ep1_rx_clk  (phy_clkout        )//
    ,.i_ep1_rx_rdy  (1'b1              )//
    ,.o_ep1_rx_dval (  audio_tx_dval )//
    ,.o_ep1_rx_data ( audio_tx_data	)//

); 

//	RAM_based_shift_reg_1 RAM_based_shift_reg_1(
//		.clk(phy_clkout), //input clk
//		.Reset(reset), //input Reset
//		.Din(audio_tx_dval), //input [0:0] Din
//		.Q(audio_tx_dval_d) //output [0:0] Q
//	);
//
//	RAM_based_shift_reg_2 RAM_based_shift_reg_2(
//		.clk(phy_clkout), //input clk
//		.Reset(reset), //input Reset
//		.Din(audio_tx_data), //input [7:0] Din
//		.Q(audio_tx_data_d) //output [7:0] Q
//	);


//==============================================================
//======UAC Controller
uac_ctrl #(
     .CLOCK_SOURCE_ID          (CLOCK_SOURCE_ID         )//Clock Source
    ,.AUDIO_CONTROL_UNIT_ID    (AUDIO_CONTROL_UNIT_ID   )//Audio Control Feature Unit
    ,.CLOCK_SELECTOR_ID        (CLOCK_SELECTOR_ID       )//Clock Selector
    ,.DOP_PACKET_CODE0         (DOP_PACKET_CODE0        )//0x00 XX XX 0x05 0x00 XX XX 0x05
    ,.DOP_PACKET_CODE1         (DOP_PACKET_CODE1        )//0x00 XX XX 0xFA 0x00 XX XX 0xFA
    ,.AUDIO_IT_FB_ENDPOINT     (AUDIO_IT_FB_ENDPOINT    )
)
uac_ctrl_inst
( 
     .PHY_CLKOUT        (phy_clkout       )//clock
    ,.RESET             (reset            )//reset
    ,.XMCLK             (xmclk        	  )
    ,.I_USB_HIGHSPEED   (1'b1             )
    ,.I_USB_SETUP       (usb_setup        )
    ,.I_USB_ENDPT_SEL   (usb_endpt_sel    )
    ,.I_USB_RXPKTVAL    (usb_rxpktval     )
    ,.I_USB_SOF         (usb_sof          )
    ,.I_USB_RXACT       (usb_rxact        )
    ,.I_USB_RXVAL       (usb_rxval        )
    ,.I_USB_RXDAT       (usb_rxdat        )
    ,.I_USB_TXACT       (usb_txact        )
    ,.I_USB_TXPOP       (usb_txpop        )
    ,.O_USB_TXVAL       (usb_txval        )
    ,.O_USB_TXDAT       (uac_txdat        )
    ,.O_USB_TXDAT_LEN   (uac_txdat_len    )
    ,.O_USB_TXCORK      (uac_txcork       )
    ,.I_INTERFACE_ALTER (interface_alter_o)
    ,.O_INTERFACE_ALTER (interface_alter_i)
    ,.I_INTERFACE_SEL   (interface_sel    )
    ,.I_INTERFACE_UPDATE(interface_update )
    ,.I_FIFO_ALEMPTY    (fifo_alempty     )
    ,.I_FIFO_ALFULL     (fifo_alfull      )
    ,.O_DSD_EN          (dsd_en           )
    ,.O_DOP_EN          (dop_en           )
    ,.O_MUTE            (mute             )
    ,.O_CH0_VOLUME      (ch0_volume       )
    ,.O_CH1_VOLUME      (ch1_volume       )
    ,.O_CH2_VOLUME      (ch2_volume       )
    ,.O_SAMPLE_RATE     (sample_rate      )
    ,.O_TX_DATA_BITS    (tx_data_bits     )
    ,.O_RX_DATA_BITS    (rx_data_bits     )
);
//==============================================================
//======Audio TX
audio_tx audio_tx_inst //384 192 96 48
(
     .PHY_CLKOUT          (phy_clkout          )//
    ,.RESET               (reset               )//reset
    ,.MCLK                (fclk                )//iis clock 98.304MHz
    ,.I_ENABLE            (1'b1                )
    ,.I_LEFT_EN           (1'b1                )
    ,.I_RIGHT_EN          (1'b1                )
    ,.I_DSD_EN            (dsd_en              )
    ,.I_DOP_EN            (dop_en              )
    ,.I_SOF               (usb_sof             )
    ,.I_SAMPLE_RATE       (sample_rate         )
    ,.I_DATA_BITS         (tx_data_bits        )
    ,.I_AUDIO_DVAL        (audio_tx_dval       )
    ,.I_AUDIO_DATA        (audio_tx_data       )
    ,.O_FIFO_ALEMPTY      (fifo_alempty        )
    ,.O_FIFO_ALFULL       (fifo_alfull         )
    ,.O_DSD_CLK           (dsd_clk             )
    ,.O_DSD_DATA1         (dsd_data1           )
    ,.O_DSD_DATA2         (dsd_data2           )
    ,.O_PCM_LRCK          (pcm_lrck            )
    ,.O_PCM_BCLK          (pcm_bclk            )
    ,.O_PCM_DATA          (pcm_data            )
    ,.O_IIS_LRCK          (iis_lrck            )
    ,.O_IIS_BCLK          (iis_bclk            )
    ,.O_IIS_DATA          (iis_data            )
);






//==============================================================
//======IIS RX

MIC_CLK_GEN  MIC_CLK_GEN_inst
(
	.PHY_CLKOUT 	( phy_clkout	) ,
	.MCLK 			(fclk			) ,
	.RESET			(reset			) ,
    .I_DATA_BITS  	(rx_data_bits   ) ,	
	.I_SAMPLE_RATE  (sample_rate	) ,

    .O_IIS_LRCK     (MIC_IIS_LRCK_O),
    .O_IIS_BCLK     (MIC_IIS_BCLK_O)	

);


reg async_fifo_rst ;
always @ ( posedge fclk or posedge reset )begin
	if(reset)
		async_fifo_rst <= 1'b1 ;
	else if ( usb_tx_fifo_full )
		async_fifo_rst <= 1'b1 ;
	else if ( interface_sel == 2 && interface_alter_o == 0 )
		async_fifo_rst <= 1'b1 ;
	else if ( async_fifo_rst == 1 && usb_endpt_sel==2 )
		async_fifo_rst <= 1'b0 ;
	else
		async_fifo_rst <= async_fifo_rst ;
end
 
audio_rx audio_rx_inst
(
     .PHY_CLKOUT        (phy_clkout        )//
    ,.RESET             (reset             )//reset
    ,.MCLK              (fclk              )//clock
    ,.L_EN_I            (1'b1              )
    ,.R_EN_I            (1'b1              )
    ,.PCM_EN_I          (1'b0              )
	,.async_fifo_rst	(async_fifo_rst)
    ,.DATA_BITS_I       (rx_data_bits      )
    ,.SAMPLE_FREQ_I     (sample_rate       )
    ,.PCM_LRCK_I        (1'b0              )
    ,.PCM_BCLK_I        (1'b0              )
    ,.PCM_DATA_I        (1'b0              )
    ,.IIS_LRCK_I        (w_lrck_source     )
    ,.IIS_BCLK_I        (w_bclk_source     )
    ,.IIS_DATA_I        (w_data_source     )
    ,.AUDIO_PKT_MAX     (audio_pkt_max     )
    ,.AUDIO_PKT_NOR     (audio_pkt_nor     )
    ,.AUDIO_PKT_MIN     (audio_pkt_min     )
    ,.AUDIO_RX_DVAL_O   (audio_rx_dval     )
    ,.AUDIO_RX_DATA_O   (audio_rx_data     )
);
//==============================================================
//====== IIS 2 IO 
always @ ( posedge fclk or posedge reset  ) begin
	if ( reset ) begin 
		APM_IIS_LRCK_O =	1'b0 ;
		APM_IIS_BCLK_O =	1'b0 ;
		APM_IIS_DATA_O =	1'b0 ;
		MIC_IIS_2_IO_BCLK_O = 1'b0  ;		
		MIC_IIS_2_IO_LRCK_O = 1'b0  ;		
	end
	else begin 
		APM_IIS_LRCK_O =  IIS_LRCK_O;
		APM_IIS_BCLK_O =  IIS_BCLK_O;
		APM_IIS_DATA_O =  IIS_DATA_O;
		MIC_IIS_2_IO_BCLK_O = MIC_IIS_BCLK_O  ;		
		MIC_IIS_2_IO_LRCK_O = MIC_IIS_LRCK_O  ;		
	end
end
//==============================================================
//======Tx Cork
assign usb_txdat_len = (usb_endpt_sel == AUDIO_IT_ENDPOINT[3:0]) ? ep_usb_txlen : uac_txdat_len;
assign usb_txcork = (usb_endpt_sel == AUDIO_IT_ENDPOINT[3:0]) ? ep_usb_txcork : uac_txcork;
assign usb_txdat  = (usb_endpt_sel == AUDIO_IT_ENDPOINT[3:0]) ? ep_usb_txdat : uac_txdat;
assign IIS_BCLK_O = dsd_en|dop_en ? dsd_clk   : iis_bclk;
assign IIS_LRCK_O = dsd_en|dop_en ? dsd_data2 : iis_lrck;
assign IIS_DATA_O = dsd_en|dop_en ? dsd_data1 : iis_data;

endmodule
