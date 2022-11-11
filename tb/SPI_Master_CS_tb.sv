// Testbench for "SPI_Master_CS"

`timescale 1ns/1ns
`include "SPI_Master.v"

module SPI_Master_CS_tb();

	// Parameters
	parameter CS_INACTIVE_CLKS	= 5;
	parameter MAX_BYTES_PER_CS 	= 10;
	parameter CLKS_PER_HALF_BIT	= 4;
	parameter MAIN_CLK_DELAY 	= 2;
	parameter SPI_MODE = 0;
	
	// Main control
	logic r_rst_n 	= 1'b0;
	logic r_clk		= 1'b0;
	
	// SPI Interface main ports
	logic w_MOSI;
	logic w_SPCK;
	logic w_CS_n;
	
	// User interface data load
	logic [$clog2(MAX_BYTES_PER_CS+1)-1:0] w_Master_RX_Count;
	logic [$clog2(MAX_BYTES_PER_CS+1)-1:0] r_Master_TX_Count = MAX_BYTES_PER_CS;
	logic [7:0] r_Master_TX_Byte = 8'h00;
	logic [7:0] r_Master_RX_Byte;
	logic r_Master_TX_En = 1'b0;
	logic w_Master_TX_Ready;
	logic r_Master_RX_EN;
	
	// Variables
	logic [7:0] i;

	always #(MAIN_CLK_DELAY) r_clk = ~ r_clk;

	// Describe UUT
	SPI_Master_CS
	#(.SPI_MODE(SPI_MODE), 
	  .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT),
	  .CS_INACTIVE_CLKS(CS_INACTIVE_CLKS),
	  .MAX_BYTES_PER_CS(MAX_BYTES_PER_CS)) SPI_Master_CS_UUT

	(
	// Control Signals
	.rst_n(r_rst_n),
	.clk(r_clk),
	
	// SPI Interface signals 
	.o_MOSI(w_MOSI),
	.i_MISO(w_MOSI),
	.o_SPCK(w_SPCK),
	.o_CS_n(w_CS_n),
	
	// MOSI signals
	.i_TX_Byte(r_Master_TX_Byte),
	.i_TX_En(r_Master_TX_En),
	.o_TX_Ready(w_Master_TX_Ready),
	.i_TX_Count(r_Master_TX_Count),
	
	// MISO signals
	.o_RX_Byte(r_Master_RX_Byte),
	.o_RX_En(r_Master_RX_En),
	.o_RX_Count(w_Master_RX_Count)
	);
	
	// Task to send one byte
	task SendByte(input [7:0] data);
		@(posedge r_clk);
		r_Master_TX_Byte 	<= data;
		r_Master_TX_En 	<= 1'b1;
		@(posedge r_clk);
		r_Master_TX_En	<= 1'b0;
		@(posedge w_Master_TX_Ready);
	endtask

	initial
	begin
		repeat(10) @(posedge r_clk);
      	r_rst_n = 1'b0;
      	repeat(10) @(posedge r_clk);
      	r_rst_n = 1'b1;
      	repeat(10) @(posedge r_clk);
      
		for (i = 1; i < MAX_BYTES_PER_CS + 1; i = i + 1)
		begin
			SendByte(i);
			$display("Sent out 0x%X", i, "  Received 0x%X", r_Master_RX_Byte); 
      	end  
		repeat(10) @(posedge r_clk);	
	end	
endmodule
