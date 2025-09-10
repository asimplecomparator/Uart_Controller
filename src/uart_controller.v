// +FHEADER-------------------------------------------------------------------------------
// Copyright (c) 2018-2023 Radsim. All rights reserved.
// ---------------------------------------------------------------------------------------
// Author        : Feiyu Wang
// Email         : wangfeiyu@radsim.com
// Department    : Hardware
// Create Data   : 04/10/2023 14:17:11
// Module Name   : uart_controller.v
// ---------------------------------------------------------------------------------------
// Revision      : 1.0 (04/10/2023)
// Description   : a uart controller allow dynamic configure
// Revision 1.00 - File Created
// ---------------------------------------------------------------------------------------
// Reuse Issue   : 
// Clock Domains : clk
// Synthesizable : yes
// Reset Strategy: Sync Reset, Active High
// Instantiations: yes
// Other : 
// -FHEADER-------------------------------------------------------------------------------
 
`resetall
`timescale 1ns / 1ps
`default_nettype none
 
module uart_controller#(
	parameter integer	BAUD_RATE   = 10_000_000, // 110 - 10_000_000 
	parameter integer   LSB_FIRST   = 1,  	      // 0:FALSE / 1:TURE
	parameter integer	STOP_BIT    = 2,          // 1 / 2
	parameter integer	PARITY_TYPE = 2,          // 2:EVEN/1:ODD/0:NO_PARITY
	parameter integer	CLK_FREQ	= 100_000_000 // 
	)(
	input	wire		clk,
	input	wire		rst,

	input	wire		uart_rxd,
	output	wire		uart_txd,

	input	wire [ 7:0]	s_axis_tdata,
	input	wire 		s_axis_tvalid,
	output	wire 		s_axis_tready,

	output	wire [ 7:0]	m_axis_tdata,
	output  wire 		m_axis_tvalid,
	
	input	wire [31:0]	s_axis_cfg_tdata,
	input	wire 		s_axis_cfg_tvalid,
	output  wire        s_axis_cfg_tready
	);

	reg  [23:0]			cfg_baud_rate;
	reg  				cfg_lsb_first;
	reg  [ 1:0]			cfg_stop_bit;
	reg  [ 1:0] 		cfg_parity_type;
	reg 				cfg_channel_enable;
	reg	 [31:0]			cfg_clk_freq;

	wire				is_receiving;// most important REG 
	reg					is_receiving_d1;
	wire				is_transmitting;// most important REG 拉高在s_axis_tvalid 的下一个时钟周期
	reg				 	is_transmitting_d1;
	wire				new_rx_data;
	wire				new_tx_data;
	wire				ce_tx;
	wire				ce_rx;


	always @ ( posedge clk ) begin
		if(rst)begin
			cfg_baud_rate 		<= BAUD_RATE;
			cfg_lsb_first 		<= LSB_FIRST;
			cfg_stop_bit  		<= STOP_BIT;
			cfg_parity_type 	<= PARITY_TYPE;
			cfg_channel_enable 	<= 1'b1;  // Todo: default Value Should be Set by User. 
			cfg_clk_freq		<= CLK_FREQ;
		end else if (s_axis_cfg_tvalid && s_axis_cfg_tready)begin
			cfg_baud_rate 		<= s_axis_cfg_tdata[23:0];
			cfg_lsb_first 		<= s_axis_cfg_tdata[24];
			cfg_stop_bit  		<= s_axis_cfg_tdata[26:25];
			cfg_parity_type 	<= s_axis_cfg_tdata[28:27];
			cfg_channel_enable 	<= s_axis_cfg_tdata[29];
			cfg_clk_freq		<= CLK_FREQ;
		end else begin
			cfg_baud_rate 		<= cfg_baud_rate;
			cfg_lsb_first 		<= cfg_lsb_first;
			cfg_stop_bit  		<= cfg_stop_bit;
			cfg_parity_type 	<= cfg_parity_type;
			cfg_channel_enable 	<= cfg_channel_enable;
			cfg_clk_freq		<= cfg_clk_freq;
		end
	end

	assign s_axis_cfg_tready = !is_receiving && !is_transmitting;
	assign s_axis_tready     = !is_transmitting; 

	always @(posedge clk ) begin
		if(rst)begin
			is_transmitting_d1 <= 1'b0;
			is_receiving_d1	 <= 1'b0;
		end else begin
			is_transmitting_d1 <= is_transmitting;
			is_receiving_d1  <= is_receiving;
		end
	end

	assign	new_rx_data	= !is_receiving_d1 && is_receiving;
	assign  new_tx_data	= !is_transmitting_d1 && is_transmitting;


	baud_gen inst_baud_gen(
		.clk				(clk				),
		.rst				(rst				),
		.new_tx_data		(new_tx_data		),
		.ce_tx				(ce_tx				),
		.new_rx_data		(new_rx_data		),
		.ce_rx				(ce_rx				),

		.cfg_baud_rate		(cfg_baud_rate		),
		.cfg_clk_freq		(cfg_clk_freq		),
		.cfg_stop_bit  		(cfg_stop_bit  		),
		.cfg_parity_type 	(cfg_parity_type 	)
	);
	
	uart_rx inst_uart_rx(
		.clk				(clk				),
		.rst				(rst				),
		.ce_rx				(ce_rx				),
		.rx_byte			(m_axis_tdata		),
		.received			(m_axis_tvalid		),
		.uart_rx			(uart_rxd			),
		.is_receiving		(is_receiving		),

		.cfg_lsb_first 		(cfg_lsb_first 		),
		.cfg_parity_type 	(cfg_parity_type 	),
		.cfg_channel_enable (cfg_channel_enable	)
	);

	uart_tx inst_uart_tx(
    	.clk				(clk				),
    	.rst				(rst				),
		.ce_tx				(ce_tx				),
    	.tx_byte			(s_axis_tdata		),
    	.transmit			(s_axis_tvalid		),
    	.uart_tx			(uart_txd			),
    	.is_transmitting	(is_transmitting    ),
		
		.cfg_lsb_first 		(cfg_lsb_first 		),
		.cfg_stop_bit  		(cfg_stop_bit  		),
		.cfg_parity_type 	(cfg_parity_type 	),
		.cfg_channel_enable (cfg_channel_enable	)
    );


	
endmodule
 
`resetall
