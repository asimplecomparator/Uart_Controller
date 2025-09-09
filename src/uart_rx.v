// +FHEADER-------------------------------------------------------------------------------
// Copyright (c) 2018-2023 Radsim. All rights reserved.
// ---------------------------------------------------------------------------------------
// Author        : Feiyu Wang
// Email         : wangfeiyu@radsim.com
// Department    : Hardware
// Create Data   : 04/10/2023 14:17:11
// Module Name   : uart_rx.v
// ---------------------------------------------------------------------------------------
// Revision      : 1.0 (04/10/2023)
// Description   : a uart controller of rx
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
module uart_rx(
    input	wire	    clk,
    input	wire	    rst,
    input   wire        ce_rx,
    output	reg  [7:0]	rx_byte,
    output	reg 	    received,
    input   wire 	    uart_rx,
    output  reg         is_receiving,
    
    input  wire         cfg_lsb_first,	    
    input  wire [1:0]   cfg_parity_type,	          
    input  wire         cfg_channel_enable
    );
    reg  [ 3:0]         cnt_bit;
    wire [ 3:0]         data_length;
    reg  [ 7:0]         rx_buffer_lsb;
    reg  [ 7:0]         rx_buffer_msb;
    reg  [ 1:0]         sync_in;
    reg  [ 3:0]         sync_in_buffer;
    reg                 parity_bit_cal;
    reg                 parity_bit_sav;
    reg                 parity_error;

    always @ (posedge clk)begin 
        if (rst)
            sync_in <= 2'b11;
        else 
            sync_in <= {sync_in[0],uart_rx};
    end

    always @ (posedge clk)begin 
        if (rst)
            sync_in_buffer <= 4'b1111; // sampling four times
        else 
            sync_in_buffer <= {sync_in_buffer[3:1],sync_in[1]};
    end
    
    assign data_length = cfg_parity_type ? 4'd10 : 4'd9;

    always @ (posedge clk)begin 
        if (rst)
            is_receiving <= 1'b0;
        else if (~is_receiving & ~sync_in[1] & cfg_channel_enable)
            is_receiving <= 1'b1;
        else if (is_receiving & (cnt_bit == data_length) & ce_rx) 
            is_receiving <= 1'b0;
    end 

    always @ (posedge clk) begin
        if(rst || !is_receiving)
            cnt_bit <= 4'd0;
        else if(ce_rx && is_receiving)
            cnt_bit <= cnt_bit + 1'b1;
        else
            cnt_bit <= cnt_bit;
    end

    always @ (posedge clk) begin
        if(rst)begin
            parity_error <= 1'b0;
            rx_buffer_lsb <= 8'h00;
            rx_buffer_msb <= 8'h00;
            parity_bit_cal <= 1'b0;
            parity_bit_sav <= 1'b0;
        end else if(is_receiving && ce_rx) begin
            if(cfg_parity_type)begin
                if(cnt_bit <= 4'h8)begin
                    rx_buffer_lsb <= {sync_in[1],rx_buffer_lsb[7:1]};
                    rx_buffer_msb <= {rx_buffer_msb[6:0],sync_in[1]};
                    parity_bit_cal <= parity_bit_cal + sync_in[1];
                end else if(cnt_bit == 4'h9)begin
                    if(cfg_parity_type==2 && (sync_in[1]==(~parity_bit_cal)))
                        parity_error <= 1'b1;
                    else if(cfg_parity_type==1 && (sync_in[1]==parity_bit_cal))
                        parity_error <= 1'b1;
                    else
                        parity_error <= 1'b0;
                end
            end else begin
                rx_buffer_lsb <= {sync_in[1],rx_buffer_lsb[7:1]};
                rx_buffer_msb <= {rx_buffer_msb[6:0],sync_in[1]};
            end
        end else if (!is_receiving)begin
            parity_error <= 1'b0;
            rx_buffer_lsb  <= 8'd0;
            rx_buffer_msb  <= 8'd0;
            parity_bit_cal <= 1'b0;
            parity_bit_sav <= 1'b0;
        end else begin
            parity_error   <= parity_error  ;
            rx_buffer_lsb  <= rx_buffer_lsb ;
            rx_buffer_msb  <= rx_buffer_msb ;
            parity_bit_cal <= parity_bit_cal;
            parity_bit_sav <= parity_bit_sav;
        end
    end

    always @(posedge clk ) begin
        if(rst)begin
            rx_byte <= 8'h0;
            received <= 1'b0;
        end else if(is_receiving && (cnt_bit==data_length) && ce_rx)begin
            received <= ~parity_error;
            if(cfg_lsb_first)
                rx_byte <= rx_buffer_lsb;
            else
                rx_byte <= rx_buffer_msb;
        end else begin
            received <= 1'b0;
            rx_byte <= rx_byte;
        end
    end



endmodule
`resetall