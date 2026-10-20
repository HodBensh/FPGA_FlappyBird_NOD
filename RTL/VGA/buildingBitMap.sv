// Drawing the buildings with code instead of a bitmap

module buildingBitMap (
    input  logic clk,
    input  logic resetN,
    input  logic [10:0] offsetX,         // from pipe_object (0 to 99)
    input  logic [10:0] offsetY,         // from pipe_object (0 to 479)
    input  logic InsideRectangle,        // drawingRequest from pipe_object

    output logic drawingRequest,
    output logic [7:0] RGBout
);

localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF;

localparam logic [7:0] COLOR_OUTLINE   = 8'b11_011_110; // light Blue
localparam logic [7:0] COLOR_BASE      = 8'b11_110_111; // yellowish-green
localparam logic [7:0] COLOR_WINDOWS   = 8'b10_101_111; // Light Mint


logic [7:0] color;

always_comb begin
    color = TRANSPARENT_ENCODING;
    
    // Building 2 (Middle/Tallest): X: 80 to 140, Y: 80 to 480
    // (Checked first so it draws "behind" or "in front" if they overlap. They don't overlap much here)
    if (offsetX >= 80 && offsetX <= 140 && offsetY >= 80) begin
        // Top Roof Notch cut-out
        if (offsetY < 110 && offsetX > 115) begin
             color = TRANSPARENT_ENCODING; 
        end
        // Outlines (4 pixels thick)
        else if (offsetX < 84 || offsetX > 136 || offsetY < 84 || (offsetY < 114 && offsetX > 111))
            color = COLOR_OUTLINE;
        // Windows grid using Modulo!
        else if ((offsetX - 84) % 15 < 8 && (offsetY - 114) % 30 < 15)
            color = COLOR_WINDOWS;
        // Base wall color
        else
            color = COLOR_BASE;
    end
    
    // Building 1 (Left/Medium): X: 10 to 80, Y: 200 to 480
    else if (offsetX >= 10 && offsetX <= 80 && offsetY >= 200) begin
        // Left roof notch
        if (offsetY < 230 && offsetX < 30) begin
            color = TRANSPARENT_ENCODING;
        end
        else if (offsetX < 14 || offsetX > 76 || offsetY < 204 || (offsetY < 234 && offsetX < 34)) 
            color = COLOR_OUTLINE;
        else if ((offsetX - 34) % 15 < 8 && (offsetY - 234) % 25 < 12) 
            color = COLOR_WINDOWS;
        else
            color = COLOR_BASE;
    end

    // Building 3 (Right/Short): X: 140 to 193, Y: 250 to 480
    else if (offsetX >= 140 && offsetX <= 193 && offsetY >= 250) begin
        if (offsetX < 144 || offsetX > 189 || offsetY < 254)
            color = COLOR_OUTLINE;
        else if ((offsetX - 144) % 20 < 10 && (offsetY - 254) % 30 < 15) 
            color = COLOR_WINDOWS;
        else
            color = COLOR_BASE;
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
