// SPI Master block with CS_n
//
/////////////////////////////////////////////////
//	SPI_MODE |		CPOL	|	CPHA 
//		0		|		0		|		0	
//		1		|		0		|		1
//		2		|		1		|		0
//		3		|		1		|		1
/////////////////////////////////////////////////
module SPI_Master_CS

	#( // Parameters
	parameter SPI_MODE 				= 0,
	parameter CLKS_PER_HALF_BIT 	= 2,
	parameter CS_INACTIVE_CLKS 	= 1,
	parameter MAX_BYTES_PER_CS 	= 3)

	(// FPGA Signals
	input clk, 
	input rst_n,
	
	// SPI MOSI Signals
	input [$clog2(MAX_BYTES_PER_CS+1)-1:0] i_TX_Count,
	input [7:0] 	i_TX_Byte,			// Byte to transmit
	input 			i_TX_En,				// Pulse for transmit 
	output 	 		o_TX_Ready,			// Ready to transmit next byte
	
	
	// SPI MISO Signals	
	output reg [$clog2(MAX_BYTES_PER_CS+1)-1:0] o_RX_Count,
	output [7:0] 	o_RX_Byte,	// Received byte from i_MISO
	output 			o_RX_En,		// Pulse then byte completed


	// SPI Interface
	output	o_MOSI,				// MOSI output
	output	o_SPCK,				// SPI Clock  
	input 	i_MISO,
	output 	o_CS_n	
	);
	
	// FSM States
	localparam IDLE 			= 2'b00;
	localparam TRANSFER		= 2'b01;
	localparam CS_INACTIVE 	= 2'b10; 

	reg [$clog2(MAX_BYTES_PER_CS+1)-1:0] r_TX_Count;
	reg [$clog2(CS_INACTIVE_CLKS+1)-1:0] r_CS_Inactive_Count;
	reg [1:0] r_FSM_CS;
	reg r_CS_n;
	wire w_Master_TX_Ready;

	// Instantiate SPI_Master_Base
	SPI_Master_Base
	#(.SPI_MODE(SPI_MODE),
	  .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT)
	 ) SPI_Master_Base_Inst 
	
	(
	// FPGA Signals
	.clk(clk),
	.rst_n(rst_n),

	// SPI Interface
	.i_MISO(i_MISO),
	.o_MOSI(o_MOSI),
	.o_SPCK(o_SPCK),

	// SPI MOSI Signals
	.i_TX_Byte(i_TX_Byte),			
	.i_TX_En(i_TX_En),				
	.o_TX_Ready(w_Master_TX_Ready),			
 	
	// SPI MISO Signals
	.o_RX_Byte(o_RX_Byte),
	.o_RX_En(o_RX_En)
	);

	// State machine for CS_n
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
		begin
			r_CS_Inactive_Count <= CS_INACTIVE_CLKS;
			r_CS_n 		<= 1'b1;
			r_TX_Count 	<= 1'b0;
			r_FSM_CS 	<= IDLE; 
		end
		else
		begin
			case(r_FSM_CS)
				
				IDLE:
				begin
					if (i_TX_En & r_CS_n)
					begin
						r_CS_n 		<= 1'b0;
						r_TX_Count	<= i_TX_Count - 1'b1;
						r_FSM_CS		<= TRANSFER;
					end
				end	
				
				TRANSFER:
				begin	
					if (w_Master_TX_Ready)
					begin
						if (r_TX_Count > 0)
						begin
							if (i_TX_En)
							begin
								r_TX_Count <= r_TX_Count - 1'b1;
							end
						end
						else
						begin
							r_CS_n  					<= 1'b1;
              			r_CS_Inactive_Count 	<= CS_INACTIVE_CLKS;
              			r_FSM_CS             <= CS_INACTIVE;
						end
					end	
				end

				CS_INACTIVE:
				begin
					if (r_CS_Inactive_Count > 0)
					begin
						r_CS_Inactive_Count <= r_CS_Inactive_Count - 1'b1;  
					end	
					else
					begin
						r_FSM_CS <= IDLE;
					end
				end
				
				default:
				begin
					r_FSM_CS 	<= IDLE;
					r_CS_n 		<= 1'b1;
				end	
			endcase
		end
	end
	
	// Count MISO bytes	
	always @(posedge clk)
	begin
		if(r_CS_n)
		begin
			o_RX_Count <= 0;
		end	
		else if (o_RX_En)
		begin
			o_RX_Count <= o_RX_Count + 1'b1;
		end
	end

	assign o_CS_n = r_CS_n;
	assign o_TX_Ready  = ((r_FSM_CS == IDLE) | (r_FSM_CS == TRANSFER && w_Master_TX_Ready == 1'b1 && r_TX_Count > 0)) & ~i_TX_En;

endmodule
