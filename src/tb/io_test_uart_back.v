// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module io_test_uart #(
    parameter INPUT_IO_WIDTH  = 32,
    parameter OUTPUT_IO_WIDTH = 32
) (
    input wire                          clk,
    input wire                          rstn,
    input wire                          en,

    input wire                          baud_load,
    input wire [31:0]                   baud_div,

    input  wire [OUTPUT_IO_WIDTH-1:0]   io_oe,
    output wire [OUTPUT_IO_WIDTH-1:0]   io_o,
    output wire [OUTPUT_IO_WIDTH-1:0]   io_o_r,
    input  wire [ INPUT_IO_WIDTH-1:0]   io_i,
    output wire [ INPUT_IO_WIDTH-1:0]   io_i_r,
    output reg  [ INPUT_IO_WIDTH-1:0]   state,
    output wire                         state_valid
);
    wire		uart_txd;

    reg [ 7:0]	s_axis_tdata;
    reg 		s_axis_tvalid;
    wire 		s_axis_tready;       
    reg  [ 8:0] cnt;
    
    wire [31:0]	                s_axis_cfg_tdata;
    wire 		                s_axis_cfg_tvalid;
    wire                        s_axis_cfg_tready;
    wire [INPUT_IO_WIDTH-1:0]   s_axis_cfg_tready_rx;

    assign s_axis_cfg_tvalid        = baud_load;
    assign s_axis_cfg_tdata[23:0]   = baud_div[23:0];
    assign s_axis_cfg_tdata[24]     = 1'b1;
    assign s_axis_cfg_tdata[26:25]  = 2'b1;
    assign s_axis_cfg_tdata[28:27]  = 2'b1;
    assign s_axis_cfg_tdata[29]     = 1'b1;

/******************************************************************/
/********************   TX      ***********************************/
/******************************************************************/
    genvar yy;
    generate 
        for (yy = 0; yy < OUTPUT_IO_WIDTH; yy = yy + 1)begin
            assign io_o_r[yy] = uart_txd;
            assign io_o[yy]   = (io_oe[yy]&en) ? io_o_r[yy] : 1'bz;
        end
    endgenerate
    
    uart_controller#(
        .BAUD_RATE          (10_000_000         ),
        .LSB_FIRST          (1                  ),
        .STOP_BIT           (1                  ),
        .PARITY_TYPE        (1                  ),
        .CLK_FREQ	        (100_000_000        )
    )inst_uart_controller_tx(      
        .clk                (clk                ),
        .rst                (!rstn              ),
        .uart_rxd           (1'b1               ),
        .uart_txd           (uart_txd           ),
        .s_axis_tdata       (s_axis_tdata       ),
        .s_axis_tvalid      (s_axis_tvalid      ),
        .s_axis_tready      (s_axis_tready      ),
        .s_axis_cfg_tdata   (s_axis_cfg_tdata   ),
        .s_axis_cfg_tvalid  (s_axis_cfg_tvalid  ),
        .s_axis_cfg_tready  (s_axis_cfg_tready  ));

    // sent increment data
    always @(posedge clk ) begin
        if(!(rstn&en))begin
            s_axis_tvalid <= 1'b0;
        end else if (s_axis_tready & (!cnt[8]))begin
            s_axis_tvalid <= 1'b1;
        end else begin
            s_axis_tvalid <= 1'b0;
        end
    end

    always @(posedge clk ) begin
        if(!(rstn&en))begin
            s_axis_tdata <= 8'b0;
            cnt <= 9'd0;
        end else if (s_axis_tready && s_axis_tvalid)begin
            s_axis_tdata <= s_axis_tdata + 1'b1;
            cnt <= cnt+1'b1;
        end else begin
            s_axis_tdata <= s_axis_tdata;
            cnt <= cnt;
        end
    end


/******************************************************************/
/********************     RX    ***********************************/
/******************************************************************/
    
    wire [ 7:0]	                        m_axis_tdata[INPUT_IO_WIDTH-1:0];
    wire [INPUT_IO_WIDTH-1:0]           m_axis_tvalid;
    reg  [3:0]                          io_i_reg[(INPUT_IO_WIDTH-1):0];
    reg  [7:0]                          data_cal[(INPUT_IO_WIDTH-1):0];
    reg  [(INPUT_IO_WIDTH-1):0]         error;



    // 输入移位寄存器
    genvar ii;
    generate
        for (ii = 0; ii < INPUT_IO_WIDTH; ii = ii + 1) begin
            uart_controller#(
                .BAUD_RATE          (10_000_000         ),
                .LSB_FIRST          (1                  ),
                .STOP_BIT           (1                  ),
                .PARITY_TYPE        (1                  ),
                .CLK_FREQ	        (100_000_000        )
            )inst_uart_controller_rx(      
                .clk                (clk                ),
                .rst                (!rstn              ),
                .uart_rxd           (io_i_r[ii]         ),
                .s_axis_tvalid      (1'b0               ),
                .m_axis_tdata       (m_axis_tdata[ii]   ),
                .m_axis_tvalid      (m_axis_tvalid[ii]  ),
                .s_axis_cfg_tdata   (s_axis_cfg_tdata   ),
                .s_axis_cfg_tvalid  (s_axis_cfg_tvalid  ),
                .s_axis_cfg_tready  (s_axis_cfg_tready_rx[ii]));

            always @(posedge clk) begin
                if (!(rstn&en)) begin
                    io_i_reg[ii][0] <= 1;
                    io_i_reg[ii][1] <= 1;
                    io_i_reg[ii][2] <= 1;
                    io_i_reg[ii][3] <= 1;
                end else begin
                    io_i_reg[ii][0] <= io_i[ii];
                    io_i_reg[ii][1] <= io_i_reg[ii][0];
                    io_i_reg[ii][2] <= io_i_reg[ii][1];
                    io_i_reg[ii][3] <= io_i_reg[ii][2];
                end
            end
            assign io_i_r[ii] = io_i_reg[ii][2];

            
            // check
            always @(posedge clk ) begin
                if(!(rstn&en))begin
                    data_cal[ii] <= 8'h00;
                    error[ii]	 <= 1'b0;
                end else if(m_axis_tvalid[ii])begin
                    data_cal[ii] <= data_cal[ii] + 1'b1;
                    error[ii]    <= (m_axis_tdata[ii]!=data_cal[ii]) | error[ii];
                end
            end

            always @(posedge clk) begin
                if (!(rstn&en)) begin
                    state[ii] <= 1'b0;
                end else if ((data_cal[ii]==8'hfe) & (!error[ii]) ) begin
                    state[ii] <= 1'b1;
                end else begin
                    state[ii] <= state[ii];
                end
            end

        end
    endgenerate

    assign state_valid = cnt[8];

    
    ila_0 ila_iotest (
        .clk        (clk                 ),      
        .probe0     (en                  ),// 1
        .probe1     (state               ),// 101
        .probe2     (state_valid         ),// 1
        .probe3     (io_oe               ),// 36
        .probe4     (io_o_r              ),// 36
        .probe5     (io_i_r              ),// 101
        .probe6     (error               ),// 101
        .probe7     (m_axis_tvalid       ) // 101 看收整个字节的切割
    );

endmodule