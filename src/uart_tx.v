// +FHEADER-------------------------------------------------------------------------------
// Copyright (c) 2018-2023 Radsim. All rights reserved.
// ---------------------------------------------------------------------------------------
// Author        : Feiyu Wang
// Email         : wangfeiyu@radsim.com
// Department    : Hardware
// Create Data   : 04/10/2023 14:17:11
// Module Name   : uart_tx.v
// ---------------------------------------------------------------------------------------
// Revision      : 1.0 (04/10/2023)
// Description   : a uart controller of tx
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

module uart_tx(
    input	wire	    clk,
    input	wire	    rst,
    input   wire        ce_tx,
    input	wire [7:0]	tx_byte,
    input	wire	    transmit,
    output  reg 	    uart_tx,
    output  reg         is_transmitting,

    input  wire         cfg_lsb_first,	
    input  wire [1:0]   cfg_stop_bit,	    
    input  wire [1:0]   cfg_parity_type,	          
    input  wire         cfg_channel_enable
    );

    reg  [3:0]          cnt_bit;
    reg  [3:0]          data_length;
    reg  [8:0]          tx_buffer_lsb;
    reg  [8:0]          tx_buffer_msb;
    reg                 parity_bit_lsb;
    reg                 parity_bit_msb;

    always @( posedge clk ) begin
        if(rst)
            data_length <= 4'd0;
        else if(cfg_parity_type==0)
            data_length <= 4'd8 + cfg_stop_bit ;
        else 
            data_length <= 4'd8 + cfg_stop_bit + 1'b1; 
    end

    always @ ( posedge clk ) begin
        if(rst || ~cfg_channel_enable)
            is_transmitting <= 1'b0;
        else if(transmit && ~is_transmitting)
            is_transmitting <= 1'b1;
        else if(is_transmitting && (cnt_bit == data_length) && ce_tx)
            is_transmitting <= 1'b0;
        else
            is_transmitting <= is_transmitting;
    end

    always @ (posedge clk) begin
        if(rst || !is_transmitting)
            cnt_bit <= 4'd0;
        else if(ce_tx && is_transmitting)
            cnt_bit <= cnt_bit + 1'b1;
        else
            cnt_bit <= cnt_bit;
    end
    
    always @ (posedge clk) begin
        if(rst)begin
            tx_buffer_lsb <= 9'b0;
            parity_bit_lsb <= 1'b0;
            tx_buffer_msb <= 9'b0;
            parity_bit_msb <= 1'b0;
        end else if(!is_transmitting)begin
            tx_buffer_lsb <= {tx_byte,1'b0};
            parity_bit_lsb <= 1'b0;
            tx_buffer_msb <= {1'b0,tx_byte};
            parity_bit_msb <= 1'b0;
        end else if( ce_tx && is_transmitting )begin
            if(cfg_parity_type)begin
                if(cnt_bit <= 4'd7)begin
                    tx_buffer_lsb <= {1'b1,tx_buffer_lsb[8:1]};
                    parity_bit_lsb <= parity_bit_lsb + tx_buffer_lsb[1];
                    tx_buffer_msb <= {tx_buffer_msb[7:0],1'b1};
                    parity_bit_msb <= parity_bit_msb + tx_buffer_msb[8];
                end else if(cnt_bit == 4'd8)begin
                    if(cfg_parity_type==1)begin
                        tx_buffer_lsb[0] <= ~parity_bit_lsb;
                        tx_buffer_msb[8] <= ~parity_bit_lsb;
                    end else begin
                        tx_buffer_lsb[0] <= parity_bit_lsb;
                        tx_buffer_msb[8] <= parity_bit_lsb;
                    end
                end else begin
                        tx_buffer_lsb <= {1'b1,tx_buffer_lsb[8:1]};
                        tx_buffer_msb <= {tx_buffer_msb[7:0],1'b1};
                end
            end else begin
                tx_buffer_lsb <= {1'b1,tx_buffer_lsb[8:1]};
                tx_buffer_msb <= {tx_buffer_msb[7:0],1'b1};
            end
        end else begin
            tx_buffer_lsb <= tx_buffer_lsb;
            tx_buffer_msb <= tx_buffer_msb;
        end
    end

    always @ ( posedge clk ) begin
        if(rst)
            uart_tx <= 1'b1;
        else if (is_transmitting)begin
            if(cfg_lsb_first)
                uart_tx <= tx_buffer_lsb[0];
            else
                uart_tx <= tx_buffer_msb[8];
        end else
            uart_tx <= 1'b1;
    end




endmodule

`resetall