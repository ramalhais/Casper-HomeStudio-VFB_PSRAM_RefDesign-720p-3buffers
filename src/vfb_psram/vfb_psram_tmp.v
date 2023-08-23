//Copyright (C)2014-2022 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: GowinSynthesis V1.9.8.06
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9C
//Created Time: Sun Nov 13 11:40:37 2022

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	VFB_PSRAM_Top your_instance_name(
		.I_rst_n(I_rst_n_i), //input I_rst_n
		.I_dma_clk(I_dma_clk_i), //input I_dma_clk
		.I_vin0_clk(I_vin0_clk_i), //input I_vin0_clk
		.I_vin0_vs_n(I_vin0_vs_n_i), //input I_vin0_vs_n
		.I_vin0_de(I_vin0_de_i), //input I_vin0_de
		.I_vin0_data(I_vin0_data_i), //input [23:0] I_vin0_data
		.O_vin0_fifo_full(O_vin0_fifo_full_o), //output O_vin0_fifo_full
		.I_vout0_clk(I_vout0_clk_i), //input I_vout0_clk
		.I_vout0_vs_n(I_vout0_vs_n_i), //input I_vout0_vs_n
		.I_vout0_de(I_vout0_de_i), //input I_vout0_de
		.O_vout0_den(O_vout0_den_o), //output O_vout0_den
		.O_vout0_data(O_vout0_data_o), //output [23:0] O_vout0_data
		.O_vout0_fifo_empty(O_vout0_fifo_empty_o), //output O_vout0_fifo_empty
		.O_cmd(O_cmd_o), //output O_cmd
		.O_cmd_en(O_cmd_en_o), //output O_cmd_en
		.O_addr(O_addr_o), //output [20:0] O_addr
		.O_wr_data(O_wr_data_o), //output [63:0] O_wr_data
		.O_data_mask(O_data_mask_o), //output [7:0] O_data_mask
		.I_rd_data_valid(I_rd_data_valid_i), //input I_rd_data_valid
		.I_rd_data(I_rd_data_i), //input [63:0] I_rd_data
		.I_init_calib(I_init_calib_i) //input I_init_calib
	);

//--------Copy end-------------------
