

`timescale 1ns / 1ns
`include "usb2_0_softphy_name.v"
`include "static_macro_define.v"

module `module_name (
    input       clk_i            ,
    input       rst_i            ,
    input       fclk_i           ,
    input       pll_locked_i     ,
    `ifdef UTMI //utmi
    input[7:0]  utmi_data_out_i  ,
    input       utmi_txvalid_i   ,
    input[1:0]  utmi_op_mode_i   ,
    input[1:0]  utmi_xcvrselect_i,
    input       utmi_termselect_i,
    output[7:0] utmi_data_in_o   ,
    output      utmi_txready_o   ,
    output      utmi_rxvalid_o   ,
    output      utmi_rxactive_o  ,
    output      utmi_rxerror_o   ,
    output[1:0] utmi_linestate_o ,
    `else //ulpi
    inout [7:0] ulpi_data_io     ,
    output      ulpi_dir_o       ,
    input       ulpi_stp_i       ,
    output      ulpi_nxt_o       ,
    `endif
    //usb interface
    inout       usb_dxp_io       ,
    inout       usb_dxn_io       ,
    input       usb_rxdp_i       ,
    input       usb_rxdn_i       ,
    output      usb_pullup_en_o  ,
    inout       usb_term_dp_io   ,
    inout       usb_term_dn_io
);

`getname(usb2_0_softphy,`module_name) usb2_0_softphy
(
     .clk_i            (clk_i            )
    ,.rst_i            (rst_i            )
    ,.fclk_i           (fclk_i           )
    ,.pll_locked_i     (pll_locked_i     )
    `ifdef UTMI //utmi
    ,.utmi_data_out_i  (utmi_data_out_i  )
    ,.utmi_txvalid_i   (utmi_txvalid_i   )
    ,.utmi_op_mode_i   (utmi_op_mode_i   )
    ,.utmi_xcvrselect_i(utmi_xcvrselect_i)
    ,.utmi_termselect_i(utmi_termselect_i)
    ,.utmi_data_in_o   (utmi_data_in_o   )
    ,.utmi_txready_o   (utmi_txready_o   )
    ,.utmi_rxvalid_o   (utmi_rxvalid_o   )
    ,.utmi_rxactive_o  (utmi_rxactive_o  )
    ,.utmi_rxerror_o   (utmi_rxerror_o   )
    ,.utmi_linestate_o (utmi_linestate_o )
    `else //ulpi
    ,.ulpi_data_io     (ulpi_data_io     )
    ,.ulpi_dir_o       (ulpi_dir_o       )
    ,.ulpi_stp_i       (ulpi_stp_i       )
    ,.ulpi_nxt_o       (ulpi_nxt_o       )
    `endif
    //usb interface
    ,.usb_dxp_io       (usb_dxp_io       )
    ,.usb_dxn_io       (usb_dxn_io       )
    ,.usb_rxdp_i       (usb_rxdp_i       )
    ,.usb_rxdn_i       (usb_rxdn_i       )
    ,.usb_pullup_en_o  (usb_pullup_en_o  )
    ,.usb_term_dp_io   (usb_term_dp_io   )
    ,.usb_term_dn_io   (usb_term_dn_io   )
);
endmodule
