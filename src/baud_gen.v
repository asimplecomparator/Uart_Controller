// +FHEADER-------------------------------------------------------------------------------
// Copyright (c) 2018-2023 Radsim. All rights reserved.
// ---------------------------------------------------------------------------------------
// Author        : Feiyu Wang
// Email         : wangfeiyu@radsim.com
// Department    : Hardware
// Create Data   : 04/10/2023 14:17:11
// Module Name   : baud_gen.v
// ---------------------------------------------------------------------------------------
// Revision      : 1.0 (04/10/2023)
// Description   : a uart baud gen, include tx and rx
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
module baud_gen(
    input   wire        clk,
    input   wire        rst,
    input   wire        new_tx_data,
    output  reg         ce_tx,
    input   wire        new_rx_data,
    output  reg         ce_rx,
    input   wire [23:0] cfg_baud_rate,
    input   wire [ 1:0] cfg_stop_bit,	    
    input   wire [ 1:0] cfg_parity_type,
    input   wire [31:0] cfg_clk_freq
    );
    
    reg  [31:0]         baud_tx_cnt;
    reg  [ 3:0]         ce_tx_cnt;
    reg  [31:0]         baud_rx_cnt;
    reg  [ 3:0]         ce_rx_cnt;
    reg  [ 3:0]         ce_cnt_max;

    always @( posedge clk ) begin
        if(rst)
            ce_cnt_max <= 4'd0;
        else if(cfg_parity_type==0)
            ce_cnt_max <= 4'd10 + cfg_stop_bit ;
        else 
            ce_cnt_max <= 4'd11 + cfg_stop_bit ;
    end

    always @ (posedge clk) begin
        if(rst || new_tx_data)
            baud_tx_cnt <= cfg_baud_rate *3; 
            // due to delay of uart_tx fall to new_tx_data rise
            // 发送使能在T0时刻;
            // is_transmitting在T1时刻拉高;
            // new_tx_data在T2时刻拉高;
            // baud_tx_cnt在T3时刻开始计数;
            // 所以这里要多等3个周期;
            // 前提是起始位和发送使能是同步的。否则这个延时不成立。
            // 事实上，起始位下拉发生在T2时刻。
        else if(ce_tx_cnt==ce_cnt_max)
            baud_tx_cnt <= cfg_baud_rate *3; // Todo: don't use *, use +.
        else 
            baud_tx_cnt <= baud_tx_cnt + cfg_baud_rate;
    end

    always @(posedge clk ) begin
        if(rst || new_tx_data)begin
            ce_tx       <= 1'b0;
            ce_tx_cnt   <= 4'd1;
        end else if(baud_tx_cnt >= (cfg_clk_freq*ce_tx_cnt)) begin
            ce_tx       <= 1'b1;
            ce_tx_cnt   <= ce_tx_cnt + 1'b1;
        end else begin
            ce_tx       <= 1'b0;
            ce_tx_cnt   <= ce_tx_cnt;
        end
    end

    always @ (posedge clk) begin
        if(rst || new_rx_data) // we need new_rx_data to resync ce_rx and uart_rx
            baud_rx_cnt <= {1'b0,cfg_clk_freq[31:1]} + (cfg_baud_rate *4);
        else if(ce_rx_cnt==ce_cnt_max) 
        // we have to make sure ce_rx_cnt is accurate,that's say there shouldn't be useless ce_rx. 
            baud_rx_cnt <= {1'b0,cfg_clk_freq[31:1]} + (cfg_baud_rate *4);
        else 
            baud_rx_cnt <= baud_rx_cnt + cfg_baud_rate;
    end

    always @(posedge clk ) begin
        if(rst || new_rx_data)begin
            ce_rx <= 1'b0;
            ce_rx_cnt   <= 4'd1;
        end else if(baud_rx_cnt >= (cfg_clk_freq*ce_rx_cnt)) begin
            ce_rx <= 1'b1;
            ce_rx_cnt <= ce_rx_cnt + 1'b1;
        end else begin
            ce_rx <= 1'b0;
            ce_rx_cnt <= ce_rx_cnt;
        end
    end


 
endmodule
 
`resetall