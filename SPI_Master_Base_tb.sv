`timescale 1ns/1ns
module SPI_Master_Base_tb();

	// Parameters
	parameter SPI_MODE = 0;
	parameter CLKS_PER_HALF_BIT = 4;
	parameter MAIN_CLK_DELAY = 2;

	// Main control
	logic r_rst_n 		= 1'b0;
	logic r_clk			= 1'b0;
	
	// SPI Interface main ports
	logic w_MOSI;
	logic w_SPCK;
	
	// User interface data load
	logic [7:0] r_Master_TX_byte	= 8'h00;
	logic r_Master_TX_En				= 1'b0;
	logic w_Master_TX_Ready;
	logic [7:0] r_Master_RX_byte;
	logic r_Master_RX_EN;

	always #(MAIN_CLK_DELAY) r_clk = ~ r_clk;

	// Describe UUT
	SPI_Master_Base
	#(.SPI_MODE(SPI_MODE), 
	  .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT)) SPI_Master_Base_UUT

	(
	// Control/Data Signals
	.rst_n(r_rst_n),
	.clk(r_clk),
	
	// SPI Interface signals 
	.o_MOSI(w_MOSI),
	.i_MISO(w_MOSI),
	.o_SPCK(w_SPCK),
	
	// MOSI signals
	.i_TX_byte(r_Master_TX_byte),
	.i_TX_En(r_Master_TX_En),
	.o_TX_Ready(w_Master_TX_Ready),
	
	// MISO signals
	.o_RX_byte(r_Master_RX_byte),
	.o_RX_En(r_Master_RX_En)	

	);
	
	// Task to send one byte
	task SendByte(input [7:0] data);
		@(posedge r_clk);
		r_Master_TX_byte 	<= data;
		r_Master_TX_En 	<= 1'b1;
		@(posedge r_clk);
		r_Master_TX_En		<= 1'b0;
		@(posedge w_Master_TX_Ready);
	endtask

	initial
	begin
		repeat(10) @(posedge r_clk);
      r_rst_n = 1'b0;
      repeat(10) @(posedge r_clk);
      r_rst_n = 1'b1;
       repeat(10) @(posedge r_clk);
      SendByte(8'hF1);
		$display("Sent out 0xF1, Received 0x%X", r_Master_RX_byte); 
      SendByte(8'h0E);
		$display("Sent out 0x0E, Received 0x%X", r_Master_RX_byte); 
 		SendByte(8'h0F);
      $display("Sent out 0x0F, Received 0x%X", r_Master_RX_byte);       
		repeat(10) @(posedge r_clk);	
	end	

endmodule
