//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// System-Verilog Alex Grinshpun May 2018
// New coding convention dudy December 2018
// (c) Technion IIT, Department of Electrical Engineering 2021 


module	square_Pipe_object	(	
					input		logic	clk,
					input		logic	resetN,
					input 	logic signed	[10:0] pixelX,// current VGA pixel 
					input 	logic signed	[10:0] pixelY,
					input   logic signed [10:0] topLeftX,
					input   logic signed [10:0] transparentGapY,
					input   logic [7:0]  gap_height,
					
					output 	logic	[10:0] offsetX,// offset inside bracket from top left position 
					output 	logic	[10:0] offsetY,
					output	logic	drawingRequest, // indicates pixel inside the bracket
					output	logic	[7:0]	 RGBout //optional color output for mux 
);

// parameter  int OBJECT_WIDTH_X = 100;
parameter  int OBJECT_WIDTH_X = 60;
parameter  int OBJECT_HEIGHT_Y = 480;
// parameter  int GAP_HEIGHT = 150; 
parameter  logic [7:0] OBJECT_COLOR = 8'h5b ;
localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// bitmap  representation for a transparent pixel 
 
int rightX ; //coordinates of the sides  
int bottomGapY ;
logic insidePipe;

//////////--------------------------------------------------------------------------------------------------------------=
// Calculate object right  & bottom  boundaries
assign rightX	= (topLeftX + OBJECT_WIDTH_X);
// assign bottomGapY	= (transparentGapY + gap_height);
assign bottomGapY	= (transparentGapY + signed'({1'b0, gap_height}));
assign insidePipe = (
	(pixelX  >= topLeftX) &&  (pixelX < rightX)
	&&
	((pixelY >= bottomGapY) || (pixelY < (transparentGapY)))  
);


//////////--------------------------------------------------------------------------------------------------------------=
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout			<=	8'b0;
		drawingRequest	<=	1'b0;
	end
	else begin // DEFUALT
	      RGBout <= TRANSPARENT_ENCODING ; // so it will not be displayed 
			drawingRequest <= 1'b0 ;// transparent color 
			offsetX	<= 0; //no offset
			offsetY	<= 0; //no offset
	
		if (insidePipe) 
		begin 
			RGBout  <= OBJECT_COLOR ;	// colors table 
			drawingRequest <= 1'b1 ;
			offsetX	<= (pixelX - topLeftX); //calculate relative offsets from top left corner
			offsetY	<= (pixelY);
		end 
		

		
	end
end 
endmodule 