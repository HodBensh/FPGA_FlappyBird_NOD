// Drawing the pipe with code instead of a bitmap

module pipeBitMap (
    input  logic clk,
    input  logic resetN,
    input  logic [10:0] offsetX,         // from pipe_object (0 to 99)
    input  logic [10:0] offsetY,         // from pipe_object (0 to 479)
    input  logic signed [10:0] transparentGapY, // Need this to know where to draw the pipe caps!
    input  logic InsideRectangle,        // drawingRequest from pipe_object
	 input  logic [7:0] gap_height,
	 
    output logic drawingRequest,
    output logic [7:0] RGBout
);

localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF;

localparam logic [7:0] COLOR_OUTLINE   = 8'b000_000_00; // Black 
localparam logic [7:0] COLOR_HIGHLIGHT = 8'b100_111_01; // Bright light green
localparam logic [7:0] COLOR_BASE      = 8'b010_110_00; // Main pipe green
localparam logic [7:0] COLOR_SHADOW    = 8'b001_011_00; // Dark green shadow

//localparam int GAP_HEIGHT = 150;
localparam int CAP_HEIGHT = 25;  

logic isCap;
logic [7:0] color;

// check if we are in the cap area
assign isCap = ((offsetY >= (transparentGapY - CAP_HEIGHT)) && (offsetY < transparentGapY)) ||
               ((offsetY >= (transparentGapY + gap_height)) && (offsetY < (transparentGapY + gap_height + CAP_HEIGHT)));

always_comb begin
    color = TRANSPARENT_ENCODING;
    
	 
    if (isCap) begin
        // cap drawing was 96 changed to 56
        // if (offsetX < 3 || offsetX > 96 || 
        if (offsetX < 3 || offsetX > 56 || 
            (offsetY == transparentGapY - CAP_HEIGHT) || // Top edge of top cap
            (offsetY == transparentGapY - 1) ||          // Bottom edge of top cap
            (offsetY == transparentGapY + gap_height) || // Top edge of bottom cap
            (offsetY == transparentGapY + gap_height + CAP_HEIGHT - 1)) // Bottom edge of bottom cap
            color = COLOR_OUTLINE;
        // else if (offsetX >= 3 && offsetX < 15)
        else if (offsetX >= 3 && offsetX < 10)
            color = COLOR_HIGHLIGHT;
        // else if (offsetX >= 15 && offsetX < 70)
        else if (offsetX >= 10 && offsetX < 43)
            color = COLOR_BASE;
        // else if (offsetX >= 70 && offsetX < 90)
        else if (offsetX >= 43 && offsetX < 54)
            color = COLOR_SHADOW;
        // else if (offsetX >= 90 && offsetX <= 96)
        else if (offsetX >= 54 && offsetX <= 56)
            color = COLOR_BASE;
    end
    else begin
        // body drawing
        // if (offsetX >= 4 && offsetX <= 95) begin
        if (offsetX >= 2 && offsetX <= 57) begin
            // if (offsetX < 7 || offsetX > 92)
            if (offsetX < 4 || offsetX > 55)
                color = COLOR_OUTLINE;
            // else if (offsetX >= 7 && offsetX < 17)
            else if (offsetX >= 4 && offsetX < 10)
                color = COLOR_HIGHLIGHT;
            // else if (offsetX >= 17 && offsetX < 68)
            else if (offsetX >= 10 && offsetX < 42)
                color = COLOR_BASE;
            // else if (offsetX >= 68 && offsetX < 86)
            else if (offsetX >= 42 && offsetX < 52)
                color = COLOR_SHADOW;
            // else if (offsetX >= 86 && offsetX <= 92)
            else if (offsetX >= 52 && offsetX <= 55)
                color = COLOR_BASE;
        end
    end
end

always_ff@(posedge clk or negedge resetN)
begin
    if(!resetN) begin
        RGBout <= 8'h00;
    end else begin
        RGBout <= TRANSPARENT_ENCODING; 
        if (InsideRectangle == 1'b1 && color != TRANSPARENT_ENCODING) begin 
            RGBout <= color;
        end  	
    end
end

// drawing request
assign drawingRequest = (RGBout != TRANSPARENT_ENCODING) ? 1'b1 : 1'b0; 

endmodule
