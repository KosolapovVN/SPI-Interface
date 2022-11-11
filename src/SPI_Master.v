// SPI Master base block (without CS_n)
//
/////////////////////////////////////////////////
//	SPI_MODE	|		CPOL	|		CPHA 
//		0		|		0		|		0	
//		1		|		0		|		1
//		2		|		1		|		0
//		3		|		1		|		1
/////////////////////////////////////////////////
module SPI_Master_Base
	
	#(	
	// Parameters
	parameter SPI_MODE = 0,
	parameter CLKS_PER_HALF_BIT = 2)	// SPCK = CLK/(2*CLK_PER_HALF_BIT)
	
	(	
	// FPGA Signals
	input clk, 
	input rst_n, 
	
	// SPI MOSI Signals
	input [7:0] i_TX_Byte,			// Byte to transmit
	input 		i_TX_En,			// Pulse for transmit 
	output reg	o_TX_Ready,			// Ready to transmit next byte
	
	// SPI MISO Signals	
	output reg [7:0] 	o_RX_Byte,		// Received byte from i_MISO
	output reg 			o_RX_En,		// Pulse then byte completed


	// SPI Interface
	output reg 	o_MOSI,				// MOSI output
	output reg 	o_SPCK,				// SPI Clock  
	input 		i_MISO
	);

	wire w_CPOL;						// SPCK polarity
	wire w_CPHA;						// SPCK phase 
	
	reg [$clog2(CLKS_PER_HALF_BIT*2)-1:0] r_SPCK_Count;
	reg [4:0] r_SPCK_Edges;				
	reg [2:0] r_TX_Bit_Count;
	reg [2:0] r_RX_Bit_Count;
	reg [7:0] r_TX_Byte;
	reg	r_Leading_Edge;
	reg r_Trailing_Edge;
	reg r_SPCK;
	reg r_TX_En;
	
    
	assign w_CPOL = (SPI_MODE == 2)|(SPI_MODE == 3);
	assign w_CPHA = (SPI_MODE == 1)|(SPI_MODE == 3);

	// Generation of SPCK
	always @(posedge clk or negedge rst_n)
	begin
		if (!rst_n) 
		begin
			o_TX_Ready 		<= 1'b0;
			r_SPCK_Edges 	<= 0;
			r_Leading_Edge  <= 1'b0;
     		r_Trailing_Edge <= 1'b0;
      		r_SPCK	       	<= w_CPOL;
      		r_SPCK_Count 	<= 0;
		end
		else 
		begin
			r_Leading_Edge  	<= 1'b0;
     		r_Trailing_Edge 	<= 1'b0;
			
			if (i_TX_En)
			begin	
				o_TX_Ready 		<= 1'b0;
				r_SPCK_Edges	<= 16;			
			end
			else if (r_SPCK_Edges > 0)
			begin
				o_TX_Ready 			<= 1'b0;
				
				if (r_SPCK_Count == CLKS_PER_HALF_BIT - 1)			// Half of bit
				begin
					r_SPCK_Edges 		<= r_SPCK_Edges - 1'b1;
					r_Leading_Edge 	<= 1'b1;							
					r_SPCK_Count 		<= r_SPCK_Count + 1'b1;
					r_SPCK 				<= ~r_SPCK;	
				end
				else if (r_SPCK_Count == 2*CLKS_PER_HALF_BIT - 1)	// Full bit
				begin
					r_SPCK_Edges 		<= r_SPCK_Edges - 1'b1;
					r_Trailing_Edge		<= 1'b1;							
					r_SPCK_Count 		<= 0;
					r_SPCK 				<= ~r_SPCK;	
				end
				else
				begin
					r_SPCK_Count 		<= r_SPCK_Count + 1'b1;	
				end
			end					
			else 
			begin
				o_TX_Ready			<= 1'b1;
			end
		end	
	end		

	// Fix input i_TX_Byte then i_TX_En is coming
	always @(posedge clk or negedge rst_n)	
	begin
		if (!rst_n)
		begin	
			r_TX_Byte	<= 8'h00;
			r_TX_En		<= 1'b0;				 		 		
		end
		else
		begin
			r_TX_En <= i_TX_En;
			if (i_TX_En)
			begin
				r_TX_Byte <= i_TX_Byte;
			end	 
		end
	end

	// Generate MOSI data
	always @(posedge clk or negedge rst_n)
	begin
		if (!rst_n)
		begin
			r_TX_Bit_Count 	<= 3'b111;		// MSB first
			o_MOSI 			<= 1'b0;
		end	
		else
		begin
			if (o_TX_Ready)
			begin
				r_TX_Bit_Count 	<= 3'b111;
			end
			else if (r_TX_En & ~ w_CPHA)		// first bit then CPHA = 0  
			begin
				o_MOSI 			<= r_TX_Byte[3'b111];
				r_TX_Bit_Count 	<= 3'b110;
			end
			else if ((r_Leading_Edge & w_CPHA) | (r_Trailing_Edge & ~ w_CPHA)) 
			begin
				o_MOSI 			<= r_TX_Byte[r_TX_Bit_Count];
				r_TX_Bit_Count 	<= r_TX_Bit_Count - 1'b1;	
			end
		end
	end

	// Receive data from i_MISO
	always @(posedge clk or negedge rst_n)
	begin
		if (!rst_n)
		begin
			o_RX_Byte		<= 8'h00;
			r_RX_Bit_Count 	<= 3'b111;
			o_RX_En			<= 1'b0;
		end
		else
		begin
			o_RX_En	<= 1'b0;
			
			if (o_TX_Ready)
			begin
				r_RX_Bit_Count 	<= 3'b111;
			end
			else if ((r_Leading_Edge & ~ w_CPHA) | (r_Trailing_Edge & w_CPHA))
			begin
				o_RX_Byte[r_RX_Bit_Count] 	<= i_MISO;
				r_RX_Bit_Count 				<= r_RX_Bit_Count - 1'b1;
				if (r_RX_Bit_Count == 0)
				begin
					o_RX_En <= 1'b1;
				end
			end
		end
	end


	// SPCK Delay adjustment
	always @(posedge clk or negedge rst_n)
	begin
	if (!rst_n)
		begin
			o_SPCK <= w_CPOL;	
		end
	else
		begin
			o_SPCK <= r_SPCK;
		end
	end

endmodule
