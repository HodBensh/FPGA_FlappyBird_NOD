// (c) Technion IIT, Department of Electrical Engineering 2025 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018
//-- Eyal Lev 31 Jan 2021

module objects_mux_with_box (	
// -------- Clock Input 	
    input  logic       clk,
    input  logic       resetN,
    // smiley 
    input  logic       birdDrawingRequest, // two set of inputs per unit
    input  logic [7:0] birdRGB, 
    
    input  logic       scoreDrawingRequest,
    input  logic [7:0] RGBScore,
    input  logic       gameActiveMode,
    
    input  logic       pipeDrawingRequest, 
    input  logic [7:0] pipeRGB,   
    
    input  logic       buildingDrawingRequest, 
    input  logic [7:0] buildingRGB,  
	 
	input  logic       starDrawingRequest, 
    input  logic [7:0] starRGB,
	
    input  logic       powerBarDrawingRequest, 
    input  logic [7:0] powerBarRGB,
    input  logic       shield_active,

    input  logic       startFBDrawingRequest, 
    input  logic [7:0] startFBRGB, 

    input  logic       startPEDrawingRequest, 
    input  logic [7:0] startPERGB,  	
    
    input  logic       gameOverDrawingRequest, 
    input  logic [7:0] gameOverRGB,  	
    
    input  logic [7:0] backGroundRGB, 

    // Feature 2: Dark Mode inputs
    input  logic       dark_mode,
    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,

    output logic [7:0] RGBOut
);

// Bird center coordinates
// Horizontal center of the bird (INITIAL_X = 100, width = 64, center = 132)
localparam logic [10:0] BIRD_CENTER_X = 11'd132;

// Vertical center dynamically captured from the bird drawing request
logic [10:0] bird_center_y_latched;
logic [10:0] bird_center_y_captured;
logic        seen_bird_this_frame;

always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        bird_center_y_latched  <= 11'd240;
        bird_center_y_captured <= 11'd240;
        seen_bird_this_frame   <= 1'b0;
    end else begin
        // At the start of a frame, latch the captured center Y for the new frame
        if (pixelY == 11'd0 && pixelX == 11'd0) begin
            bird_center_y_latched <= bird_center_y_captured;
            seen_bird_this_frame  <= 1'b0;
        end else if (birdDrawingRequest && !seen_bird_this_frame) begin
            seen_bird_this_frame   <= 1'b1;
            bird_center_y_captured <= pixelY + 11'd16; // Top of bird + half height (16 px)
        end
    end
end

logic [3:0] frame_cnt;
always_ff @(posedge clk or negedge resetN) begin
    if (!resetN)
        frame_cnt <= 4'd0;
    else if (pixelY == 11'd0 && pixelX == 11'd0)
        frame_cnt <= frame_cnt + 4'd1;
end

// Distance calculation (squared Euclidean distance)
logic [10:0] dx;
logic [10:0] dy;
logic [21:0] dist_sq;

assign dx = (pixelX >= BIRD_CENTER_X) ? (pixelX - BIRD_CENTER_X) : (BIRD_CENTER_X - pixelX);
assign dy = (pixelY >= bird_center_y_latched) ? (pixelY - bird_center_y_latched) : (bird_center_y_latched - pixelY);
assign dist_sq = (dx * dx) + (dy * dy);

// Spotlight distance rings:
// Inner: R <= 120 (R^2 <= 14400) -> 100% full brightness
// Mid:   R <= 180 (R^2 <= 32400) -> 50% intensity
// Outer: R <= 250 (R^2 <= 62500) -> 25% intensity
// Dark:  R > 250                 -> 0% pitch black
localparam logic [21:0] RADIUS_INNER_SQ = 22'd14400; // R = 120 px
localparam logic [21:0] RADIUS_MID_SQ   = 22'd32400; // R = 180 px
localparam logic [21:0] RADIUS_OUTER_SQ = 22'd62500; // R = 250 px

logic [1:0] light_level;
always_comb begin
    if (dist_sq <= RADIUS_INNER_SQ)
        light_level = 2'd3; // 100%
    else if (dist_sq <= RADIUS_MID_SQ)
        light_level = 2'd2; // 50%
    else if (dist_sq <= RADIUS_OUTER_SQ)
        light_level = 2'd1; // 25%
    else
        light_level = 2'd0; // Pitch black
end

// Multiplexer logic to select the base color
logic [7:0] raw_RGB;
logic       is_bird_pixel;
logic       is_score_pixel;
logic       is_star_pixel;

always_comb begin
    is_bird_pixel  = 1'b0;
    is_score_pixel = 1'b0;
    is_star_pixel  = 1'b0;

    if (starDrawingRequest == 1'b1) begin
		raw_RGB = starRGB;
        is_star_pixel = 1'b1;
	end
    else if (powerBarDrawingRequest == 1'b1) begin   // NEW
        raw_RGB       = powerBarRGB;
        is_star_pixel = 1'b1;
    end
	else if (birdDrawingRequest == 1'b1) begin
        raw_RGB       = (shield_active && frame_cnt[3]) ? (birdRGB | 8'b100_100_10) : birdRGB;
        is_bird_pixel = 1'b1;
    end
    else if (startFBDrawingRequest == 1'b1) begin
        raw_RGB = startFBRGB;
    end
    else if (startPEDrawingRequest == 1'b1) begin
        raw_RGB = startPERGB;
    end
    else if (gameOverDrawingRequest == 1'b1) begin
        raw_RGB = gameOverRGB;
    end
    else if (scoreDrawingRequest == 1'b1 && gameActiveMode) begin
        raw_RGB        = RGBScore;
        is_score_pixel = 1'b1;
    end
    else if (pipeDrawingRequest == 1'b1) begin
        raw_RGB = pipeRGB;
    end
    else if (buildingDrawingRequest == 1'b1) begin
        raw_RGB = buildingRGB;
    end
    else begin
        raw_RGB = backGroundRGB; // last priority
    end
end

// Dark Mode Dimming logic:
// VGA DAC Format: {Blue[7:5], Green[4:2], Red[1:0]}
logic [7:0] final_RGB;
always_comb begin
    if (dark_mode && gameActiveMode && !is_bird_pixel && !is_score_pixel && !is_star_pixel) begin
        case (light_level)
            2'd3: final_RGB = raw_RGB; // 100%
            2'd2: final_RGB = {1'b0, raw_RGB[7:6], 1'b0, raw_RGB[4:3], 1'b0, raw_RGB[1]}; // 50%
            2'd1: final_RGB = {2'b00, raw_RGB[7], 2'b00, raw_RGB[4], 2'b00};              // 25%
            default: final_RGB = 8'h00; // Pitch black
        endcase
    end else begin
        final_RGB = raw_RGB;
    end
end

always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        RGBOut <= 8'b0;
    end else begin
        RGBOut <= final_RGB;
    end
end

endmodule
