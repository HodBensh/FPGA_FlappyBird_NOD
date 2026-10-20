// System-Verilog bitmap for Flappy Bird
// Based on the original smileyBitMap

module birdBitMap (	
    input  logic        clk,
    input  logic        resetN,
    input  logic [10:0] offsetX,         // offset from top left position 
    input  logic [10:0] offsetY,
    input  logic        InsideRectangle, // input that the pixel is within a bracket 

    output logic        drawingRequest,  // output that the pixel should be displayed 
    output logic [7:0]  RGBout           // rgb value from the bitmap 
);

// this is the divider used to access the right pixel 
localparam int OBJECT_NUMBER_OF_Y_BITS = 5;  // 2^5 = 32 
localparam int OBJECT_NUMBER_OF_X_BITS = 6;  // 2^6 = 64 
logic [10:0] address;

localparam logic [10:0] OBJECT_HEIGHT_Y = 11'b1 << OBJECT_NUMBER_OF_Y_BITS;
localparam logic [10:0] OBJECT_WIDTH_X  = 11'b1 << OBJECT_NUMBER_OF_X_BITS;

// Calculate the address for the ROM
assign address = (offsetY * OBJECT_WIDTH_X) + offsetX;

// generating the bird bitmap from a MIF file
logic [7:0] color;
localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF; // RGB value representing a transparent pixel 

lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(11),
    .LPM_NUMWORDS(2048),
    .LPM_FILE("RTL/bird.mif"), // <-- Change this to point to the new bird MIF file
    .LPM_TYPE("LPM_ROM"),
    .LPM_ADDRESS_CONTROL("REGISTERED"), 
    .LPM_OUTDATA("UNREGISTERED"), 
    .AUTO_CARRY_CHAINS("ON"),
    .AUTO_CASCADE_BUFFERS("ON"),
    .INTENDED_DEVICE_FAMILY("Cyclone V")  
) rom_inst (
    .address(address),
    .inclock(clk),
    .q(color)
);
 
// pipeline (ff) to get the pixel color from the ROM 	
always_ff@(posedge clk or negedge resetN)
begin
    if(!resetN) begin
        RGBout <= 8'h00;
    end
    else begin
        RGBout <= TRANSPARENT_ENCODING; // default transparency
        
        if (InsideRectangle == 1'b1) begin // inside the external bracket 
            RGBout <= color;
        end  	
    end
end

// decide if to draw the pixel or not 
// output '1' only if the color is not the transparent encoding
assign drawingRequest = (RGBout != TRANSPARENT_ENCODING) ? 1'b1 : 1'b0;

endmodule