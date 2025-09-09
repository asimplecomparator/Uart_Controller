// +FHEADER-------------------------------------------------------------------------------
// Copyright (c) 2018-2023 Radsim. All rights reserved.
// ---------------------------------------------------------------------------------------
// Author        : Feiyu Wang
// Email         : wangfeiyu@radsim.com
// Department    : Hardware
// Create Data   : 04/10/2023 14:17:11
// Module Name   : uart_controller_tb.v
// ---------------------------------------------------------------------------------------
// Revision      : 1.0 (04/10/2023)
// Description   : a uart controller testbench
// Revision 1.00 - File Created
// ---------------------------------------------------------------------------------------
// Reuse Issue   : 
// Clock Domains : clk
// Synthesizable : no
// Reset Strategy: Sync Reset, Active High
// Instantiations: no
// Other : 
// -FHEADER-------------------------------------------------------------------------------
`resetall
`timescale 1ns / 1ps
`default_nettype none

module uart_controller_tb();

    reg 		clk;
    reg 		rst;

    wire		uart_rxd;
    wire		uart_txd;

    reg [ 7:0]	s_axis_tdata;
    reg 		s_axis_tvalid;
    wire 		s_axis_tready;

    wire [ 7:0]	m_axis_tdata;
    wire    	m_axis_tvalid;

    wire [31:0]	s_axis_cfg_tdata;
    wire 		s_axis_cfg_tvalid;
    wire        s_axis_cfg_tready;

    reg  [ 7:0] data_cal;
    reg         error;
    reg  [ 3:0] cnt;


    always #10 clk<= ~clk;

    initial begin
        clk <= 1'b0;
        rst <= 1'b1;
        #20
        rst <= 1'b0;
    end 

    assign  s_axis_cfg_tvalid = 1'b0;

    
    uart_controller#(
        .BAUD_RATE          (10_000_000         ),
        .LSB_FIRST          (1                  ),
        .STOP_BIT           (1                  ),
        .PARITY_TYPE        (1                  ),
        .CLK_FREQ	        (100_000_000        )
    )inst_uart_controller(      
        .clk                (clk                ),
        .rst                (rst                ),
        .uart_rxd           (uart_txd           ),
        .uart_txd           (uart_txd           ),
        .s_axis_tdata       (s_axis_tdata       ),
        .s_axis_tvalid      (s_axis_tvalid      ),
        .s_axis_tready      (s_axis_tready      ),
        .m_axis_tdata       (m_axis_tdata       ),
        .m_axis_tvalid      (m_axis_tvalid      ),
        .s_axis_cfg_tdata   (s_axis_cfg_tdata   ),
        .s_axis_cfg_tvalid  (s_axis_cfg_tvalid  ),
        .s_axis_cfg_tready  (s_axis_cfg_tready  )
    );


/************sent and recieve **************************************/
    // sent increment data
    always @(posedge clk ) begin
        if(rst)begin
            s_axis_tvalid <= 1'b0;
            cnt <= 4'd0;
        end else if (s_axis_tready  )begin
            s_axis_tvalid <= 1'b1;
            cnt <= cnt+1'b1;
        end else begin
            s_axis_tvalid <= 1'b0;
            cnt <= cnt;
        end
    end

    always @(posedge clk ) begin
        if(rst)begin
            s_axis_tdata <= 8'b0;
        end else if (s_axis_tready && s_axis_tvalid)begin
            s_axis_tdata <= s_axis_tdata + 1'b1;
        end
    end

    // check
    always @(posedge clk ) begin
		if(rst)begin
			data_cal <= 8'h00;
			error	 <= 1'b0;
		end else if(m_axis_tvalid)begin
			data_cal <= data_cal + 1'b1;
			error    <= (m_axis_tdata!=data_cal);
		end
	end


/************ recieve and sent **************************************/
//	reg  [ 7:0] s_axis_tdata_reg;
//	reg         s_axis_tvalid_reg;
//
//	assign s_axis_tdata = s_axis_tdata_reg;
//	assign s_axis_tvalid = s_axis_tvalid_reg;
//
//	always @(posedge clk ) begin
//		if(rst)begin
//			s_axis_tdata_reg <= 8'd0;
//			s_axis_tvalid_reg <= 1'b0;
//		end else if (m_axis_tvalid)begin
//			s_axis_tdata_reg <= m_axis_tdata;
//			s_axis_tvalid_reg <= 1'b1;
//		end else if (s_axis_tready && s_axis_tvalid)begin
//			s_axis_tdata_reg <= s_axis_tdata_reg;
//			s_axis_tvalid_reg <= 1'b0;
//		end else begin 
//			s_axis_tdata_reg <= s_axis_tdata_reg;
//			s_axis_tvalid_reg <= s_axis_tvalid_reg;
//		end
//	end


    



endmodule

`resetall