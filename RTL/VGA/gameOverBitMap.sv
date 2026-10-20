// System-Verilog bitmap for Flappy Bird
// Based on the original smileyBitMap
// Option 2: Enhanced 12x24 score & high-score display with generous 15px vertical row spacing

module gameOverBitMap (	
    input  logic        clk,
    input  logic        resetN,
    input  logic [10:0] offsetX,         // offset from top left position 
    input  logic [10:0] offsetY,
    input  logic        InsideRectangle, // input that the pixel is within a bracket 

    // Score inputs for the Game Over scoreboard display
    input  logic [3:0]  scoreTens,
    input  logic [3:0]  scoreOnes,
    input  logic [3:0]  highestScoreTens,
    input  logic [3:0]  highestScoreOnes,

    output logic        drawingRequest,  // output that the pixel should be displayed 
    output logic [7:0]  RGBout           // rgb value from the bitmap 
);

// this is the divider used to access the right pixel 
localparam int OBJECT_NUMBER_OF_Y_BITS = 8;  // 2^8 = 256 
localparam int OBJECT_NUMBER_OF_X_BITS = 8;  // 2^8 = 256 
logic [15:0] address;

localparam logic [10:0] OBJECT_HEIGHT_Y = 11'b1 << OBJECT_NUMBER_OF_Y_BITS;
localparam logic [10:0] OBJECT_WIDTH_X  = 11'b1 << OBJECT_NUMBER_OF_X_BITS;

// Calculate the address for the background card ROM
assign address = (offsetY * OBJECT_WIDTH_X) + offsetX;

// generating the game over bitmap from a MIF file
logic [7:0] color;
localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF; // RGB value representing a transparent pixel 

lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(16),
    .LPM_NUMWORDS(65536),
    .LPM_FILE("RTL/GameOver.mif"),
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

// =========================================================================
// Score Digits Overlay Engine (12x24 scaled digits, 15px gap between rows)
// =========================================================================
parameter logic [7:0] SCORE_COLOR        = 8'hFC; // Retro bright yellow for YOUR SCORE
parameter logic [7:0] HIGH_SCORE_COLOR   = 8'hEC; // Retro warm gold/orange for HIGH SCORE
parameter bit         BLANK_LEADING_ZERO = 1'b0; // 0: show 05, 1: blank tens digit if zero

logic        is_score_digit;
logic [3:0]  current_digit;
logic [3:0]  digit_offsetX; // 0..15 inside native 16x32 font
logic [4:0]  digit_offsetY; // 0..31 inside native 16x32 font
logic [7:0]  digit_color_target;

always_comb begin
    is_score_digit     = 1'b0;
    current_digit      = 4'd0;
    digit_offsetX      = 4'd0;
    digit_offsetY      = 5'd0;
    digit_color_target = SCORE_COLOR;

    // Row 1: "YOUR SCORE" row (Y in [98..121], height = 24 px)
    if (offsetY >= 11'd98 && offsetY <= 11'd121) begin
        // Map 0..23 (24 px height) to native 0..31 font height using *4/3
        digit_offsetY      = ((offsetY - 11'd98) * 4) / 3;
        digit_color_target = SCORE_COLOR;

        // Tens digit: X in [192..203] (width = 12 px)
        if (offsetX >= 11'd192 && offsetX <= 11'd203) begin
            if (!(BLANK_LEADING_ZERO && scoreTens == 4'd0)) begin
                is_score_digit = 1'b1;
                // Map 0..11 (12 px width) to native 0..15 font width using *4/3
                digit_offsetX  = ((offsetX - 11'd192) * 4) / 3;
                current_digit  = scoreTens;
            end
        end
        // Ones digit: X in [208..219] (width = 12 px)
        else if (offsetX >= 11'd208 && offsetX <= 11'd219) begin
            is_score_digit = 1'b1;
            digit_offsetX  = ((offsetX - 11'd208) * 4) / 3;
            current_digit  = scoreOnes;
        end
    end
    // Row 2: "HIGH SCORE" row (Y in [136..159], height = 24 px, 15px gap from Row 1!)
    else if (offsetY >= 11'd136 && offsetY <= 11'd159) begin
        digit_offsetY      = ((offsetY - 11'd136) * 4) / 3;
        digit_color_target = HIGH_SCORE_COLOR;

        // Tens digit: X in [192..203] (width = 12 px)
        if (offsetX >= 11'd192 && offsetX <= 11'd203) begin
            if (!(BLANK_LEADING_ZERO && highestScoreTens == 4'd0)) begin
                is_score_digit = 1'b1;
                digit_offsetX  = ((offsetX - 11'd192) * 4) / 3;
                current_digit  = highestScoreTens;
            end
        end
        // Ones digit: X in [208..219] (width = 12 px)
        else if (offsetX >= 11'd208 && offsetX <= 11'd219) begin
            is_score_digit = 1'b1;
            digit_offsetX  = ((offsetX - 11'd208) * 4) / 3;
            current_digit  = highestScoreOnes;
        end
    end
end

// Address calculation into numbers.mif (512 words per digit: 16 wide * 32 high)
logic [12:0] num_address;
assign num_address = {current_digit[3:0], digit_offsetY[4:0], digit_offsetX[3:0]};

logic num_pixel;

lpm_rom #(
    .LPM_WIDTH(1),
    .LPM_WIDTHAD(13),
    .LPM_NUMWORDS(8192),
    .LPM_FILE("RTL/numbers.mif"),
    .LPM_TYPE("LPM_ROM"),
    .LPM_ADDRESS_CONTROL("REGISTERED"), 
    .LPM_OUTDATA("UNREGISTERED"), 
    .AUTO_CARRY_CHAINS("ON"),
    .AUTO_CASCADE_BUFFERS("ON"),
    .INTENDED_DEVICE_FAMILY("Cyclone V")  
) num_rom_inst (
    .address(num_address),
    .inclock(clk),
    .q(num_pixel)
);

// Pipeline matching flip-flop (1 cycle delay to align with ROM read)
logic       is_score_digit_d;
logic [7:0] digit_color_target_d;

always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        is_score_digit_d     <= 1'b0;
        digit_color_target_d <= SCORE_COLOR;
    end else begin
        is_score_digit_d     <= is_score_digit;
        digit_color_target_d <= digit_color_target;
    end
end

// Final output stage (Cycle 2)
always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        RGBout <= 8'h00;
    end
    else begin
        RGBout <= TRANSPARENT_ENCODING; // default transparency
        
        if (InsideRectangle == 1'b1) begin // inside the external bracket 
            // If on a solid score pixel, display the score color; otherwise background card
            if (is_score_digit_d && (num_pixel == 1'b1)) begin
                RGBout <= digit_color_target_d;
            end else begin
                RGBout <= color;
            end
        end  	
    end
end

// decide if to draw the pixel or not 
assign drawingRequest = (RGBout != TRANSPARENT_ENCODING) ? 1'b1 : 1'b0;

endmodule
