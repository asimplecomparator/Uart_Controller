`timescale 1ns/1ps
module io_test_uart_tb();

parameter INPUT_IO_WIDTH  = 2;
parameter OUTPUT_IO_WIDTH = 2;


    reg     clk_100m		;
    reg     reset_100m		;

    wire [OUTPUT_IO_WIDTH-1:0]   io_oe;
    wire [OUTPUT_IO_WIDTH-1:0]   io;
    reg  [31:0]                 baud_div;
    reg                         baud_load; 
    reg                         ttl_test_en;

    always #10 clk_100m = ~clk_100m;

    initial begin
        clk_100m   <= 1'b1;
        reset_100m <= 1'b1;
        ttl_test_en<= 1'b0;
        baud_div   <= 32'd1_000_000;
        baud_load  <= 1'b0;
        #100
        reset_100m <= 1'b0;
        #100
        baud_load  <= 1'b1;
        #20
        baud_load  <= 1'b0;
        #1000
        ttl_test_en<= 1'b1;
        // #40
        // cfg_en     <= 1'b0;
    end

    assign io_oe = 2'b10;


    io_test_uart #(
        .INPUT_IO_WIDTH     (INPUT_IO_WIDTH         ),
        .OUTPUT_IO_WIDTH    (OUTPUT_IO_WIDTH        )
    ) io_test_uart_inst (
        .clk                (clk_100m               ),
        .rstn               (~reset_100m            ),
        .en                 (ttl_test_en            ),
        .baud_load          (baud_load              ),
        .baud_div           (baud_div               ),

        .io_oe              (io_oe                  ),
        .io_o               (io                     ),
        .io_i               (io                     ),
        .io_i_r             (                       ),
        .state              (                       ),
        .state_valid        (                       ));

endmodule