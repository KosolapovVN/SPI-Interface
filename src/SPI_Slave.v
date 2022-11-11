// SPI_Slave module without MISO

module SPI_Slave

	#(
	// Parameters 
	parameter SPI_MODE = 0)

	(	
	// FPGA Signals
	input clk, rst_n,

	// Received Signals
	output reg [7:0]	o_RX_Byte,
	output reg 			o_RX_Ready,

	// SPI Interface
	input 		i_MOSI,
	input 		i_CS_n,
	input 		i_SPCK
	);

	reg r_RX_Ready, r1_RX_Ready, r2_RX_Ready;	// Fix data from SPCK clock domain  
	reg [7:0]	r_RX_Byte;
	reg [7:0]	r_RX_Bit_Count;
	reg [7:0]	r_Temp_RX_Byte;
	wire 		w_CPHA;
	wire		w_CPOL;
	wire		w_SPCK;

	assign w_CPHA = (SPI_MODE == 1) | (SPI_MODE == 3);
	assign w_CPOL = (SPI_MODE == 2) | (SPI_MODE == 3);
	assign w_SPCK = (w_CPHA ^ w_CPOL) ? ~i_SPCK : i_SPCK;

	always @(posedge w_SPCK or posedge i_CS_n)
  	begin
   	if (i_CS_n)
    	begin
      		r_RX_Bit_Count <= 0;
     		r_RX_Ready     <= 1'b0;
    	end
    	else
    	begin
     		r_RX_Bit_Count <= r_RX_Bit_Count + 1;
      		r_Temp_RX_Byte <= {r_Temp_RX_Byte[6:0], i_MOSI};
      		if (r_RX_Bit_Count == 3'b111)
      		begin
      			r_RX_Ready 		<= 1'b1;
        		r_RX_Byte 		<= {r_Temp_RX_Byte[6:0], i_MOSI};
				r_RX_Bit_Count	<= 1'b0;
      		end
      		else if (r_RX_Bit_Count == 3'b010)
      		begin
        		r_RX_Ready <= 1'b0;        
      		end
    	end 
  	end 

	always @(posedge clk or negedge rst_n)
  	begin
    	if (!rst_n)
    	begin
      		r1_RX_Ready		<= 1'b0;
      		r2_RX_Ready 	<= 1'b0;
      		o_RX_Ready 		<= 1'b0;
      		o_RX_Byte  		<= 8'h00;
    	end
    	else
    	begin
      		r1_RX_Ready 	<= r_RX_Ready;
      		r2_RX_Ready 	<= r2_RX_Ready;

      		if (r2_RX_Ready == 1'b0 && r1_RX_Ready == 1'b1) 
      		begin
        		o_RX_Ready  <= 1'b1;  
        		o_RX_Byte 	<= r_RX_Byte;
      		end
      		else
      		begin
        		o_RX_Ready 	<= 1'b0;
      		end
    	end 
  	end 
endmodule
