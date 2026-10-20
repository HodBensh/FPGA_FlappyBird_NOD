module powerBarBitMap (
    input  logic        clk,
    input  logic        resetN,
    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,
    input  logic        visible,        
    input  logic [3:0]  power_level,    

    output logic        drawingRequest,
    output logic [7:0]  RGBout
);


parameter int BAR_X   = 616;   // left edge (star is at 580..611)
parameter int BAR_Y   = 140;   // top edge incl. frame
parameter int BAR_W   = 16;
parameter int LEVEL_H = 19;    // pixels per level

localparam int BAR_H        = 10 * LEVEL_H + 2;     // 192 (1px frame top+bottom)
localparam int INNER_BOTTOM = BAR_Y + BAR_H - 2;    // last inner row

localparam logic [7:0] TRANSPARENT  = 8'hFF;
localparam logic [7:0] COLOR_FRAME  = 8'b000_000_00; // black
localparam logic [7:0] COLOR_EMPTY  = 8'b010_010_01; // dark grey
localparam logic [7:0] COLOR_GREEN  = 8'b000_111_00;
localparam logic [7:0] COLOR_YELLOW = 8'b111_111_00;
localparam logic [7:0] COLOR_RED    = 8'b111_000_00;


int   fill_top;
logic inside_bar;
logic on_frame;
logic [7:0] color_c;
logic [7:0] color_d;

assign fill_top   = INNER_BOTTOM + 1 - (int'(power_level) + 1) * LEVEL_H;

assign inside_bar = (pixelX >= BAR_X) && (pixelX < BAR_X + BAR_W) &&
                    (pixelY >= BAR_Y) && (pixelY < BAR_Y + BAR_H);

assign on_frame   = (pixelX == BAR_X) || (pixelX == BAR_X + BAR_W - 1) ||
                    (pixelY == BAR_Y) || (pixelY == BAR_Y + BAR_H - 1);

always_comb begin
    color_c = TRANSPARENT;
    if (visible && inside_bar) begin
        if (on_frame)
            color_c = COLOR_FRAME;
        else if (pixelY >= fill_top) begin
            // color depends on row: green at bottom (low power), red at top (high power)
            if (pixelY > INNER_BOTTOM - 63)       color_c = COLOR_GREEN;
            else if (pixelY > INNER_BOTTOM - 127)  color_c = COLOR_YELLOW;
            else                                    color_c = COLOR_RED;
        end
        else
            color_c = COLOR_EMPTY;
    end
end

// 2 register stages -> same latency as square_object + bitmap of other objects
always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        color_d <= TRANSPARENT;
        RGBout  <= TRANSPARENT;
    end
    else begin
        color_d <= color_c;
        RGBout  <= color_d;
    end
end

assign drawingRequest = (RGBout != TRANSPARENT);

endmodule
